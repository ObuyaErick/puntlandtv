import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../features/auth/domain/entities/console_user.dart';
import 'admin_api/dto/admin_program_dto.dart';
import 'admin_api/dto/staff_dto.dart';

/// Names of the languages the product supports, in the *active* UI language.
///
/// Distinct from the language picker, which deliberately uses endonyms so a
/// reader can find their own language without being able to read the rest of
/// the UI. Everywhere else — "No English translation", "Somali is behind" —
/// the language name is ordinary prose and follows the active locale like any
/// other word.
String languageName(AppL10n l10n, String code) => switch (code) {
  'so' => l10n.languageNameSomali,
  'en' => l10n.languageNameEnglish,
  _ => code.toUpperCase(),
};

extension LocalisedContext on BuildContext {
  /// The name of [code] in the active UI language.
  String languageNameOf(String code) => languageName(l10n, code);
}

/// Names of the console's enum values, in the active UI language.
///
/// These live together rather than beside each screen because several of them
/// appear in more than one place — a role in the users table and in the rail's
/// user chip, a genre in the programme table and in its editor — and two
/// switches over the same enum drift apart the moment somebody adds a value.
abstract final class ConsoleLabels {
  static String cadence(AppL10n l10n, ProgramCadence value) => switch (value) {
    ProgramCadence.daily => l10n.cadenceDaily,
    ProgramCadence.weekly => l10n.cadenceWeekly,
    ProgramCadence.monthly => l10n.cadenceMonthly,
    ProgramCadence.occasional => l10n.cadenceOccasional,
  };

  static String genre(AppL10n l10n, ProgramGenre value) => switch (value) {
    ProgramGenre.news => l10n.genreNews,
    ProgramGenre.debate => l10n.genreDebate,
    ProgramGenre.culture => l10n.genreCulture,
    ProgramGenre.kids => l10n.genreKids,
    ProgramGenre.sport => l10n.genreSport,
    ProgramGenre.religion => l10n.genreReligion,
  };

  static String role(AppL10n l10n, ConsoleRole value) => switch (value) {
    ConsoleRole.journalist => l10n.roleJournalist,
    ConsoleRole.editor => l10n.roleEditor,
    ConsoleRole.operations => l10n.roleOperations,
    ConsoleRole.admin => l10n.roleAdmin,
  };

  static String staffStatus(AppL10n l10n, StaffStatus value) => switch (value) {
    StaffStatus.active => l10n.statusActive,
    StaffStatus.invited => l10n.statusInvited,
    StaffStatus.suspended => l10n.statusSuspended,
  };

  /// What a capability lets someone do, in prose.
  ///
  /// Spelled out rather than shown as the enum name: the users screen exists so
  /// an administrator can see what a role grants before assigning it, and
  /// `manageBroadcast` tells them nothing they did not already assume.
  static String capability(AppL10n l10n, Capability value) => switch (value) {
    Capability.writeOwnArticles => l10n.capWriteOwnArticles,
    Capability.publishArticles => l10n.capPublishArticles,
    Capability.sendPush => l10n.capSendPush,
    Capability.manageBroadcast => l10n.capManageBroadcast,
    Capability.manageLibrary => l10n.capManageLibrary,
    Capability.manageTaxonomy => l10n.capManageTaxonomy,
    Capability.manageUsers => l10n.capManageUsers,
    Capability.manageConfig => l10n.capManageConfig,
    Capability.viewAuditLog => l10n.capViewAuditLog,
  };

  /// Why a staff change was refused.
  static String refusal(AppL10n l10n, StaffRefusal value) => switch (value) {
    StaffRefusal.self => l10n.refusalSelf,
    StaffRefusal.lastAdmin => l10n.refusalLastAdmin,
  };
}
