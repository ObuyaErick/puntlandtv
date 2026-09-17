import 'dart:async';

import 'realtime_client.dart';
import 'realtime_event.dart';

/// [RealtimeClient] with no server behind it.
///
/// The counterpart to [FixturePuntlandApi], and the reason the app still runs
/// end to end with `USE_FIXTURES=true` or no `API_BASE_URL` at all. It reports
/// [RealtimeStatus.idle] and emits nothing, which is the honest fixture: a
/// client with no connection is one that never delivers an event, and every
/// screen above here already has to be correct in that case — it is also what
/// a viewer in a tunnel has, and what the fallback poll exists for.
///
/// [emit] makes it scriptable, for tests and for demonstrating a screen's
/// live behaviour without a backend.
class FixtureRealtimeClient implements RealtimeClient {
  FixtureRealtimeClient({
    this.reportedStatus = RealtimeStatus.idle,
    this.isConnectable = false,
  });

  /// The status this client reports. Settable at construction so a golden can
  /// render the console's connected indicator without a socket.
  final RealtimeStatus reportedStatus;

  final _topics = <String, StreamController<RealtimeEvent>>{};
  var _disposed = false;

  /// Topics with a live listener, for tests asserting that a screen subscribed
  /// to what it should have.
  Iterable<String> get subscribedTopics => _topics.keys;

  /// No server, so no fallback poll by default — see
  /// [RealtimeClient.isConnectable]. Settable only so a test can exercise the
  /// poll itself, which otherwise has no way to run without a backend.
  @override
  final bool isConnectable;

  @override
  RealtimeStatus get currentStatus => reportedStatus;

  @override
  Stream<RealtimeStatus> get status =>
      Stream<RealtimeStatus>.value(reportedStatus);

  @override
  Stream<RealtimeEvent> subscribe(String topic) {
    final controller = _topics.putIfAbsent(
      topic,
      StreamController<RealtimeEvent>.broadcast,
    );
    return controller.stream;
  }

  /// Delivers [event] to whoever is listening to its topic. A no-op if nothing
  /// is — which is itself worth asserting on.
  void emit(RealtimeEvent event) {
    if (_disposed) return;
    _topics[event.topic]?.add(event);
  }

  /// Convenience for the common case, so a test reads as the event it means.
  void emitEvent(
    String topic,
    String name, [
    Map<String, dynamic> data = const {},
  ]) {
    emit(
      RealtimeEvent(topic: topic, name: name, data: data, at: DateTime.now()),
    );
  }

  @override
  void close() {}

  @override
  void reopen() {}

  @override
  void dispose() {
    _disposed = true;
    for (final controller in _topics.values) {
      controller.close();
    }
    _topics.clear();
  }
}
