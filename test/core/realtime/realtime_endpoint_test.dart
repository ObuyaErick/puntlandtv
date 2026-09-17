import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/core/realtime/realtime_providers.dart';

/// The socket URL is derived from `API_BASE_URL` rather than configured
/// separately, so this function is the only place the two can disagree — and
/// the failure it prevents is a quiet one: an app that loads fine and never
/// updates.
void main() {
  group('realtimeEndpoint', () {
    test('turns the production base URL into a wss endpoint', () {
      expect(
        realtimeEndpoint('https://puntland-api.tenslet.com/api').toString(),
        'wss://puntland-api.tenslet.com/api/v1/realtime',
      );
    });

    test('keeps a LAN base URL on ws, as `task device` uses it', () {
      expect(
        realtimeEndpoint('http://192.168.1.20:3000/api').toString(),
        'ws://192.168.1.20:3000/api/v1/realtime',
      );
    });

    test('tolerates a trailing slash', () {
      expect(
        realtimeEndpoint('https://api.test/api/').toString(),
        'wss://api.test/api/v1/realtime',
      );
    });

    test('is null when there is no backend, which selects the fixture', () {
      expect(realtimeEndpoint(''), isNull);
      expect(realtimeEndpoint('not a url'), isNull);
    });
  });
}
