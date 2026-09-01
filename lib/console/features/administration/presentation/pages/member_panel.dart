import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/staff_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../../core/widgets/side_panel.dart';
import '../../../auth/domain/entities/console_user.dart';
import '../controllers/administration_controller.dart';
import 'users_page.dart';

/// Opens one account.
Future<void> showMemberPanel(BuildContext context, {required String memberId}) {
  return showSidePanel<void>(
    context: context,
    builder: (context) => MemberPanel(memberId: memberId),
  );
}

/// One account: its role, what that role grants, and whether it can sign in.
class MemberPanel extends ConsumerWidget {
  const MemberPanel({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directory = ref.watch(staffDirectoryProvider);
    final actingUserId = ref.watch(currentUserProvider)?.id ?? '';

    return directory.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        failure: error is Failure
            ? error
            : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
        onRetry: () => ref.invalidate(staffDirectoryProvider),
      ),
      data: (rows) {
        final member = rows.byId(memberId);
        if (member == null) {
          // Reached when the account is removed while its panel is open.
          // The shared error view already says "not found" in both languages;
          // inventing a second phrasing for it here would be one more string
          // to keep translated for a state nobody should reach.
          return ErrorView(
            failure: const Failure(
              kind: FailureKind.notFound,
              code: 'HTTP_404',
            ),
            onRetry: () => ref.invalidate(staffDirectoryProvider),
          );
        }
        return _Loaded(
          directory: rows,
          member: member,
          actingUserId: actingUserId,
        );
      },
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.directory,
    required this.member,
    required this.actingUserId,
  });

  final StaffDirectoryDto directory;
  final StaffMemberDto member;
  final String actingUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final suspensionRefusal = directory.refusalForSuspension(
      id: member.id,
      actingUserId: actingUserId,
    );

    return SidePanelScaffold(
      title: l10n.memberTitle,
      subtitle: member.name,
      actions: [
        if (member.status == StaffStatus.suspended)
          OutlinedButton(
            onPressed: () => _setStatus(context, ref, StaffStatus.active),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              side: BorderSide(color: context.colors.outline),
              foregroundColor: context.scheme.onSurface,
            ),
            child: Text(l10n.reinstateAccount),
          )
        else
          // Disabled rather than hidden, with the reason on the tooltip and
          // spelled out below: an administrator who cannot see why they may
          // not do something assumes the console is broken.
          Tooltip(
            message: suspensionRefusal == null
                ? ''
                : ConsoleLabels.refusal(l10n, suspensionRefusal),
            child: OutlinedButton(
              onPressed: suspensionRefusal == null
                  ? () => _setStatus(context, ref, StaffStatus.suspended)
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                side: BorderSide(color: context.colors.outline),
                foregroundColor: context.scheme.error,
              ),
              child: Text(l10n.suspendAccount),
            ),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Identity(member: member),
          const SizedBox(height: Spacing.sectionBreak),
          _SectionLabel(l10n.sectionRole),
          const SizedBox(height: Spacing.cardInternal),
          _RoleChooser(
            directory: directory,
            member: member,
            actingUserId: actingUserId,
          ),
          const SizedBox(height: Spacing.sectionBreak),
          _SectionLabel(l10n.sectionCapabilities),
          const SizedBox(height: Spacing.cardInternal),
          _CapabilityList(role: member.role),
          const SizedBox(height: Spacing.cardInternal),
          Text(
            l10n.capabilityDerivedNote,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sectionBreak),
          _SectionLabel(l10n.sectionAccount),
          const SizedBox(height: Spacing.cardInternal),
          _AccountDetails(member: member),
          const SizedBox(height: Spacing.cardInternal),
          Text(
            l10n.suspendKeepsBylinesNote,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    StaffStatus status,
  ) async {
    final l10n = context.l10n;
    await ref
        .read(staffActionsProvider.notifier)
        .setStatus(id: member.id, status: status);
    if (!context.mounted) return;
    showConsoleToast(
      context,
      message: status == StaffStatus.suspended
          ? l10n.accountSuspended(member.name)
          : l10n.accountReinstated(member.name),
      kind: ToastKind.success,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.text.overline.copyWith(
      color: context.scheme.onSurfaceVariant,
    ),
  );
}

class _Identity extends StatelessWidget {
  const _Identity({required this.member});

  final StaffMemberDto member;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.skeleton,
            shape: BoxShape.circle,
          ),
          child: Text(
            member.user.initials,
            style: context.text.label.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: Spacing.listRhythm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.name,
                style: context.text.title.copyWith(
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                member.email,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        StaffStatusChip(status: member.status),
      ],
    );
  }
}

/// One row per role, each with why it cannot be chosen when it cannot.
///
/// A list rather than a dropdown. A dropdown shows one role at a time and hides
/// the refusal until after the choice; the whole point of this screen is that
/// the consequence is visible before the click.
class _RoleChooser extends ConsumerWidget {
  const _RoleChooser({
    required this.directory,
    required this.member,
    required this.actingUserId,
  });

  final StaffDirectoryDto directory;
  final StaffMemberDto member;
  final String actingUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final role in roleOrder)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.chip),
            child: _RoleOption(
              role: role,
              selected: member.role == role,
              refusal: directory.refusalForRoleChange(
                id: member.id,
                role: role,
                actingUserId: actingUserId,
              ),
              onSelect: () async {
                await ref
                    .read(staffActionsProvider.notifier)
                    .setRole(id: member.id, role: role);
                if (!context.mounted) return;
                showConsoleToast(
                  context,
                  message: l10n.roleChanged(
                    member.name,
                    ConsoleLabels.role(l10n, role),
                  ),
                  kind: ToastKind.success,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.refusal,
    required this.onSelect,
  });

  final ConsoleRole role;
  final bool selected;
  final StaffRefusal? refusal;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blocked = refusal != null;

    return Semantics(
      selected: selected,
      button: true,
      enabled: !blocked,
      child: InkWell(
        onTap: blocked || selected ? null : onSelect,
        borderRadius: Radii.cardBorder,
        child: Container(
          padding: const EdgeInsets.all(Spacing.cardInternal),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.accentContainer
                : context.scheme.surface,
            borderRadius: Radii.cardBorder,
            border: Border.all(
              color: selected
                  ? context.colors.accentContainerOutline
                  : context.colors.outline,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected
                    ? context.colors.onAccentContainer
                    : blocked
                    ? context.scheme.onSurfaceVariant
                    : context.scheme.onSurface,
              ),
              const SizedBox(width: Spacing.cardInternal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ConsoleLabels.role(l10n, role),
                      style: context.text.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? context.colors.onAccentContainer
                            : context.scheme.primary,
                      ),
                    ),
                    Text(
                      // How many of the nine capabilities this role carries —
                      // the difference between two roles, said as a number
                      // before the list below says it in full.
                      l10n.itemCount(role.capabilities.length),
                      style: context.text.meta.copyWith(
                        color: selected
                            ? context.colors.onAccentContainer
                            : context.scheme.onSurfaceVariant,
                      ),
                    ),
                    if (blocked) ...[
                      const SizedBox(height: 4),
                      Text(
                        ConsoleLabels.refusal(l10n, refusal!),
                        style: context.text.meta.copyWith(
                          color: context.scheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every capability, ticked or not, for the selected role.
///
/// Shows the *absent* ones too. A list of what a role can do says nothing about
/// what it cannot, and the question an administrator is actually asking —
/// "will moving them to Editor take away the on-air toggle?" — is answered only
/// by the empty rows.
class _CapabilityList extends StatelessWidget {
  const _CapabilityList({required this.role});

  final ConsoleRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final granted = role.capabilities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final capability in Capability.values)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.chip),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  granted.contains(capability)
                      ? Icons.check_circle_rounded
                      : Icons.remove_circle_outline_rounded,
                  size: 16,
                  color: granted.contains(capability)
                      ? context.colors.accent
                      : context.scheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.chip),
                Expanded(
                  child: Text(
                    ConsoleLabels.capability(l10n, capability),
                    style: context.text.meta.copyWith(
                      color: granted.contains(capability)
                          ? context.scheme.onSurface
                          : context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AccountDetails extends StatelessWidget {
  const _AccountDetails({required this.member});

  final StaffMemberDto member;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = context.languageCode;

    return Column(
      children: [
        _Row(
          label: l10n.colLastActive,
          value: member.lastActiveAt == null
              ? l10n.neverSignedIn
              : AppDateFormat.byline(member.lastActiveAt!, code),
        ),
        _Row(
          label: l10n.twoFactorTitle,
          value: member.twoFactorEnrolled ? l10n.healthy : l10n.noSecondFactor,
          warn: !member.twoFactorEnrolled,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.cardInternal),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.body.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: context.text.body.copyWith(
              color: warn ? context.scheme.error : context.scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
