import 'dart:async';
import 'dart:math';

import 'realtime_client.dart';
import 'realtime_event.dart';

/// Applies an event to the value on screen.
///
/// Return the new value to apply it inline, or **null** to say "this event
/// cannot be applied from its payload alone" — which triggers a jittered
/// refetch instead. Null is the right answer whenever the change involves
/// anything localised: the payload is one set of bytes fanned out to every
/// viewer, and the slate is not the same sentence in both languages.
typedef ApplyEvent<T> = T? Function(T current, RealtimeEvent event);

/// How long after a `refetch` event a client waits before asking.
///
/// Full jitter over two seconds. The event goes to every viewer of a channel
/// on the same tick, so without this, going off air would turn one broadcast
/// into five thousand simultaneous requests — the API would meet its whole
/// audience at once, which is exactly the load the socket was supposed to
/// remove.
const refetchJitter = Duration(seconds: 2);

/// Fallback poll while the socket is **down**. The pre-realtime cadence.
const disconnectedPollInterval = Duration(seconds: 30);

/// Fallback poll while the socket is **up**.
///
/// Not zero. A socket that is connected can still have missed something — a
/// frame lost in a proxy, an event published while this client was between
/// reconnects — and the cost of being wrong is a viewer watching a slate that
/// should be a programme. Five minutes is a safety net, not a mechanism.
const connectedPollInterval = Duration(minutes: 5);

/// A value that keeps itself current from a realtime topic, with a poll behind
/// it for everything the socket misses.
///
/// This is the whole mechanism of the phase, in one place, because three
/// repositories need exactly it — live, channels and radio — and three copies
/// of "jitter, then refetch, unless you can apply it inline" is three chances
/// to get the jitter wrong in one of them.
///
/// The stream does not end when the connection drops, and does not error when
/// a refetch fails: consumers are players and lists that are still showing
/// something valid. A failed re-check on a bad connection must not tear down a
/// player that is happily playing buffered segments.
Stream<T> watchRealtime<T>({
  required RealtimeClient client,
  required String topic,
  required Future<T> Function() fetch,
  required ApplyEvent<T> apply,
  Duration jitter = refetchJitter,
  Duration whileConnected = connectedPollInterval,
  Duration whileDisconnected = disconnectedPollInterval,
  Random? random,
  void Function(void Function() dispose)? onDispose,
}) {
  final rng = random ?? Random();
  late final StreamController<T> controller;
  late final void Function() release;

  StreamSubscription<RealtimeEvent>? events;
  StreamSubscription<RealtimeStatus>? status;
  Timer? poll;
  Timer? pending;
  T? current;
  var closed = false;
  var inFlight = false;

  Future<void> refresh() async {
    // One at a time. A jittered refetch landing on top of a poll tick would
    // otherwise double the very request this is trying to spread out.
    if (closed || inFlight) return;
    inFlight = true;
    try {
      final value = await fetch();
      if (closed) return;
      current = value;
      controller.add(value);
    } catch (_) {
      // Deliberately swallowed. See the class comment: the consumer is still
      // showing the last good value, and the next tick is the retry.
    } finally {
      inFlight = false;
    }
  }

  void scheduleRefetch() {
    if (closed || pending != null) return;
    pending = Timer(
      Duration(milliseconds: rng.nextInt(jitter.inMilliseconds + 1)),
      () {
        pending = null;
        unawaited(refresh());
      },
    );
  }

  void restartPoll(RealtimeStatus connection) {
    poll?.cancel();
    if (closed) return;
    // Nothing to catch up with: see [RealtimeClient.isConnectable].
    if (!client.isConnectable) return;
    final interval = connection == RealtimeStatus.connected
        ? whileConnected
        : whileDisconnected;
    poll = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  /// Stops everything. Idempotent, because both the provider's disposal and
  /// the stream's own cancellation can reach it.
  release = () {
    closed = true;
    poll?.cancel();
    poll = null;
    pending?.cancel();
    pending = null;
    unawaited(events?.cancel());
    events = null;
    unawaited(status?.cancel());
    status = null;
  };

  // Tied to the *provider's* lifetime, not only to the stream's.
  //
  // Cancelling a stream subscription reaches `onCancel` through a future, and
  // a widget test checks for pending timers the moment the test body returns —
  // so a poll cancelled only on that path is still alive at the check, and
  // every test that mounts a screen using this fails with "a Timer is still
  // pending". `ref.onDispose` runs synchronously when the provider goes, which
  // is the same reason the timers this replaced were registered there.
  onDispose?.call(() => release());

  controller = StreamController<T>(
    onListen: () {
      unawaited(refresh());

      events = client.subscribe(topic).listen((event) {
        final value = current;
        if (value == null) return scheduleRefetch();

        final applied = apply(value, event);
        if (applied == null) return scheduleRefetch();

        current = applied;
        if (!controller.isClosed) controller.add(applied);
      });

      var previous = client.currentStatus;
      restartPoll(previous);

      status = client.status.listen((next) {
        // Reconnected: whatever happened while this client was away was
        // published to a socket that was not there to receive it, so the only
        // honest thing to do is ask. Jittered, because every device that lost
        // the same cell reconnects at the same moment.
        if (next == RealtimeStatus.connected &&
            previous != RealtimeStatus.connected) {
          scheduleRefetch();
        }
        // The fallback cadence depends on whether the socket is carrying
        // events, so it is re-chosen whenever that changes.
        if ((next == RealtimeStatus.connected) !=
            (previous == RealtimeStatus.connected)) {
          restartPoll(next);
        }
        previous = next;
      });
    },
    // Cancelling the event subscription is what drops the topic's refcount to
    // zero and sends the `unsubscribe` — see [RealtimeClient.subscribe].
    onCancel: () => release(),
  );

  return controller.stream;
}
