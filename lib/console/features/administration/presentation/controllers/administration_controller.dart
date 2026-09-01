import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/admin_api/dto/console_config_dto.dart';
import '../../../../core/admin_api/dto/staff_dto.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../auth/domain/entities/console_user.dart';

part 'administration_controller.g.dart';

@riverpod
Future<StaffDirectoryDto> staffDirectory(Ref ref) =>
    ref.watch(adminApiProvider).fetchStaffDirectory();

/// Writes against staff accounts.
@Riverpod(keepAlive: true)
class StaffActions extends _$StaffActions {
  @override
  void build() {}

  Future<void> setRole({required String id, required ConsoleRole role}) async {
    await ref.read(adminApiProvider).setStaffRole(id: id, role: role);
    ref.invalidate(staffDirectoryProvider);
  }

  Future<void> setStatus({
    required String id,
    required StaffStatus status,
  }) async {
    await ref.read(adminApiProvider).setStaffStatus(id: id, status: status);
    ref.invalidate(staffDirectoryProvider);
  }
}

@riverpod
Future<ConsoleConfigDto> storedConfig(Ref ref) =>
    ref.watch(adminApiProvider).fetchConsoleConfig();

/// The config as it stands in the form, which is not what is stored.
///
/// App configuration is edited as a whole and saved once, unlike the article
/// list where every action is its own write. Two of these fields can take the
/// product down for every reader, so a switch that applies the instant it is
/// flipped is the wrong shape: there has to be a moment where the form is
/// wrong, the screen says why, and nothing has happened yet.
///
/// Null until the stored config has loaded — the draft is a copy of something,
/// and inventing a default would let the form save a floor nobody chose.
@riverpod
class ConfigDraft extends _$ConfigDraft {
  @override
  ConsoleConfigDto? build() {
    // Seeds from the stored value and re-seeds if it is refetched, but is not
    // otherwise derived from it: once someone starts typing, the draft is the
    // thing they are editing.
    final stored = ref.watch(storedConfigProvider).value;
    return stored;
  }

  void setMinimumBuild(int build) =>
      _update((c) => c.copyWith(minimumSupportedBuild: build));

  void setLocaleEnabled(String code, bool enabled) =>
      _update((c) => c.withLocaleEnabled(code, enabled));

  void setFlag(String key, bool enabled) =>
      _update((c) => c.withFlag(key, enabled));

  void setDataSaverDefault(bool value) =>
      _update((c) => c.copyWith(dataSaverDefault: value));

  void _update(ConsoleConfigDto Function(ConsoleConfigDto) change) {
    final current = state;
    if (current != null) state = change(current);
  }

  /// Throws the draft away and goes back to what is stored.
  void discard() => state = ref.read(storedConfigProvider).value;
}

/// Whether the form differs from what is stored.
///
/// Compared field by field rather than by identity: the draft is a new object
/// after every keystroke, so an identity check would report unsaved changes
/// forever once anyone touched the form and then undid it.
@riverpod
bool configIsDirty(Ref ref) {
  final stored = ref.watch(storedConfigProvider).value;
  final draft = ref.watch(configDraftProvider);
  if (stored == null || draft == null) return false;

  if (stored.minimumSupportedBuild != draft.minimumSupportedBuild) return true;
  if (stored.dataSaverDefault != draft.dataSaverDefault) return true;

  for (final locale in stored.locales) {
    if (draft.locale(locale.code)?.enabled != locale.enabled) return true;
  }
  for (final flag in stored.flags) {
    final theirs = draft.flags.where((f) => f.key == flag.key).firstOrNull;
    if (theirs?.enabled != flag.enabled) return true;
  }
  return false;
}

@Riverpod(keepAlive: true)
class ConfigActions extends _$ConfigActions {
  @override
  void build() {}

  Future<void> save() async {
    final draft = ref.read(configDraftProvider);
    if (draft == null) return;
    await ref.read(adminApiProvider).saveConsoleConfig(draft);
    ref.invalidate(storedConfigProvider);
  }
}
