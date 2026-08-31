import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/schedule_dto.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/status_badge.dart';

final dayScheduleProvider = FutureProvider<DayScheduleDto>(
  (ref) => ref.watch(adminApiProvider).fetchSchedule(DateTime.now()),
);

/// The day's programming, with its problems shown rather than counted.
///
/// Gaps and overlaps are derived from the slots on every build, never stored.
/// A stored flag goes stale the moment somebody moves a programme, and a
/// schedule that claims to be clean when it is not is worse than no check.
class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedule = ref.watch(dayScheduleProvider);
    final day = schedule.value;

    return ConsolePage(
      title: l10n.scheduleTitle,
      subtitle: AppDateFormat.weekdayDayMonth(
        DateTime.now(),
        context.languageCode,
      ),
      actions: [
        if (day != null && day.overlaps.isNotEmpty)
          OutlinedButton(
            onPressed: () async {
              await ref
                  .read(adminApiProvider)
                  .saveSchedule(day.resolveOverlaps());
              ref.invalidate(dayScheduleProvider);
            },
            child: Text(l10n.autoResolveOverlap),
          ),
        FilledButton(
          // Publishing a day with an overlap means something gets cut and
          // nobody chose what. Gaps are only a warning — a continuity slate
          // fills them.
          onPressed: (day?.isPublishable ?? false) ? () {} : null,
          child: Text(l10n.publishDay),
        ),
      ],
      notice: day == null || day.issues.isEmpty
          ? null
          : ConsoleNotice(
              icon: Icons.warning_amber_rounded,
              message: day.isPublishable
                  ? l10n.gapsAndOverlaps(day.gaps.length, day.overlaps.length)
                  : l10n.publishBlockedByOverlap,
            ),
      child: schedule.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(dayScheduleProvider),
        ),
        data: (data) => _DayGrid(schedule: data),
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.schedule});

  final DayScheduleDto schedule;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = schedule.ordered;
    final issues = schedule.issues;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.gutter,
        0,
        Spacing.gutter,
        Spacing.emptyState,
      ),
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _SlotRow(slot: rows[i]),
          // Issue markers sit between the two slots they concern, so the
          // problem is read where it happens rather than in a list elsewhere.
          for (final issue in issues.where(
            (x) => x.slotIds.first == rows[i].id,
          ))
            _IssueMarker(issue: issue),
        ],
        const SizedBox(height: Spacing.listRhythm),
        Text(
          l10n.dayTotal(
            schedule.programmedTime.inHours,
            schedule.programmedTime.inMinutes % 60,
          ),
          style: context.text.meta.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot});

  final ScheduleSlotDto slot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.languageCode;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.chip),
      padding: const EdgeInsets.all(Spacing.listRhythm),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(
          color: slot.isLive ? context.colors.accent : context.colors.outline,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              AppDateFormat.time(slot.startsAt, language),
              style: context.text.label.copyWith(color: context.scheme.primary),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        slot.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: context.scheme.primary,
                        ),
                      ),
                    ),
                    if (slot.isLive) ...[
                      const SizedBox(width: Spacing.chip),
                      const StatusBadge(kind: BadgeKind.live),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppDateFormat.time(slot.startsAt, language)} – '
                  '${AppDateFormat.time(slot.endsAt, language)} · '
                  '${[?slot.genre, l10n.durationMinutes(slot.duration.inMinutes)].join(' · ')}',
                  style: context.text.meta.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueMarker extends StatelessWidget {
  const _IssueMarker({required this.issue});

  final ScheduleIssue issue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.languageCode;
    final isOverlap = issue.kind == ScheduleIssueKind.overlap;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.chip),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.listRhythm,
        vertical: Spacing.cardInternal,
      ),
      decoration: BoxDecoration(
        // Amber for a gap, red for an overlap: a gap is filled by a
        // continuity slate and is a warning; an overlap is an error.
        color: isOverlap
            ? context.scheme.errorContainer
            : const Color(0xFFFDF6EC),
        borderRadius: Radii.cardBorder,
        border: Border.all(
          color: isOverlap
              ? context.colors.errorContainerOutline
              : const Color(0xFFEEDCC0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverlap ? Icons.error_outline_rounded : Icons.more_horiz_rounded,
            size: 16,
            color: isOverlap ? context.scheme.error : const Color(0xFF8A5A00),
          ),
          const SizedBox(width: Spacing.chip),
          Expanded(
            child: Text(
              isOverlap
                  ? l10n.overlapLabel(issue.length.inMinutes)
                  : l10n.gapLabel(
                      AppDateFormat.time(issue.from, language),
                      AppDateFormat.time(issue.to, language),
                    ),
              style: context.text.meta.copyWith(
                color: isOverlap
                    ? context.scheme.error
                    : const Color(0xFF8A5A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
