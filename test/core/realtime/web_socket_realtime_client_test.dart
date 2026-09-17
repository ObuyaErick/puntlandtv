import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/core/realtime/realtime_event.dart';
import 'package:puntland/core/realtime/web_socket_realtime_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A socket the test drives by hand: frames in via [deliver], frames out
/// recorded in [sent], and the handshake resolved or refused on demand.
///
/// Hand-rolled rather than mocked, in the house style — and small, because the
/// only parts of `WebSocketChannel` this client uses are `stream`, `sink` and
/// `ready`.
class FakeChannel implements WebSocketChannel {
  FakeChannel({this.failHandshake = false});

  final bool failHandshake;
  final _incoming = StreamController<dynamic>();
  final _sink = _FakeSink();

  bool get isClosed => _sink.closed;
  List<Map<String, dynamic>> get sent => _sink.frames;

  /// Frames of one `type`, in order.
  List<Map<String, dynamic>> sentOfType(String type) =>
      sent.where((frame) => frame['type'] == type).toList();

  /// Pushes a server frame at the client.
  void deliver(Map<String, dynamic> frame) => _incoming.add(jsonEncode(frame));

  /// Pushes whatever arrived — a proxy's error page, a truncated frame.
  void deliverRaw(Object payload) => _incoming.add(payload);

  /// The connection dropping under the client — a dead cell, a proxy timeout.
  void drop() => _incoming.close();

  @override
  Future<void> get ready => failHandshake
      ? Future<void>.error(WebSocketChannelException('refused'))
      : Future<void>.value();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  /// `WebSocketChannel` extends `StreamChannelMixin`, whose members this
  /// client never touches and whose type is not re-exported by the package.
  /// Forwarding to `noSuchMethod` keeps the fake to the three members that
  /// matter, and turns any future use of the rest into a loud failure rather
  /// than a silent stub.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSink implements WebSocketSink {
  final frames = <Map<String, dynamic>>[];
  var closed = false;

  @override
  void add(dynamic data) =>
      frames.add(jsonDecode(data as String) as Map<String, dynamic>);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> get done => Future<void>.value();
}

void main() {
  /// Builds a client over a queue of channels, one per connection attempt.
  /// The intervals are shrunk through the constructor rather than faked —
  /// there is no `fake_async` in this repo, and the established pattern is to
  /// inject durations.
  ({
    WebSocketRealtimeClient client,
    List<FakeChannel> opened,
    List<Uri> targets,
  })
  build({List<FakeChannel Function()> channels = const []}) {
    final opened = <FakeChannel>[];
    final targets = <Uri>[];
    var attempt = 0;

    final client = WebSocketRealtimeClient(
      endpoint: Uri.parse('wss://api.test/api/v1/realtime'),
      baseDelay: const Duration(milliseconds: 1),
      maxDelay: const Duration(milliseconds: 2),
      connect: (uri) {
        targets.add(uri);
        final channel = attempt < channels.length
            ? channels[attempt]()
            : FakeChannel();
        attempt++;
        opened.add(channel);
        return channel;
      },
    );
    addTearDown(client.dispose);
    return (client: client, opened: opened, targets: targets);
  }

  /// Lets the client's queued microtasks and short timers run.
  Future<void> settle([int millis = 20]) =>
      Future<void>.delayed(Duration(milliseconds: millis));

  group('WebSocketRealtimeClient · subscribing', () {
    test('opens no connection until something actually listens', () async {
      final harness = build();

      final stream = harness.client.subscribe(RealtimeTopic.news);
      await settle();
      expect(harness.opened, isEmpty);

      final subscription = stream.listen((_) {});
      await settle();
      expect(harness.opened, hasLength(1));

      await subscription.cancel();
    });

    test('subscribes the topic once connected', () async {
      final harness = build();
      final subscription = harness.client
          .subscribe(RealtimeTopic.channel('main'))
          .listen((_) {});
      await settle();

      expect(harness.opened.single.sentOfType('subscribe').last['topics'], [
        'channel:main',
      ]);
      await subscription.cancel();
    });

    test('delivers an event only to its own topic', () async {
      final harness = build();
      final live = <RealtimeEvent>[];
      final news = <RealtimeEvent>[];
      final a = harness.client
          .subscribe(RealtimeTopic.channel('main'))
          .listen(live.add);
      final b = harness.client.subscribe(RealtimeTopic.news).listen(news.add);
      await settle();

      harness.opened.single.deliver({
        'type': 'event',
        'topic': 'channel:main',
        'event': RealtimeEventName.liveChanged,
        'data': {'channel_key': 'main', 'is_live': true},
        'at': '2026-09-16T19:40:14.126Z',
      });
      await settle();

      expect(live, hasLength(1));
      expect(live.single.name, RealtimeEventName.liveChanged);
      expect(live.single.boolean('is_live'), isTrue);
      expect(news, isEmpty);

      await a.cancel();
      await b.cancel();
    });

    test('shares one socket across every topic', () async {
      final harness = build();
      final a = harness.client.subscribe(RealtimeTopic.news).listen((_) {});
      await settle();
      final b = harness.client.subscribe(RealtimeTopic.channels).listen((_) {});
      await settle();

      // A phone on the live page, the channel list and the feed holds one
      // connection, not three.
      expect(harness.opened, hasLength(1));
      expect(harness.opened.single.sentOfType('subscribe'), hasLength(2));

      await a.cancel();
      await b.cancel();
    });

    test('refcounts: the second listener does not resubscribe', () async {
      final harness = build();
      final a = harness.client.subscribe(RealtimeTopic.news).listen((_) {});
      await settle();
      final b = harness.client.subscribe(RealtimeTopic.news).listen((_) {});
      await settle();

      expect(harness.opened.single.sentOfType('subscribe'), hasLength(1));
      expect(harness.opened.single.sentOfType('unsubscribe'), isEmpty);

      // Only the *last* listener going away unsubscribes.
      await a.cancel();
      await settle();
      expect(harness.opened.single.sentOfType('unsubscribe'), isEmpty);

      await b.cancel();
      await settle();
      expect(harness.opened.single.sentOfType('unsubscribe').single['topics'], [
        'news',
      ]);
    });

    test('drops the socket when the last topic goes away', () async {
      final harness = build();
      final subscription = harness.client
          .subscribe(RealtimeTopic.news)
          .listen((_) {});
      await settle();

      await subscription.cancel();
      await settle();

      expect(harness.opened.single.isClosed, isTrue);
      expect(harness.client.currentStatus, RealtimeStatus.idle);
    });
  });

  group('WebSocketRealtimeClient · reconnecting', () {
    test('resubscribes every held topic after a drop', () async {
      final harness = build();
      final events = <RealtimeEvent>[];
      final a = harness.client
          .subscribe(RealtimeTopic.channel('main'))
          .listen(events.add);
      final b = harness.client.subscribe(RealtimeTopic.news).listen((_) {});
      await settle();
      expect(harness.opened, hasLength(1));

      harness.opened.first.drop();
      await settle(60);

      // The server knows nothing about what this client was listening to, so
      // the whole held set goes again on the new connection.
      expect(harness.opened, hasLength(2));
      final resubscribed = harness.opened.last
          .sentOfType('subscribe')
          .expand((frame) => frame['topics'] as List<dynamic>)
          .toSet();
      expect(resubscribed, {'channel:main', 'news'});

      // And the consumer's subscription survived the gap.
      harness.opened.last.deliver({
        'type': 'event',
        'topic': 'channel:main',
        'event': RealtimeEventName.liveChanged,
        'data': <String, dynamic>{},
        'at': '2026-09-16T19:40:14.126Z',
      });
      await settle();
      expect(events, hasLength(1));

      await a.cancel();
      await b.cancel();
    });

    test('retries after a refused handshake', () async {
      final harness = build(channels: [() => FakeChannel(failHandshake: true)]);
      final subscription = harness.client
          .subscribe(RealtimeTopic.news)
          .listen((_) {});
      await settle(80);

      expect(harness.opened.length, greaterThan(1));
      expect(harness.client.currentStatus, RealtimeStatus.connected);

      await subscription.cancel();
    });

    test('does not reconnect once nothing is subscribed', () async {
      final harness = build();
      final subscription = harness.client
          .subscribe(RealtimeTopic.news)
          .listen((_) {});
      await settle();

      await subscription.cancel();
      harness.opened.first.drop();
      await settle(60);

      expect(harness.opened, hasLength(1));
    });

    test('close stops reconnecting; reopen resumes', () async {
      final harness = build();
      final subscription = harness.client
          .subscribe(RealtimeTopic.news)
          .listen((_) {});
      await settle();

      // Backgrounded: no socket, no heartbeat, no retries.
      harness.client.close();
      await settle(60);
      expect(harness.opened, hasLength(1));
      expect(harness.client.currentStatus, RealtimeStatus.idle);

      harness.client.reopen();
      await settle();
      expect(harness.opened, hasLength(2));
      expect(harness.opened.last.sentOfType('subscribe').single['topics'], [
        'news',
      ]);

      await subscription.cancel();
    });

    test('refuses to attempt anything while the device is offline', () async {
      var offline = true;
      final opened = <FakeChannel>[];
      final client = WebSocketRealtimeClient(
        endpoint: Uri.parse('wss://api.test/api/v1/realtime'),
        baseDelay: const Duration(milliseconds: 1),
        canConnect: () => !offline,
        connect: (_) {
          final channel = FakeChannel();
          opened.add(channel);
          return channel;
        },
      );
      addTearDown(client.dispose);

      final subscription = client.subscribe(RealtimeTopic.news).listen((_) {});
      await settle(40);
      expect(opened, isEmpty, reason: 'retrying into a dead network');

      // Connectivity returns, and the provider nudges the client.
      offline = false;
      client.reopen();
      await settle();
      expect(opened, hasLength(1));

      await subscription.cancel();
    });
  });

  group('WebSocketRealtimeClient · the wire', () {
    test('attaches an access token to the handshake URL', () async {
      final targets = <Uri>[];
      final client = WebSocketRealtimeClient(
        endpoint: Uri.parse('wss://api.test/api/v1/realtime'),
        accessToken: () => 'staff-token',
        connect: (uri) {
          targets.add(uri);
          return FakeChannel();
        },
      );
      addTearDown(client.dispose);

      final subscription = client
          .subscribe(RealtimeTopic.adminMedia)
          .listen((_) {});
      await settle();

      // A browser's `WebSocket` cannot set a header, and the console is a
      // browser client.
      expect(targets.single.queryParameters['access_token'], 'staff-token');

      await subscription.cancel();
    });

    test('sends no token when there is none', () async {
      final harness = build();
      final subscription = harness.client
          .subscribe(RealtimeTopic.news)
          .listen((_) {});
      await settle();

      expect(harness.targets.single.queryParameters, isEmpty);

      await subscription.cancel();
    });

    test('ignores frames it has no use for', () async {
      final harness = build();
      final events = <RealtimeEvent>[];
      final subscription = harness.client
          .subscribe(RealtimeTopic.news)
          .listen(events.add);
      await settle();

      final channel = harness.opened.single
        ..deliver({'type': 'welcome', 'heartbeat_ms': 25000})
        ..deliver({
          'type': 'subscribed',
          'topics': <String>['news'],
        })
        ..deliver({'type': 'error', 'code': 'TOPIC_FORBIDDEN'})
        // An event name from a newer API than this build knows.
        ..deliver({
          'type': 'event',
          'topic': 'news',
          'event': 'article.summarised',
          'data': <String, dynamic>{},
          'at': '2026-09-16T19:40:14.126Z',
        });
      await settle();

      // The unknown event still arrives — the consumer decides, not the
      // transport. Everything else is transport chatter.
      expect(events.map((event) => event.name), ['article.summarised']);
      expect(channel.isClosed, isFalse);

      await subscription.cancel();
    });

    test('survives a frame that is not JSON at all', () async {
      final harness = build();
      final events = <RealtimeEvent>[];
      final subscription = harness.client
          .subscribe(RealtimeTopic.news)
          .listen(events.add);
      await settle();

      harness.opened.single.deliverRaw('<html>502 Bad Gateway</html>');
      await settle();

      expect(events, isEmpty);
      expect(harness.client.currentStatus, RealtimeStatus.connected);

      await subscription.cancel();
    });
  });
}
