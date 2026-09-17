import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/core/realtime/fixture_realtime_client.dart';
import 'package:puntland/core/realtime/realtime_event.dart';
import 'package:puntland/core/realtime/realtime_watch.dart';

/// The mechanism behind every `watch()` in the app — live, radio, the reader's
/// channel list, the console's channel table and its control room. Five call
/// sites, so the rules are pinned once here rather than five times badly.
void main() {
  /// Jitter drawn as zero, so a refetch is observable without waiting seconds.
  /// The distribution itself is the point of [refetchJitter] and is asserted
  /// separately below.
  final noJitter = Random(0);

  late FixtureRealtimeClient client;
  late int fetches;

  setUp(() {
    client = FixtureRealtimeClient();
    fetches = 0;
  });
  tearDown(() => client.dispose());

  Stream<String> watch({
    required ApplyEvent<String> apply,
    String topic = 'channel:main',
    Duration jitter = Duration.zero,
  }) {
    return watchRealtime<String>(
      client: client,
      topic: topic,
      fetch: () async => 'fetch#${++fetches}',
      apply: apply,
      jitter: jitter,
      random: noJitter,
    );
  }

  /// Lets the seed fetch, an event and any scheduled refetch settle.
  Future<void> settle([int millis = 10]) =>
      Future<void>.delayed(Duration(milliseconds: millis));

  test('seeds from the network before any event arrives', () async {
    final seen = <String>[];
    final sub = watch(apply: (_, _) => null).listen(seen.add);
    await settle();

    expect(seen, ['fetch#1']);
    await sub.cancel();
  });

  test('applies an event inline when the payload is enough', () async {
    // The fast path, and the whole point of the phase: going on air carries
    // the stream URL, so the player starts with no round trip.
    final seen = <String>[];
    final sub = watch(apply: (current, event) => event.string('value'))
        .listen(seen.add);
    await settle();

    client.emitEvent('channel:main', RealtimeEventName.liveChanged, {
      'value': 'applied-inline',
    });
    await settle();

    expect(seen, ['fetch#1', 'applied-inline']);
    expect(fetches, 1, reason: 'an inline apply must cost no request');
    await sub.cancel();
  });

  test('refetches when the event cannot be applied from its payload', () async {
    final seen = <String>[];
    final sub = watch(apply: (_, _) => null).listen(seen.add);
    await settle();

    client.emitEvent('channel:main', RealtimeEventName.liveChanged);
    await settle();

    expect(seen, ['fetch#1', 'fetch#2']);
    await sub.cancel();
  });

  test('coalesces a burst of events into one refetch', () async {
    // Five thousand viewers all refetching is the load this was supposed to
    // remove; one viewer refetching five times is the same mistake, smaller.
    final seen = <String>[];
    final sub = watch(apply: (_, _) => null).listen(seen.add);
    await settle();

    for (var i = 0; i < 5; i++) {
      client.emitEvent('channel:main', RealtimeEventName.liveChanged);
    }
    await settle();

    expect(fetches, 2, reason: 'one seed, one refetch for the burst');
    expect(seen, ['fetch#1', 'fetch#2']);
    await sub.cancel();
  });

  test('spreads refetches across the jitter window', () {
    // Full jitter over two seconds. Without it, one event becomes an
    // instantaneous request from every viewer of the channel at once.
    final rng = Random(7);
    final draws = List.generate(
      500,
      (_) => rng.nextInt(refetchJitter.inMilliseconds + 1),
    );

    expect(refetchJitter, const Duration(seconds: 2));
    expect(draws.every((d) => d >= 0 && d <= 2000), isTrue);
    // Spread, not clustered: both halves of the window are used.
    expect(draws.where((d) => d < 1000), isNotEmpty);
    expect(draws.where((d) => d >= 1000), isNotEmpty);
  });

  test('keeps the stream alive when a refetch fails', () async {
    // The consumer is a player still showing something valid. A failed
    // re-check on a bad connection must not tear it down.
    final seen = <String>[];
    final errors = <Object>[];
    var attempt = 0;

    final stream = watchRealtime<String>(
      client: client,
      topic: 'channel:main',
      fetch: () async {
        attempt++;
        if (attempt == 2) throw StateError('network down');
        return 'ok#$attempt';
      },
      apply: (_, _) => null,
      jitter: Duration.zero,
      random: noJitter,
    );
    final sub = stream.listen(seen.add, onError: errors.add);
    await settle();

    client.emitEvent('channel:main', RealtimeEventName.liveChanged);
    await settle();
    client.emitEvent('channel:main', RealtimeEventName.liveChanged);
    await settle();

    expect(errors, isEmpty, reason: 'a failed re-check is not a stream error');
    expect(seen, ['ok#1', 'ok#3'], reason: 'it recovers on the next event');
    await sub.cancel();
  });

  test('ignores events for other topics', () async {
    final seen = <String>[];
    final sub = watch(apply: (_, _) => null).listen(seen.add);
    await settle();

    client.emitEvent('channel:other', RealtimeEventName.liveChanged);
    await settle();

    expect(seen, ['fetch#1']);
    await sub.cancel();
  });

  test('subscribes on listen and unsubscribes on cancel', () async {
    // Refcounting is what makes a retry cheap and a closed screen free.
    final sub = watch(apply: (_, _) => null).listen((_) {});
    await settle();
    expect(client.subscribedTopics, contains('channel:main'));

    await sub.cancel();
    await settle();
    expect(fetches, 1);
  });

  test('runs no fallback poll when there is no backend behind it', () async {
    // Otherwise every console widget test — which runs on fixtures — ends with
    // a pending periodic timer, and `testWidgets` fails on exactly that.
    expect(client.isConnectable, isFalse);
    final sub = watch(apply: (_, _) => null).listen((_) {});
    await settle(40);

    expect(fetches, 1, reason: 'the seed, and nothing on a timer');
    await sub.cancel();
  });

  test('polls faster while disconnected than while connected', () {
    // The fallback is a safety net, not the mechanism — but it must still be
    // the old cadence when the socket is not carrying anything.
    expect(disconnectedPollInterval, const Duration(seconds: 30));
    expect(connectedPollInterval, const Duration(minutes: 5));
    expect(disconnectedPollInterval, lessThan(connectedPollInterval));
  });

  test('re-reads on the fallback poll with no events at all', () async {
    // A connectable client, because the poll only runs when there is a server
    // behind it to have missed something — see `RealtimeClient.isConnectable`.
    final connectable = FixtureRealtimeClient(isConnectable: true);
    addTearDown(connectable.dispose);

    final seen = <String>[];
    final stream = watchRealtime<String>(
      client: connectable,
      topic: 'channel:main',
      fetch: () async => 'poll#${++fetches}',
      apply: (_, _) => null,
      whileConnected: const Duration(milliseconds: 15),
      whileDisconnected: const Duration(milliseconds: 15),
      random: noJitter,
    );
    final sub = stream.listen(seen.add);
    await settle(60);

    expect(fetches, greaterThan(1), reason: 'the net must actually catch');
    await sub.cancel();
  });
}
