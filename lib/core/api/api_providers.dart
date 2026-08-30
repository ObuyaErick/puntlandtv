import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/interceptors/locale_interceptor.dart';
import '../network/interceptors/logging_interceptor.dart';
import '../network/interceptors/retry_interceptor.dart';
import '../providers/preferences_providers.dart';
import 'fixture_puntland_api.dart';
import 'http_puntland_api.dart';
import 'puntland_api.dart';

/// Base URL of the Puntland TV API, injected at build time:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://api.puntlandtv.nt
/// ```
///
/// Empty means "no backend configured", which is the current state of the
/// project — see [puntlandApiProvider].
const kApiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Forces fixtures even when a base URL is set. Useful for demos and for
/// working on the UI without a backend running.
const kUseFixtures = bool.fromEnvironment('USE_FIXTURES');

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      // Generous by desktop standards, deliberately: a 3G handshake in a
      // congested cell regularly takes longer than the usual 5s default, and
      // failing early just produces an error screen the user has to dismiss
      // before the request would have succeeded anyway.
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(LocaleInterceptor(() => ref.read(localeTagProvider)));
  dio.interceptors.add(RetryInterceptor(dio: dio));
  if (kDebugMode) dio.interceptors.add(LoggingInterceptor());

  ref.onDispose(dio.close);
  return dio;
});

/// **The swap point.**
///
/// Everything above this line — repositories, controllers, every screen — is
/// written against [PuntlandApi] and cannot tell which implementation it got.
/// Pointing the app at the real backend is this provider plus a
/// `--dart-define`, with no other change anywhere in the tree.
final puntlandApiProvider = Provider<PuntlandApi>((ref) {
  if (kUseFixtures || kApiBaseUrl.isEmpty) {
    return FixturePuntlandApi(
      languageCode: () => ref.read(localeProvider).languageCode,
    );
  }
  return HttpPuntlandApi(ref.watch(dioProvider));
});
