/// What a signed-in member of staff is allowed to do.
///
/// Modelled as capabilities rather than role checks scattered through the UI.
/// A screen asks "can this user publish?", never "is this user an editor?" —
/// so adding a role later does not mean auditing every widget.
enum Capability {
  /// Create and edit one's own drafts.
  writeOwnArticles,

  /// Edit anyone's article, and publish.
  publishArticles,

  /// Compose and send push alerts.
  sendPush,

  /// Streams, schedule, radio, on-air toggle.
  manageBroadcast,

  /// Programmes, episodes, media library.
  manageLibrary,

  /// Categories and taxonomy.
  manageTaxonomy,

  /// Staff accounts and roles.
  manageUsers,

  /// Feature flags, minimum build, locales.
  manageConfig,

  /// Read the audit trail.
  viewAuditLog,
}

/// The four staff roles from the console brief.
enum ConsoleRole {
  journalist,
  editor,
  operations,
  admin;

  Set<Capability> get capabilities => switch (this) {
    ConsoleRole.journalist => const {Capability.writeOwnArticles},
    ConsoleRole.editor => const {
      Capability.writeOwnArticles,
      Capability.publishArticles,
      Capability.sendPush,
      Capability.manageLibrary,
      Capability.manageTaxonomy,
    },
    ConsoleRole.operations => const {
      Capability.manageBroadcast,
      Capability.manageLibrary,
    },
    // Admin is deliberately the union of everything rather than a special
    // case in the checks: a capability nobody has assigned is then visibly
    // missing from a role, not silently granted by a bypass.
    ConsoleRole.admin => const {
      Capability.writeOwnArticles,
      Capability.publishArticles,
      Capability.sendPush,
      Capability.manageBroadcast,
      Capability.manageLibrary,
      Capability.manageTaxonomy,
      Capability.manageUsers,
      Capability.manageConfig,
      Capability.viewAuditLog,
    },
  };
}

/// A signed-in member of staff.
class ConsoleUser {
  const ConsoleUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final ConsoleRole role;

  bool can(Capability capability) => role.capabilities.contains(capability);

  /// "A. Yuusuf" → "AY", for the rail avatar.
  String get initials {
    final parts = name.split(RegExp(r'[\s.]+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  bool operator ==(Object other) => other is ConsoleUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Where the sign-in flow currently is.
sealed class AuthState {
  const AuthState();
}

class SignedOut extends AuthState {
  const SignedOut({this.errorCode});

  /// Set after a failed attempt, so the form can say why.
  final String? errorCode;
}

/// Credentials accepted; the second factor is outstanding.
class AwaitingSecondFactor extends AuthState {
  const AwaitingSecondFactor({
    required this.email,
    this.attemptsUsed = 0,
    this.errorCode,
  });

  final String email;

  /// The canvas shows "Isku day 1 / 3" — attempts are visible, and run out.
  final int attemptsUsed;
  final String? errorCode;

  static const maxAttempts = 3;

  int get attemptsRemaining => maxAttempts - attemptsUsed;
  bool get isLockedOut => attemptsRemaining <= 0;
}

class SignedIn extends AuthState {
  const SignedIn(this.user);

  final ConsoleUser user;
}

/// Where a forgotten-password flow has got to.
///
/// Separate from [AuthState] because it is a different question: [AuthState]
/// answers "is this person signed in", and completing a reset does not sign
/// anybody in. It returns them to the form, where the second factor still
/// applies.
sealed class PasswordResetState {
  const PasswordResetState();
}

/// Asking for an address. [errorCode] is set after a failed request.
class ResetIdle extends PasswordResetState {
  const ResetIdle({this.errorCode, this.submitting = false});

  final String? errorCode;
  final bool submitting;
}

/// A code has been asked for.
///
/// Reached whether or not the address belongs to an account — the backend
/// answers the same way for both, and the console must not be the thing that
/// gives away which it was.
class ResetCodeSent extends PasswordResetState {
  const ResetCodeSent({
    required this.email,
    this.devCode,
    this.attemptsUsed = 0,
    this.errorCode,
    this.submitting = false,
  });

  final String email;

  /// Present outside production only, where no gateway is wired up. Shown in
  /// the dialog so the flow is demonstrable; absent in production, where it
  /// would defeat the point of sending a code at all.
  final String? devCode;

  final int attemptsUsed;
  final String? errorCode;
  final bool submitting;

  static const maxAttempts = 5;

  int get attemptsRemaining => maxAttempts - attemptsUsed;

  ResetCodeSent copyWith({
    int? attemptsUsed,
    String? errorCode,
    bool? submitting,
  }) => ResetCodeSent(
    email: email,
    devCode: devCode,
    attemptsUsed: attemptsUsed ?? this.attemptsUsed,
    errorCode: errorCode,
    submitting: submitting ?? this.submitting,
  );
}

/// The password is set. Nothing is signed in — that is the point.
class ResetComplete extends PasswordResetState {
  const ResetComplete(this.email);

  final String email;
}
