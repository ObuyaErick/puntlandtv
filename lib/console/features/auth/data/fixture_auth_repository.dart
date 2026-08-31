import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/console_user.dart';
import '../domain/repositories/auth_repository.dart';

/// [AuthRepository] against a fixed staff list.
///
/// Stands in until the real identity provider exists. It models the parts that
/// shape the UI — a mandatory second factor, a finite number of attempts, a
/// restored session — so that swapping in the real one is a change to this
/// file rather than to the screens.
class FixtureAuthRepository implements AuthRepository {
  FixtureAuthRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _sessionKey = 'console.session.userId';

  /// Any password is accepted; the code is not. That keeps the demo usable
  /// while still exercising the failure path that matters.
  static const validCode = '418';

  static const _staff = <ConsoleUser>[
    ConsoleUser(
      id: 'u-editor',
      name: 'A. Yuusuf',
      email: 'a.yuusuf@pltv.so',
      role: ConsoleRole.editor,
    ),
    ConsoleUser(
      id: 'u-journalist',
      name: 'F. Xasan',
      email: 'f.xasan@pltv.so',
      role: ConsoleRole.journalist,
    ),
    ConsoleUser(
      id: 'u-ops',
      name: 'M. Cali',
      email: 'm.cali@pltv.so',
      role: ConsoleRole.operations,
    ),
    ConsoleUser(
      id: 'u-admin',
      name: 'S. Warsame',
      email: 's.warsame@pltv.so',
      role: ConsoleRole.admin,
    ),
  ];

  static ConsoleUser? _lookup(String email) {
    for (final user in _staff) {
      if (user.email.toLowerCase() == email.trim().toLowerCase()) return user;
    }
    return null;
  }

  @override
  Future<AuthState> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (password.trim().isEmpty) {
      return const SignedOut(errorCode: 'PASSWORD_REQUIRED');
    }
    if (_lookup(email) == null) {
      // Deliberately the same message as a wrong password would give: telling
      // an attacker which half was wrong is free reconnaissance.
      return const SignedOut(errorCode: 'INVALID_CREDENTIALS');
    }

    return AwaitingSecondFactor(email: email);
  }

  @override
  Future<AuthState> verifySecondFactor({
    required String email,
    required String code,
    required int attemptsUsed,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final user = _lookup(email);
    if (user == null) return const SignedOut(errorCode: 'INVALID_CREDENTIALS');

    if (code.trim() != validCode) {
      final used = attemptsUsed + 1;
      if (used >= AwaitingSecondFactor.maxAttempts) {
        return const SignedOut(errorCode: 'LOCKED_OUT');
      }
      return AwaitingSecondFactor(
        email: email,
        attemptsUsed: used,
        errorCode: 'INVALID_CODE',
      );
    }

    await _prefs.setString(_sessionKey, user.id);
    return SignedIn(user);
  }

  @override
  Future<void> signOut() async => _prefs.remove(_sessionKey);

  @override
  Future<ConsoleUser?> restoreSession() async {
    final id = _prefs.getString(_sessionKey);
    if (id == null) return null;
    for (final user in _staff) {
      if (user.id == id) return user;
    }
    return null;
  }
}
