import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently has a network route.
///
/// This says nothing about whether the *API* is reachable — a captive portal
/// reports connected. It is used only to choose which message to show, never
/// to decide whether to attempt a request.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});

/// Convenience: `false` until the first event arrives, so the offline banner
/// never flashes on a cold start.
final isOfflineProvider = Provider<bool>((ref) {
  return ref
      .watch(connectivityProvider)
      .maybeWhen(data: (online) => !online, orElse: () => false);
});
