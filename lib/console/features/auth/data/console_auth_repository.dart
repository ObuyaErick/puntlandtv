import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failure.dart';
import '../../../core/admin_api/console_credentials.dart';
import '../../../core/admin_api/dto/session_dto.dart';
import '../../../core/admin_api/puntland_admin_api.dart';
import '../domain/entities/console_user.dart';
import '../domain/repositories/auth_repository.dart';

/// [AuthRepository] over [PuntlandAdminApi].
///
/// One implementation for both backends. The transport lives in the API layer,
/// where the fixture/HTTP swap already happens, so this class has no branch on
/// which one it got — it does the two things that are genuinely its own:
///
/// **It turns refusals into states.** The API throws a [Failure] carrying the
/// backend's code; the screens switch on [AuthState]. Counting the attempt that
/// a wrong code just burned belongs here rather than in the client, because
/// "how many tries are left" is a property of the flow the console is running,
/// not of any one request.
///
/// **It decides what is remembered.** See [_persist] for why that is a
/// per-platform answer rather than one line.
class ConsoleAuthRepository implements AuthRepository {
  ConsoleAuthRepository(this._api, this._credentials, this._prefs) {
    // The client renews a lapsed access token on its own, mid-request. The
    // backend revokes the refresh token it was given when it does, so what is
    // in storage is spent from that moment — this is how the replacement gets
    // there instead.
    _credentials.onChanged = _persist;
  }

  final PuntlandAdminApi _api;
  final ConsoleCredentials _credentials;
  final SharedPreferences _prefs;

  static const _refreshTokenKey = 'console.session.refresh';

  @override
  Future<AuthState> signIn({
    required String email,
    required String password,
  }) async {
    // Answered without a request: the form can see an empty password, and the
    // backend would only be able to tell the operator the same thing less
    // precisely — it refuses a blank password as `INVALID_CREDENTIALS`, which
    // reads as "wrong password" rather than "you did not type one".
    if (password.trim().isEmpty) {
      return const SignedOut(errorCode: 'PASSWORD_REQUIRED');
    }

    try {
      final challenge = await _api.signIn(email: email, password: password);
      return AwaitingSecondFactor(email: challenge.email);
    } on Failure catch (failure) {
      return SignedOut(errorCode: failure.code);
    }
  }

  @override
  Future<AuthState> verifySecondFactor({
    required String email,
    required String code,
    required int attemptsUsed,
  }) async {
    try {
      final session = await _api.verifySecondFactor(email: email, code: code);
      _hold(session);
      return SignedIn(session.user);
    } on Failure catch (failure) {
      if (failure.code != 'INVALID_CODE') {
        // `LOCKED_OUT` and anything else end the attempt. The backend counts
        // attempts on the challenge too, so a client that lost count cannot
        // buy itself extra tries.
        return SignedOut(errorCode: failure.code);
      }

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
  }

  @override
  Future<void> signOut() async {
    final presented = _storedRefreshToken;
    try {
      await _api.signOut(refreshToken: presented);
    } finally {
      // Local state is cleared whatever the backend said. An operator who
      // pressed sign-out and is still looking at the console is the worse
      // failure of the two.
      _credentials.clear();
      await _prefs.remove(_refreshTokenKey);
    }
  }

  @override
  Future<ConsoleUser?> restoreSession() async {
    final stored = _storedRefreshToken;

    // Nothing to present and no cookie that could speak for us: this is a first
    // launch, not a session to recover, and asking the backend would only
    // produce a 401 to throw away.
    if (stored == null && !kIsWeb) return null;

    final session = await _api.restoreSession(refreshToken: stored);
    if (session == null) {
      await _prefs.remove(_refreshTokenKey);
      return null;
    }
    _hold(session);
    return session.user;
  }

  /// Takes the credentials a session came with.
  ///
  /// Done here rather than left to the client so that both implementations
  /// behave the same: the fixture has no tokens worth sending and no reason to
  /// know [ConsoleCredentials] exists, but the console still has to remember a
  /// session across a reload when it is running on fixtures.
  void _hold(ConsoleSessionDto session) => _credentials.hold(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
  );

  String? get _storedRefreshToken => _prefs.getString(_refreshTokenKey);

  /// Writes the refresh token where the next launch can find it — except on the
  /// web, where it deliberately writes nothing.
  ///
  /// The browser build already has the credential, as an httpOnly cookie the
  /// backend set and no script can read. Copying it into `localStorage` would
  /// take a token that is out of reach of any script on the page and put it
  /// within reach of every script on the page, to solve a problem the cookie
  /// has already solved.
  void _persist() {
    if (kIsWeb) return;

    final token = _credentials.refreshToken;
    if (token == null) {
      _prefs.remove(_refreshTokenKey);
      return;
    }
    _prefs.setString(_refreshTokenKey, token);
  }
}
