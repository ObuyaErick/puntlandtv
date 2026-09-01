import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/network/interceptors/locale_interceptor.dart';
import '../../../core/network/interceptors/logging_interceptor.dart';
import '../../../core/network/interceptors/retry_interceptor.dart';
import '../../../core/providers/preferences_providers.dart';
import '../../features/auth/data/console_auth_repository.dart';
import '../../features/auth/domain/entities/console_user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../admin_api/console_credentials.dart';
import '../admin_api/fixture_admin_api.dart';
import '../admin_api/http_admin_api.dart';
import '../admin_api/puntland_admin_api.dart';

/// Whether the navigation rail is collapsed to icons.
///
/// The canvas shows both states: expanded on the overview, collapsed on the
/// article list where the table wants the width. It is the operator's choice
/// rather than a per-screen rule, so it persists.
class RailCollapsed extends Notifier<bool> {
  static const _key = 'console.rail.collapsed';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> toggle() async {
    state = !state;
    await ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

final railCollapsedProvider = NotifierProvider<RailCollapsed, bool>(
  RailCollapsed.new,
);

/// Wall-clock time, as a provider.
///
/// The push composer's lock-screen preview renders the current time, which is
/// correct in the app and a time bomb in a golden — the frame would differ
/// every minute. Overriding this in tests pins it.
final consoleClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The live token pair, shared by the client that sends it and the repository
/// that persists it. See [ConsoleCredentials].
final consoleCredentialsProvider = Provider<ConsoleCredentials>(
  (ref) => ConsoleCredentials(),
);

/// The console's HTTP client.
///
/// Deliberately not the app's [dioProvider]. That one is built for a reader on
/// a congested cell — long timeouts, retries — and it must not grow an
/// interceptor that attaches a staff credential: the reader app links the
/// reader client, and a token on those requests would be a token in a build
/// shipped to every phone in the region.
///
/// The retry interceptor is shared and safe to share: it retries `GET` only, so
/// a dropped packet cannot publish an article twice.
final consoleDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
      // Sends `pltv_access` on the browser build, where the console runs from
      // its own origin and the cookie is httpOnly — the point of which is that
      // no script here, ours included, can read it.
      extra: {'withCredentials': true},
    ),
  );

  // No credential interceptor here on purpose: `HttpAdminApi` attaches the
  // token itself, because the place that sends it is also the place that has to
  // renew it when the backend says it has lapsed.

  // The backend localises chrome it returns — category names, cadence and genre
  // labels — from this header, so the console's own language choice reaches it.
  dio.interceptors.add(LocaleInterceptor(() => ref.read(localeTagProvider)));
  dio.interceptors.add(RetryInterceptor(dio: dio));
  if (kDebugMode) dio.interceptors.add(LoggingInterceptor());

  ref.onDispose(dio.close);
  return dio;
});

/// **The console's swap point**, mirroring `puntlandApiProvider` in the app.
///
/// Everything above this line — controllers, every screen — is written against
/// [PuntlandAdminApi] and cannot tell which implementation it got. Pointing the
/// console at the real backend is this provider plus a `--dart-define`, and the
/// same two flags decide it as decide the reader's: an empty `API_BASE_URL` or
/// `USE_FIXTURES=true` keeps the fixtures, so a demo of the console and a demo
/// of the app cannot end up disagreeing about whether there is a backend.
final adminApiProvider = Provider<PuntlandAdminApi>((ref) {
  if (kUseFixtures || kApiBaseUrl.isEmpty) return FixtureAdminApi();
  return HttpAdminApi(
    ref.watch(consoleDioProvider),
    ref.watch(consoleCredentialsProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ConsoleAuthRepository(
    ref.watch(adminApiProvider),
    ref.watch(consoleCredentialsProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

/// Drives the whole sign-in flow, and is what the router guards on.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const SignedOut();

  /// Restores a stored session before the first frame, so a reload does not
  /// bounce a signed-in editor back to the login form.
  Future<void> restore() async {
    final user = await ref.read(authRepositoryProvider).restoreSession();
    if (user != null) state = SignedIn(user);
  }

  Future<void> signIn({required String email, required String password}) async {
    state = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
  }

  Future<void> verify(String code) async {
    final current = state;
    if (current is! AwaitingSecondFactor) return;

    state = await ref
        .read(authRepositoryProvider)
        .verifySecondFactor(
          email: current.email,
          code: code,
          attemptsUsed: current.attemptsUsed,
        );
  }

  /// Abandons the second-factor step and returns to the form.
  void cancel() => state = const SignedOut();

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const SignedOut();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// The signed-in user, or null. Screens read this rather than unpacking
/// [AuthState] themselves.
final currentUserProvider = Provider<ConsoleUser?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is SignedIn ? state.user : null;
});

/// Capability check for guards and for hiding controls a role cannot use.
///
/// Hiding is not security — the admin API enforces the same rules — but a
/// Journalist should not see a Publish button they cannot press.
final canProvider = Provider.family<bool, Capability>((ref, capability) {
  return ref.watch(currentUserProvider)?.can(capability) ?? false;
});
