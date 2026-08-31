import '../entities/console_user.dart';

/// Authentication for staff.
///
/// Two steps by design: the console can publish to every phone in the region
/// and take the channel off air, so a password alone is not the bar.
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

  /// The session restored from storage at startup, if any.
  Future<ConsoleUser?> restoreSession();
}
