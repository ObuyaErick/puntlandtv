import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/preferences_providers.dart';
import '../../features/auth/data/fixture_auth_repository.dart';
import '../../features/auth/domain/entities/console_user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../admin_api/fixture_admin_api.dart';
import '../admin_api/puntland_admin_api.dart';

/// The console's swap point, mirroring `puntlandApiProvider` in the app.
/// Pointing at a real backend is a change here and nowhere else.
final adminApiProvider = Provider<PuntlandAdminApi>((ref) => FixtureAdminApi());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FixtureAuthRepository(ref.watch(sharedPreferencesProvider)),
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
