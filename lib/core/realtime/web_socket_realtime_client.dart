import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'realtime_client.dart';
import 'realtime_event.dart';

/// Opens a channel to the gateway. Injected so tests can drive a socket
/// without one, the way `RetryInterceptor` takes its `Dio`.
typedef ChannelFactory = WebSocketChannel Function(Uri endpoint);

/// [RealtimeClient] over one multiplexed websocket.
///
/// **One socket for the whole app.** Not one per screen: a phone holding the
/// live page, the channel list and the feed would otherwise hold three, each
/// with its own handshake, its own TLS session and its own 25s heartbeat, on
/// the kind of connection this app is built for. Topics are multiplexed over
/// the single connection and refcounted, so a screen opening and closing costs
/// one small frame rather than a reconnect.
///
/// **A drop is a gap, not an ending.** Consumers keep their subscriptions
/// across a reconnect; this class reopens underneath them and resubscribes
/// every held topic. Nothing above here has to know a connection exists, which
/// is the point — `LiveRepository.watch` is a `Stream<LiveChannel>` whether
/// the events come from a socket or from a poll.
class WebSocketRealtimeClient implements RealtimeClient {
  WebSocketRealtimeClient({
    required this.endpoint,
    ChannelFactory? connect,
    this.accessToken,
    this.canConnect,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
  }) : _connect = connect ?? WebSocketChannel.connect;

  /// The gateway, already carrying `/v1/realtime`.
  final Uri endpoint;

  final ChannelFactory _connect;

  /// Read at each connect rather than held, so a renewed token is used by the
  /// next attempt without anyone having to rebuild this client.
  final String? Function()? accessToken;

  /// Whether an attempt is worth making at all — wired to `isOfflineProvider`.
  /// Retrying into a network the device knows is dead only burns battery.
  final bool Function()? canConnect;

  /// First backoff step. Doubles per attempt, capped at [maxDelay].
  final Duration baseDelay;
  final Duration maxDelay;

  final _random = Random();

  /// Live topics, by name. A topic is present exactly while something is
  /// listening to it — see [subscribe].
  final _topics = <String, StreamController<RealtimeEvent>>{};

  final _statusController = StreamController<RealtimeStatus>.broadcast();
  RealtimeStatus _status = RealtimeStatus.idle;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _frames;
  Timer? _retry;
  int _attempt = 0;

  /// Set by [close] and cleared by [reopen] — the app was backgrounded, or
  /// went offline. Distinct from [_disposed], which is final.
  bool _stopped = false;
  bool _disposed = false;

  @override
  bool get isConnectable => true;

  @override
  RealtimeStatus get currentStatus => _status;

  @override
  Stream<RealtimeStatus> get status async* {
    // The current value first: a widget that subscribes after the connection
    // settled would otherwise show "connecting" until something changed.
    yield _status;
    yield* _statusController.stream;
  }

  @override
  Stream<RealtimeEvent> subscribe(String topic) {
    final existing = _topics[topic];
    if (existing != null) return existing.stream;

    // A broadcast controller's `onListen`/`onCancel` fire on the 0→1 and 1→0
    // edges and nowhere else, which is the refcount — no counter to keep
    // correct across an exception.
    late final StreamController<RealtimeEvent> controller;
    controller = StreamController<RealtimeEvent>.broadcast(
      onListen: () {
        _send({
          'type': 'subscribe',
          'topics': [topic],
        });
        _ensureConnected();
      },
      onCancel: () {
        _topics.remove(topic);
        _send({
          'type': 'unsubscribe',
          'topics': [topic],
        });
        controller.close();
        // Nothing left to listen for: drop the socket rather than hold a
        // connection and a heartbeat open for a backgrounded app.
        if (_topics.isEmpty) _teardown(RealtimeStatus.idle);
      },
    );

    _topics[topic] = controller;
    return controller.stream;
  }

  @override
  void close() {
    _stopped = true;
    _teardown(RealtimeStatus.idle);
  }

  @override
  void reopen() {
    if (_disposed) return;
    _stopped = false;
    // A reconnect after a resume should not wait out a backoff earned by
    // whatever failed before the app was backgrounded.
    _attempt = 0;
    _retry?.cancel();
    _retry = null;
    _ensureConnected();
  }

  @override
  void dispose() {
    _disposed = true;
    _teardown(RealtimeStatus.idle);
    for (final controller in _topics.values) {
      controller.close();
    }
    _topics.clear();
    _statusController.close();
  }

  // ---------------------------------------------------------------- connection

  void _ensureConnected() {
    if (_disposed || _stopped || _topics.isEmpty) return;
    if (_channel != null || _retry != null) return;
    if (canConnect?.call() == false) {
      _setStatus(RealtimeStatus.idle);
      return;
    }
    unawaited(_open());
  }

  Future<void> _open() async {
    if (_channel != null) return;
    _setStatus(RealtimeStatus.connecting);

    final WebSocketChannel channel;
    try {
      channel = _connect(_target());
    } catch (error) {
      // A malformed URL, or no network stack at all. Same handling as a
      // refused connection — there is nothing else to do about either.
      _log('connect failed: $error');
      _onDropped();
      return;
    }

    _channel = channel;
    _frames = channel.stream.listen(
      _onFrame,
      onError: (Object error) {
        _log('socket error: $error');
        _onDropped();
      },
      onDone: _onDropped,
      cancelOnError: false,
    );

    try {
      await channel.ready;
    } catch (error) {
      _log('handshake failed: $error');
      // `onDone` may or may not also fire depending on the platform, and
      // [_onDropped] is written to be safe either way.
      _onDropped();
      return;
    }
    if (_channel != channel) return; // superseded while awaiting

    _attempt = 0;
    _setStatus(RealtimeStatus.connected);
    // Every held topic, not only new ones: after a reconnect the server knows
    // nothing about what this client was listening to.
    if (_topics.isNotEmpty) {
      _send({'type': 'subscribe', 'topics': _topics.keys.toList()});
    }
  }

  /// The connection was lost, refused, or never established.
  void _onDropped() {
    if (_channel == null && _frames == null) return; // already handled
    _closeChannel();

    if (_disposed || _stopped || _topics.isEmpty) {
      _setStatus(RealtimeStatus.idle);
      return;
    }
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_retry != null) return;
    if (canConnect?.call() == false) {
      // Offline. `reopen()` is what brings it back — see the connectivity
      // listener in `realtime_providers.dart`.
      _setStatus(RealtimeStatus.idle);
      return;
    }

    // Exponential backoff with full jitter, the same shape as
    // `RetryInterceptor`: without the jitter, every device in a cell that lost
    // coverage reconnects in lockstep the moment it returns, and the API meets
    // the whole audience in one tick.
    final backoff = baseDelay * pow(2, _attempt).toDouble();
    final capped = backoff > maxDelay ? maxDelay : backoff;
    final delay = Duration(
      milliseconds: _random.nextInt(capped.inMilliseconds + 1),
    );
    _attempt++;

    _setStatus(RealtimeStatus.connecting);
    _retry = Timer(delay, () {
      _retry = null;
      _ensureConnected();
    });
  }

  void _onFrame(dynamic raw) {
    final Map<String, dynamic> frame;
    try {
      final decoded = jsonDecode(
        raw is String ? raw : utf8.decode(raw as List<int>),
      );
      if (decoded is! Map<String, dynamic>) return;
      frame = decoded;
    } catch (error) {
      _log('undecodable frame: $error');
      return;
    }

    final event = RealtimeEvent.tryParse(frame);
    if (event == null) {
      // `welcome`, `subscribed`, `error` — and anything a later API adds.
      if (frame['type'] == 'error') {
        _log('refused: ${frame['code']} ${frame['topic']}');
      }
      return;
    }

    // A topic nobody is listening to any more: the unsubscribe and the event
    // crossed on the wire, which is normal and not worth reporting.
    _topics[event.topic]?.add(event);
  }

  /// Sends a frame if there is a connection. Dropping it otherwise is correct
  /// rather than lossy: [_open] resubscribes the whole held set on connect, so
  /// a subscribe sent while disconnected would only be sent twice.
  void _send(Map<String, dynamic> frame) {
    final channel = _channel;
    if (channel == null || _status != RealtimeStatus.connected) return;
    try {
      channel.sink.add(jsonEncode(frame));
    } catch (error) {
      _log('send failed: $error');
    }
  }

  void _teardown(RealtimeStatus next) {
    _retry?.cancel();
    _retry = null;
    _closeChannel();
    _setStatus(next);
  }

  void _closeChannel() {
    final channel = _channel;
    _channel = null;
    unawaited(_frames?.cancel());
    _frames = null;
    unawaited(channel?.sink.close());
  }

  void _setStatus(RealtimeStatus next) {
    if (_status == next) return;
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  /// The endpoint with the access token attached, if there is one.
  ///
  /// A query parameter rather than a header because a browser's `WebSocket`
  /// cannot set one — and the console runs in a browser. The API accepts it
  /// here for the same reason the queue board does, and redacts it from its
  /// logs.
  Uri _target() {
    final token = accessToken?.call();
    if (token == null || token.isEmpty) return endpoint;
    return endpoint.replace(
      queryParameters: {...endpoint.queryParameters, 'access_token': token},
    );
  }

  void _log(String message) {
    assert(() {
      developer.log(message, name: 'realtime');
      return true;
    }());
  }
}
