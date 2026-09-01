import '../../../features/auth/domain/entities/console_user.dart';

/// What a password alone buys: a challenge, never a session.
///
/// The console can publish to every phone in the region and take the channel
/// off air, so the first step deliberately answers with this rather than with a
/// signed-in user. [devCode] is how the flow stays demonstrable before an SMS
/// gateway exists — the backend omits it in production, where a code in the
/// response body would defeat the second factor entirely.
class SecondFactorChallengeDto {
  const SecondFactorChallengeDto({
    required this.email,
    this.attemptsUsed = 0,
    this.maxAttempts = 3,
    this.expiresIn = const Duration(minutes: 5),
    this.devCode,
  });

  factory SecondFactorChallengeDto.fromJson(Map<String, dynamic> json) =>
      SecondFactorChallengeDto(
        email: json['email'] as String,
        attemptsUsed: json['attempts_used'] as int? ?? 0,
        maxAttempts: json['max_attempts'] as int? ?? 3,
        expiresIn: Duration(seconds: json['expires_in_seconds'] as int? ?? 300),
        devCode: json['dev_code'] as String?,
      );

  final String email;
  final int attemptsUsed;
  final int maxAttempts;
  final Duration expiresIn;
  final String? devCode;
}

/// A minted session: who, and the credentials that prove it.
///
/// Both tokens are nullable because the fixture implementation has no
/// cryptography behind it, and because the browser build never sees the real
/// ones — the backend sets them as httpOnly cookies, which is the point: no
/// script on the page, ours included, can read them.
class ConsoleSessionDto {
  const ConsoleSessionDto({
    required this.user,
    this.accessToken,
    this.refreshToken,
  });

  factory ConsoleSessionDto.fromJson(Map<String, dynamic> json) =>
      ConsoleSessionDto(
        user: consoleUserFromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['access_token'] as String?,
        refreshToken: json['refresh_token'] as String?,
      );

  final ConsoleUser user;

  /// Sent as `Authorization: Bearer` on every subsequent request. Short-lived.
  final String? accessToken;

  /// Exchanged for a new pair when the access token lapses.
  ///
  /// **Single-use**: the backend revokes the presented token whether or not the
  /// new pair is issued, so a captured one is worth one refresh. Whoever
  /// refreshes therefore has to persist what came back, or the next cold start
  /// arrives holding a token that has already been spent.
  final String? refreshToken;
}

/// A staff account as an auth payload carries it.
///
/// The response also lists the account's capabilities. They are not read:
/// [ConsoleRole] derives the same set on this side, and parsing the server's
/// copy would create two answers to what a role may do that could disagree.
/// The server enforces its own — hiding a control the role cannot use is a
/// courtesy, not the boundary.
ConsoleUser consoleUserFromJson(Map<String, dynamic> json) => ConsoleUser(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  role: ConsoleRole.values.firstWhere(
    (role) => role.name == json['role'],
    orElse: () => ConsoleRole.journalist,
  ),
);

/// What asking for a password reset returns.
///
/// Carries no account facts, deliberately: not a name, not whether the address
/// is one the backend knows. A reset form is the cheapest way to find out who
/// has an account somewhere, and "a code is on its way" costs nothing to say
/// when there is nobody to send it to. The console shows the same confirmation
/// either way.
///
/// [devCode] is present outside production only, for the same reason the second
/// factor's is: the flow has to be usable before an email or SMS gateway
/// exists. It is also the one field that *would* distinguish the two responses,
/// which is why the backend gates it on the environment rather than on a flag.
class PasswordResetChallengeDto {
  const PasswordResetChallengeDto({
    required this.email,
    this.maxAttempts = 5,
    this.expiresIn = const Duration(minutes: 15),
    this.devCode,
  });

  factory PasswordResetChallengeDto.fromJson(Map<String, dynamic> json) =>
      PasswordResetChallengeDto(
        email: json['email'] as String,
        maxAttempts: json['max_attempts'] as int? ?? 5,
        expiresIn: Duration(seconds: json['expires_in_seconds'] as int? ?? 900),
        devCode: json['dev_code'] as String?,
      );

  final String email;
  final int maxAttempts;
  final Duration expiresIn;
  final String? devCode;
}
