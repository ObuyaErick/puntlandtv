import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../providers/connectivity_provider.dart';
import 'fixture_realtime_client.dart';
import 'realtime_client.dart';
import 'realtime_event.dart';
import 'web_socket_realtime_client.dart';

/// The gateway's URL, derived from the one base URL the app is already given.
///
/// Derived rather than a second `--dart-define`: two URLs that must agree is
/// two URLs that will eventually disagree, and the failure — a working app
/// whose live pages never update — is a quiet one.
///
/// `API_BASE_URL` is `https://host/api`, so the socket is
/// `wss://host/api/v1/realtime`, matching `REALTIME_PATH` on the server.
Uri? realtimeEndpoint(String baseUrl) {
  if (baseUrl.isEmpty) return null;
  final base = Uri.tryParse(baseUrl);
  if (base == null || !base.hasScheme) return null;

  final scheme = switch (base.scheme) {
    'https' => 'wss',
    'http' => 'ws',
    final other => other,
  };
  final path = '${base.path}/v1/realtime'.replaceAll('//', '/');
  return base.replace(scheme: scheme, path: path);
}

/// **The swap point**, mirroring [puntlandApiProvider] exactly.
///
/// The same two flags decide it as decide the API's, so a demo cannot end up
/// with fixture data and a live socket — which would look like a backend that
/// contradicts itself.
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final endpoint = realtimeEndpoint(kApiBaseUrl);
  if (kUseFixtures || endpoint == null) {
    final client = FixtureRealtimeClient();
    ref.onDispose(client.dispose);
    return client;
  }

  final client = WebSocketRealtimeClient(
    endpoint: endpoint,
    // Read live rather than watched: rebuilding this provider on every
    // connectivity change would drop the socket the change is about.
    canConnect: () => !ref.read(isOfflineProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});

/// Where the reader's connection stands.
final realtimeStatusProvider = StreamProvider<RealtimeStatus>((ref) {
  return ref.watch(realtimeClientProvider).status;
});

/// Closes the socket while the app is backgrounded, and reopens on resume.
///
/// There was no `AppLifecycleListener` anywhere in `lib/` before this, because
/// nothing held an open connection. A socket changes that in both directions:
/// a backgrounded app holding one keeps a 25s heartbeat running on the
/// device's radio for no benefit, and — worse — an app resumed after an hour
/// has a socket the OS quietly severed, which looks exactly like a connected
/// one until the first event fails to arrive.
///
/// Reconnecting on resume is also what makes the reconcile correct: whatever
/// changed while the app was away is picked up by the repositories' refetch,
/// not inferred from events nobody was listening for.
///
/// Watched by the app shell, so it lives as long as the app does.
final realtimeLifecycleProvider = Provider<void>((ref) {
  final client = ref.watch(realtimeClientProvider);

  final listener = AppLifecycleListener(
    onStateChange: (state) {
      switch (state) {
        case AppLifecycleState.resumed:
          client.reopen();
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          client.close();
        case AppLifecycleState.inactive:
          // A transient overlay — the app switcher, a permission sheet, a
          // call banner. Dropping the socket for one would reconnect on every
          // notification the user swipes away.
          break;
      }
    },
  );
  ref.onDispose(listener.dispose);

  // Coming back onto a network is the other resume: the client refuses to
  // attempt a connection while `isOfflineProvider` is true, so something has
  // to tell it the situation changed.
  ref.listen<bool>(isOfflineProvider, (wasOffline, isOffline) {
    if (wasOffline == true && !isOffline) client.reopen();
  });
});
