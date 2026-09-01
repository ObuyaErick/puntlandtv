import '../../../features/auth/domain/entities/console_user.dart';

/// Whether an account can be used.
enum StaffStatus {
  active,

  /// Invited but has not signed in yet. Holds a role, occupies a seat, and
  /// counts for nothing — which matters for the last-admin rule below.
  invited,

  /// Kept, but cannot sign in. Deliberately not deletion: an article's author
  /// attribution outlives the person's employment, and deleting the account
  /// would either orphan the byline or silently rewrite it.
  suspended;

  static StaffStatus fromJson(String value) => StaffStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => StaffStatus.active,
  );

  String toJson() => name;
}

/// A staff account as the administration screen sees it.
class StaffMemberDto {
  const StaffMemberDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    this.lastActiveAt,
    this.twoFactorEnrolled = false,
  });

  factory StaffMemberDto.fromJson(Map<String, dynamic> json) => StaffMemberDto(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: ConsoleRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => ConsoleRole.journalist,
    ),
    status: StaffStatus.fromJson(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    lastActiveAt: json['last_active_at'] == null
        ? null
        : DateTime.parse(json['last_active_at'] as String),
    twoFactorEnrolled: json['two_factor_enrolled'] as bool? ?? false,
  );

  final String id;
  final String name;
  final String email;
  final ConsoleRole role;
  final StaffStatus status;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  /// Sign-in requires a second factor, so an account without one is an account
  /// that cannot actually be used — worth showing rather than discovering at
  /// 23:00 when the duty editor tries to publish.
  final bool twoFactorEnrolled;

  /// The capabilities this account actually has.
  ///
  /// Derived from the role every time rather than stored per user. Storing
  /// them would allow a per-user grant that no role explains, and the existing
  /// note on [ConsoleRole] is the reason not to: a capability nobody has
  /// assigned should be visibly missing from a role, not silently granted by a
  /// bypass.
  Set<Capability> get capabilities => role.capabilities;

  bool get canSignIn => status == StaffStatus.active;

  /// The account exists and holds admin, but cannot sign in to use it.
  bool get isEffectiveAdmin =>
      role == ConsoleRole.admin && status == StaffStatus.active;

  /// The projection the rest of the console consumes for attribution.
  ConsoleUser get user =>
      ConsoleUser(id: id, name: name, email: email, role: role);

  StaffMemberDto copyWith({ConsoleRole? role, StaffStatus? status}) =>
      StaffMemberDto(
        id: id,
        name: name,
        email: email,
        role: role ?? this.role,
        status: status ?? this.status,
        createdAt: createdAt,
        lastActiveAt: lastActiveAt,
        twoFactorEnrolled: twoFactorEnrolled,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'status': status.toJson(),
    'created_at': createdAt.toIso8601String(),
    'last_active_at': lastActiveAt?.toIso8601String(),
    'two_factor_enrolled': twoFactorEnrolled,
  };
}

/// Why a role or status change is refused.
enum StaffRefusal {
  /// You are editing your own account in a way that would revoke your own
  /// access. The console would drop you at the next request and you would need
  /// another admin to let you back in.
  self,

  /// This is the only admin who can actually sign in. Demoting or suspending
  /// them leaves nobody able to manage users, config, or the audit trail —
  /// a state no one inside the product can undo.
  lastAdmin,
}

/// The staff list, plus the two rules that protect it from itself.
///
/// The rules live on the collection rather than on [StaffMemberDto] because
/// neither is a property of one account: "the last admin" is a fact about the
/// whole directory, and "yourself" is a fact about the session. A per-row
/// `canDemote` getter cannot express either, which is how a console ends up
/// locking its own operators out.
class StaffDirectoryDto {
  const StaffDirectoryDto({required this.members});

  factory StaffDirectoryDto.fromJson(Map<String, dynamic> json) =>
      StaffDirectoryDto(
        members: [
          for (final member in json['members'] as List<dynamic>)
            StaffMemberDto.fromJson(member as Map<String, dynamic>),
        ],
      );

  final List<StaffMemberDto> members;

  /// Admins who can actually sign in. An invited or suspended admin is not one
  /// of them, which is the whole point of counting this rather than counting
  /// the role.
  int get effectiveAdminCount =>
      members.where((m) => m.isEffectiveAdmin).length;

  StaffMemberDto? byId(String id) =>
      members.where((m) => m.id == id).firstOrNull;

  /// True when [id] is the only admin left who can sign in.
  bool isLastAdmin(String id) {
    final member = byId(id);
    if (member == null || !member.isEffectiveAdmin) return false;
    return effectiveAdminCount <= 1;
  }

  /// Why changing [id]'s role to [role] is refused, or null when it is allowed.
  ///
  /// [actingUserId] is the signed-in operator. A real backend takes it from the
  /// session rather than the request — a client that can name the actor can
  /// name someone else — but the UI needs the same answer before the click, so
  /// the rule is expressed here too.
  StaffRefusal? refusalForRoleChange({
    required String id,
    required ConsoleRole role,
    required String actingUserId,
  }) {
    final member = byId(id);
    if (member == null || member.role == role) return null;

    // Losing admin is the only direction that can lock anyone out. Being
    // *promoted* to admin is always safe, including promoting yourself if you
    // somehow could.
    final losesAdmin =
        member.role == ConsoleRole.admin && role != ConsoleRole.admin;
    if (!losesAdmin) return null;

    if (id == actingUserId) return StaffRefusal.self;
    if (isLastAdmin(id)) return StaffRefusal.lastAdmin;
    return null;
  }

  /// Why suspending [id] is refused, or null when it is allowed.
  StaffRefusal? refusalForSuspension({
    required String id,
    required String actingUserId,
  }) {
    final member = byId(id);
    if (member == null || member.status == StaffStatus.suspended) return null;

    if (id == actingUserId) return StaffRefusal.self;
    if (isLastAdmin(id)) return StaffRefusal.lastAdmin;
    return null;
  }

  /// Reinstating is never refused: it only ever adds access back.
  bool canReinstate(String id) => byId(id)?.status == StaffStatus.suspended;

  /// How many accounts hold each role, for the summary strip.
  Map<ConsoleRole, int> get countsByRole => {
    for (final role in ConsoleRole.values)
      role: members.where((m) => m.role == role).length,
  };

  int get accountsWithoutTwoFactor =>
      members.where((m) => !m.twoFactorEnrolled).length;

  StaffDirectoryDto withMember(StaffMemberDto updated) => StaffDirectoryDto(
    members: [
      for (final member in members)
        if (member.id == updated.id) updated else member,
    ],
  );

  Map<String, dynamic> toJson() => {
    'members': [for (final member in members) member.toJson()],
  };
}

/// Refusal codes the admin API raises for staff changes.
abstract final class StaffFailureCode {
  /// The change would leave nobody able to administer the console.
  static const lastAdmin = 'STAFF_LAST_ADMIN';
}
