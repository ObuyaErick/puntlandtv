import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/staff_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_table.dart';
import '../../../auth/domain/entities/console_user.dart';
import '../controllers/administration_controller.dart';
import 'member_panel.dart';

/// Staff accounts and what each role can do.
///
/// The screen's job is not to list people — it is to make a role's *contents*
/// visible before somebody assigns it. Roles are capability sets in code, so an
/// administrator picking "Operations" from a dropdown is choosing nine yes/no
/// answers they cannot see. The panel shows them.
///
/// Two rules protect the console from being administered into a corner:
///
/// 1. **You cannot revoke your own access.** Demoting or suspending yourself
///    works exactly once and then needs somebody else to undo it.
/// 2. **The last admin who can sign in cannot be demoted or suspended.**
///    Invited and suspended admins do not count — an account that cannot
///    complete a sign-in is not a way back in. This is the state nobody inside
///    the product can recover from, so it is refused at the API too.
class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final directory = ref.watch(staffDirectoryProvider);

    return ConsolePage(
      title: l10n.usersTitle,
      subtitle: directory.value == null
          ? null
          : l10n.itemCount(directory.value!.members.length),
      actions: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.person_add_alt_rounded, size: 18),
          label: Text(l10n.inviteUser),
        ),
      ],
      notice: ConsoleNotice(message: l10n.usersNotice),
      child: directory.when(
        loading: () => const _StaffSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(staffDirectoryProvider),
        ),
        data: (rows) => _StaffBody(directory: rows),
      ),
    );
  }
}

class _StaffBody extends ConsumerWidget {
  const _StaffBody({required this.directory});

  final StaffDirectoryDto directory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final columns = <ConsoleColumn>[
      ConsoleColumn(label: l10n.colPerson, flex: 4),
      ConsoleColumn(label: l10n.colRole, width: 130),
      ConsoleColumn(label: l10n.colLastActive, width: 132),
      ConsoleColumn(label: l10n.colStatus, width: 116),
    ];

    return WindowSizeScope(
      builder: (context, size) {
        final asTable = size.isAtLeastExpanded;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AdminHealthStrip(directory: directory),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.sectionBreak,
                  Spacing.cardInternal,
                  Spacing.sectionBreak,
                  Spacing.sectionBreak,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.scheme.surface,
                    borderRadius: Radii.cardBorder,
                    border: Border.all(color: context.colors.outline),
                  ),
                  child: ClipRRect(
                    borderRadius: Radii.cardBorder,
                    child: Column(
                      children: [
                        if (asTable) ConsoleTableHeader(columns: columns),
                        Expanded(
                          child: ListView.builder(
                            itemCount: directory.members.length,
                            itemBuilder: (context, index) {
                              final member = directory.members[index];
                              void open() =>
                                  showMemberPanel(context, memberId: member.id);

                              if (!asTable) {
                                return _MemberCard(member: member, onTap: open);
                              }

                              return ConsoleTableRow(
                                columns: columns,
                                onTap: open,
                                cells: [
                                  _PersonCell(member: member),
                                  Text(
                                    ConsoleLabels.role(l10n, member.role),
                                    style: context.text.meta.copyWith(
                                      color: context.scheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    _lastActive(context, member),
                                    style: context.text.meta.copyWith(
                                      color: context.scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: StaffStatusChip(
                                      status: member.status,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _lastActive(BuildContext context, StaffMemberDto member) {
  final when = member.lastActiveAt;
  return when == null
      ? context.l10n.neverSignedIn
      : AppDateFormat.byline(when, context.languageCode);
}

/// How many people can actually administer this console, and how many accounts
/// cannot complete a sign-in.
///
/// Above the table rather than inside it because neither number is a property
/// of a row. "One admin left" is the fact that makes the next demotion
/// irreversible, and it should be visible before somebody opens a panel.
class _AdminHealthStrip extends StatelessWidget {
  const _AdminHealthStrip({required this.directory});

  final StaffDirectoryDto directory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final admins = directory.effectiveAdminCount;
    final gaps = directory.accountsWithoutTwoFactor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.sectionBreak,
        Spacing.gutter,
        Spacing.sectionBreak,
        0,
      ),
      child: Wrap(
        spacing: Spacing.cardInternal,
        runSpacing: Spacing.chip,
        children: [
          _Stat(
            icon: Icons.shield_outlined,
            label: l10n.adminSeatCount(admins),
            // One admin is not an error — it is a working configuration — but
            // it is the one worth noticing, because the next demotion has
            // nowhere to go.
            warn: admins <= 1,
          ),
          if (gaps > 0)
            _Stat(
              icon: Icons.key_off_outlined,
              label: l10n.twoFactorGapCount(gaps),
              warn: true,
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, this.warn = false});

  final IconData icon;
  final String label;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final colour = warn
        ? const Color(0xFF8A5A00)
        : context.scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.cardInternal,
        vertical: Spacing.chip,
      ),
      decoration: BoxDecoration(
        color: warn ? const Color(0xFFFDF6EC) : context.scheme.surface,
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.all(
          color: warn ? const Color(0xFFEEDCC0) : context.colors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colour),
          const SizedBox(width: Spacing.chip),
          // Flexible, because a Row hands non-flex children *unbounded*
          // main-axis constraints: the sentence would lay out on one line at
          // its full intrinsic width and run off a 390dp screen rather than
          // wrapping inside the chip.
          Flexible(
            child: Text(
              label,
              style: context.text.meta.copyWith(color: colour),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCell extends StatelessWidget {
  const _PersonCell({required this.member});

  final StaffMemberDto member;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.skeleton,
            shape: BoxShape.circle,
          ),
          child: Text(
            member.user.initials,
            style: context.text.overline.copyWith(
              fontSize: 10.5,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: Spacing.cardInternal),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              // The missing second factor takes the line ahead of the email:
              // an account that cannot complete a sign-in is the actionable
              // fact, and the address is on the panel.
              Text(
                member.twoFactorEnrolled ? member.email : l10n.noSecondFactor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.meta.copyWith(
                  color: member.twoFactorEnrolled
                      ? context.scheme.onSurfaceVariant
                      : context.scheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Account status, as a chip.
///
/// Not a [StatusBadge]: those name article and stream states, and adding three
/// more values to that enum would put "suspended" in the same list as "on air".
class StaffStatusChip extends StatelessWidget {
  const StaffStatusChip({super.key, required this.status});

  final StaffStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    final (background, foreground, border) = switch (status) {
      StaffStatus.active => (
        colors.accentContainer,
        colors.onAccentContainer,
        colors.accentContainerOutline,
      ),
      StaffStatus.invited => (
        const Color(0xFFE8F1FA),
        colors.linkText,
        const Color(0xFFC8DDF0),
      ),
      StaffStatus.suspended => (
        context.scheme.errorContainer,
        context.scheme.error,
        colors.errorContainerOutline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        ConsoleLabels.staffStatus(l10n, status),
        style: context.text.overline.copyWith(fontSize: 10, color: foreground),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});

  final StaffMemberDto member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.listRhythm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.colors.outlineSubtle),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PersonCell(member: member),
            const SizedBox(height: Spacing.cardInternal),
            Row(
              children: [
                StaffStatusChip(status: member.status),
                const SizedBox(width: Spacing.chip),
                Expanded(
                  child: Text(
                    ConsoleLabels.role(l10n, member.role),
                    style: context.text.meta.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffSkeleton extends StatelessWidget {
  const _StaffSkeleton();

  @override
  Widget build(BuildContext context) {
    final columns = [
      ConsoleColumn(label: context.l10n.colPerson, flex: 4),
      const ConsoleColumn(label: '', width: 130),
      const ConsoleColumn(label: '', width: 116),
    ];

    return ListView(
      children: [
        for (var i = 0; i < 7; i++) ConsoleTableRowSkeleton(columns: columns),
      ],
    );
  }
}

/// Read by the member panel so both surfaces agree on role ordering.
const roleOrder = ConsoleRole.values;
