import '../entities/console_user.dart';

/// Authentication for staff.
///
/// Two steps by design: the console can publish to every phone in the region
/// and take the channel off air, so a password alone is not the bar.
///
/// The requests themselves belong to `PuntlandAdminApi`, alongside every other
/// call to the same backend. What is left here is what the flow needs and a
/// request does not: the [AuthState] machine the router guards on, the count of
/// attempts a wrong code has burned, and the decision about what survives a
/// relaunch.
abstract interface class AuthRepository {
  /// Returns the user only when no second factor is required, which in
  /// practice is never — the flow always continues to [verifySecondFactor].
  Future<AuthState> signIn({required String email, required String password});

  Future<AuthState> verifySecondFactor({
    required String email,
    required String code,
    required int attemptsUsed,
  });

  Future<void> signOut();

  /// Asks for a reset code. Returns the state the flow moves to, which is
  /// [ResetCodeSent] even for an address with no account behind it.
  Future<PasswordResetState> requestPasswordReset({required String email});

  /// Sets the new password, or reports why it could not.
  Future<PasswordResetState> resetPassword({
    required ResetCodeSent pending,
    required String code,
    required String password,
  });

  /// The session restored from storage at startup, if any.
  Future<ConsoleUser?> restoreSession();
}
