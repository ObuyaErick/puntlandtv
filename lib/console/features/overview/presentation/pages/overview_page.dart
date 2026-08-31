import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/app_number_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/admin_api/dto/newsroom_summary_dto.dart';
import '../../../../core/admin_api/dto/push_dto.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../articles/presentation/controllers/article_list_controller.dart';
import '../../../operations/presentation/controllers/push_controller.dart';
import '../widgets/overview_cards.dart';

final newsroomSummaryProvider = FutureProvider<NewsroomSummaryDto>(
  (ref) => ref.watch(adminApiProvider).fetchNewsroomSummary(),
);

/// The "is everything OK" screen.
///
/// Two rows. The first answers whether the station is up and what needs
/// attention; the second is the day's work — what is queued to publish, and
/// what has already gone out to phones.
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(newsroomSummaryProvider);

    // Through the clock provider, like every other timestamp on this screen —
    // reading `DateTime.now()` here would shift the golden every minute.
    final now = ref.watch(consoleClockProvider)();

    return ConsolePage(
      title: l10n.overviewTitle,
      inlineSubtitle: true,
      subtitle:
          '${AppDateFormat.weekdayDayMonth(now, context.languageCode)}'
          ' · ${AppDateFormat.time(now, context.languageCode)}',
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, size: 17),
          label: Text(l10n.newAlert),
        ),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.newArticle),
        ),
      ],
      child: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(newsroomSummaryProvider),
        ),
        data: (data) => _OverviewBody(summary: data),
      ),
    );
  }
}

class _OverviewBody extends ConsumerWidget {
  const _OverviewBody({required this.summary});

  final NewsroomSummaryDto summary;

  /// Content inset from artboard 11A: `padding: 24px 28px; gap: 20px`.
  static const _gap = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final size = context.windowSize;
    final onAir = OnAirCard(
      onAir: summary.onAir,
      stacked: !size.isAtLeastMedium,
    );
    final published = StatCard(
      label: l10n.publishedToday,
      value: '${summary.publishedToday}',
    );
    final awaiting = StatCard(
      label: l10n.awaitingReview,
      value: '${summary.awaitingReview}',
      detail: l10n.breakingFlagged(summary.breakingFlagged),
    );
    final failed = FailureCard(
      label: l10n.failedIngests,
      value: '${summary.failedIngests}',
      detail: summary.failedIngestDetail,
      actionLabel: l10n.reviewFailures,
      onAction: () {},
    );

    final queue = const _PublishingQueueCard();
    final pushes = const _RecentPushesCard();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.sectionBreak,
        Spacing.gutter + 4,
        Spacing.sectionBreak,
        Spacing.sectionBreak,
      ),
      child: WindowSizeScope(
        builder: (context, size) {
          // Expanded and up: the artboard's proportions — 1.35 / 1 / 1, with
          // the two stat cards stacked in the middle column, then 1.6 / 1.
          if (size.isAtLeastExpanded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 135, child: onAir),
                      const SizedBox(width: _gap),
                      Expanded(
                        flex: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: published),
                            const SizedBox(height: Spacing.cardInternal),
                            Expanded(child: awaiting),
                          ],
                        ),
                      ),
                      const SizedBox(width: _gap),
                      Expanded(flex: 100, child: failed),
                    ],
                  ),
                ),
                const SizedBox(height: _gap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 160, child: queue),
                    const SizedBox(width: _gap),
                    Expanded(flex: 100, child: pushes),
                  ],
                ),
              ],
            );
          }

          // Medium: the on-air card keeps the full width — it is the headline
          // — and the two stat cards pair off beneath it.
          if (size.isAtLeastMedium) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                onAir,
                const SizedBox(height: _gap),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: published),
                      const SizedBox(width: Spacing.cardInternal),
                      Expanded(child: awaiting),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.cardInternal),
                failed,
                const SizedBox(height: _gap),
                queue,
                const SizedBox(height: _gap),
                pushes,
              ],
            );
          }

          // Compact: one column. Nothing pairs off at 390dp without one half
          // becoming unreadable.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final card in [
                onAir,
                published,
                awaiting,
                failed,
                queue,
                pushes,
              ]) ...[card, const SizedBox(height: Spacing.cardInternal)],
            ],
          );
        },
      ),
    );
  }
}

/// Today's scheduled and in-review articles.
class _PublishingQueueCard extends ConsumerWidget {
  const _PublishingQueueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.languageCode;
    final articles = ref.watch(articleListProvider).value ?? const [];

    final queued = articles
        .where(
          (a) =>
              a.status == ArticleStatus.scheduled ||
              a.status == ArticleStatus.inReview ||
              a.status == ArticleStatus.draft,
        )
        .toList(growable: false);

    return PanelCard(
      title: l10n.todaysQueue,
      action: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
        child: Text(l10n.openArticles),
      ),
      padded: false,
      child: queued.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(Spacing.gutter),
              child: Text(
                l10n.queueEmpty,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                _QueueHeader(),
                for (final article in queued)
                  _QueueRow(article: article, locale: locale),
              ],
            ),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: context.colors.outlineSubtle)),
      ),
      child: Row(
        children: [
          SizedBox(width: 88, child: _label(context, l10n.colTime)),
          Expanded(child: _label(context, l10n.colHeadline)),
          SizedBox(width: 96, child: _label(context, l10n.colStatus)),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
    text,
    style: context.text.overline.copyWith(
      fontSize: 10.5,
      color: context.scheme.onSurfaceVariant,
    ),
  );
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.article, required this.locale});

  final AdminArticleDto article;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final time = article.scheduledFor ?? article.updatedAt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.outlineSubtle)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              AppDateFormat.time(time, context.languageCode),
              style: context.text.meta.copyWith(
                fontWeight: FontWeight.w500,
                color: context.scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: Spacing.cardInternal),
              child: Text(
                article.translationFor(locale)?.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.cardTitle.copyWith(
                  fontSize: 14,
                  height: 19 / 14,
                  color: context.scheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge.forArticle(article.status),
            ),
          ),
        ],
      ),
    );
  }
}

/// What has already gone out to phones.
class _RecentPushesCard extends ConsumerWidget {
  const _RecentPushesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(pushHistoryProvider).value ?? const [];

    return PanelCard(
      title: l10n.recentPushes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in history) ...[
            _PushEntry(entry: entry),
            if (entry != history.last)
              Divider(height: 32, color: context.colors.outlineSubtle),
          ],
        ],
      ),
    );
  }
}

class _PushEntry extends ConsumerWidget {
  const _PushEntry({required this.entry});

  final PushHistoryEntryDto entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Measured against the console clock, not `DateTime.now()`: the fixture
    // seeds history relative to an injectable clock, and mixing the two
    // produced negative ages like "-288m ago".
    final elapsed = ref.watch(consoleClockProvider)().difference(entry.sentAt);
    // Clamped: a timestamp ahead of the clock — skew, or a record written by
    // another machine — should read as "just now", never as "-286m ago".
    final ago = elapsed.isNegative
        ? l10n.justNow
        : elapsed.inHours >= 1
        ? '${elapsed.inHours}h'
        : '${elapsed.inMinutes}m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (entry.topic == 'breaking') ...[
              const StatusBadge(kind: BadgeKind.breaking),
              const SizedBox(width: Spacing.chip),
            ],
            Flexible(
              child: Text(
                '$ago · ${entry.sentBy}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.chip),
        Text(
          entry.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.cardTitle.copyWith(
            fontSize: 15,
            color: context.scheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.deliveredOf(
            AppNumberFormat.decimal(entry.delivered, context.languageCode),
            AppNumberFormat.decimal(entry.targeted, context.languageCode),
          ),
          style: context.text.meta.copyWith(color: context.colors.accent),
        ),
      ],
    );
  }
}
