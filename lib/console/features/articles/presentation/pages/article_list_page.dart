import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/admin_api/puntland_admin_api.dart';
import '../../../../core/localised.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../operations/presentation/pages/categories_page.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_table.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/console_user.dart';
import '../controllers/article_list_controller.dart';
import '../widgets/article_row_card.dart';
import '../widgets/bulk_action_bar.dart';
import 'article_editor_panel.dart';

/// The newsroom's article list.
///
/// Two presentations of the same data: a real table from expanded up, and
/// cards at compact — squeezing six columns onto a 390dp screen produces a
/// table nobody can read, and a duty editor approving a story at 23:00 is on
/// their phone.
class ArticleListPage extends ConsumerWidget {
  const ArticleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final articles = ref.watch(articleListProvider);
    final counts = ref.watch(articleCountsProvider).value;
    final canPublish = user?.can(Capability.publishArticles) ?? false;

    return ConsolePage(
      title: canPublish ? l10n.articlesTitle : l10n.myArticlesTitle,
      subtitle: articles.value == null
          ? null
          : l10n.itemCount(articles.value!.length),
      actions: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(canPublish ? l10n.newArticle : l10n.newDraft),
        ),
      ],
      notice: canPublish ? null : ConsoleNotice(message: l10n.journalistNotice),
      filters: _FilterRow(counts: counts, canPublish: canPublish),
      child: articles.when(
        loading: () => const _ListSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(articleListProvider),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return EmptyView(
              title: l10n.emptyArticles,
              body: l10n.emptyArticlesBody,
              icon: Icons.article_outlined,
            );
          }
          return _ArticleBody(rows: rows, canPublish: canPublish);
        },
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.counts, required this.canPublish});

  final ArticleCounts? counts;
  final bool canPublish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(articleFilterProvider);
    final controller = ref.read(articleFilterProvider.notifier);

    final chips = <(ArticleStatusFilter, String)>[
      (
        ArticleStatusFilter.all,
        canPublish ? l10n.filterAllArticles : l10n.filterMine,
      ),
      (ArticleStatusFilter.draft, l10n.statusDraft),
      (ArticleStatusFilter.inReview, l10n.statusInReview),
      if (canPublish) (ArticleStatusFilter.scheduled, l10n.statusScheduled),
      (ArticleStatusFilter.published, l10n.statusPublished),
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sectionBreak),
        children: [
          for (final (filter, label) in chips) ...[
            Center(
              child: ConsoleFilterChip(
                label: label,
                count: counts?.forFilter(filter) ?? 0,
                selected: selected == filter,
                onTap: () => controller.select(filter),
              ),
            ),
            const SizedBox(width: Spacing.chip),
          ],
          // A rule between the status chips and the narrowing filters: they
          // compose differently, and running them together reads as one long
          // undifferentiated row.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.chip,
              vertical: Spacing.listRhythm,
            ),
            child: VerticalDivider(width: 1, color: context.colors.outline),
          ),
          for (final label in [
            l10n.filterCategory(l10n.filterAllArticles),
            // The language name, not the raw code: a filter is prose like
            // everything else on this screen.
            l10n.filterLocale(context.languageNameOf('so')),
            l10n.filterAuthor(l10n.filterAnyone),
          ]) ...[
            Center(child: _FilterSelect(label: label)),
            const SizedBox(width: Spacing.chip),
          ],
          Center(
            child: TextButton(
              onPressed: () => controller.select(ArticleStatusFilter.all),
              child: Text(l10n.clearFilters),
            ),
          ),
        ],
      ),
    );
  }
}

/// A narrowing filter, rendered as a bordered select.
class _FilterSelect extends StatelessWidget {
  const _FilterSelect({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        side: BorderSide(color: context.colors.outline),
        foregroundColor: context.scheme.onSurface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: context.scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ArticleBody extends ConsumerWidget {
  const _ArticleBody({required this.rows, required this.canPublish});

  final List<AdminArticleDto> rows;
  final bool canPublish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selection = ref.watch(articleSelectionProvider);
    // Everything on this screen resolves through the active locale — labels
    // and localised data alike — so one language switch re-hydrates the whole
    // table rather than leaving it half-translated.
    final locale = context.languageCode;
    final categoryNames = {
      for (final category
          in ref.watch(categoryConfigProvider).value ?? const [])
        category.slug: category.nameFor(locale),
    };

    // Widths from the artboard's grid: 1fr / 128 / 96 / 116 / 132 / 108 / 56.
    final columns = <ConsoleColumn>[
      ConsoleColumn(label: l10n.colHeadline, flex: 4),
      ConsoleColumn(label: l10n.colCategory, width: 128),
      // No LOCALE column. Which languages a row exists in is a technical
      // field, and a column of `SO EN` chips is noise an editor cannot act on.
      // What *is* actionable — a missing or stale translation — is said in
      // words under the headline instead.
      if (canPublish) ConsoleColumn(label: l10n.colAuthor, width: 116),
      ConsoleColumn(label: '${l10n.colUpdated} ↓', width: 132),
      ConsoleColumn(label: l10n.colStatus, width: 108),
      const ConsoleColumn(label: '', width: 56),
    ];

    return WindowSizeScope(
      builder: (context, size) {
        final asTable = size.isAtLeastExpanded;

        return Column(
          spacing: 12,
          children: [
            if (selection.isNotEmpty && canPublish)
              BulkActionBar(
                count: selection.length,
                onPublish: () => ref
                    .read(articleActionsProvider.notifier)
                    .setStatus(selection, ArticleStatus.published),
                onUnpublish: () => ref
                    .read(articleActionsProvider.notifier)
                    .setStatus(selection, ArticleStatus.draft),
                onSchedule: () => ref
                    .read(articleActionsProvider.notifier)
                    .setStatus(selection, ArticleStatus.scheduled),
                onChangeCategory: () {},
                onDeselect: ref.read(articleSelectionProvider.notifier).clear,
              ),
            if (asTable) ConsoleTableHeader(columns: columns, leading: _gap),
            Expanded(
              child: ListView.builder(
                padding: asTable
                    ? EdgeInsets.zero
                    : const EdgeInsets.fromLTRB(
                        Spacing.gutter,
                        0,
                        Spacing.gutter,
                        Spacing.emptyState,
                      ),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final article = rows[index];
                  final checked = selection.contains(article.id);

                  if (!asTable) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: Spacing.cardInternal,
                      ),
                      child: ArticleRowCard(
                        article: article,
                        categoryName:
                            categoryNames[article.categorySlug] ??
                            article.categorySlug,
                        showAuthor: canPublish,
                        onTap: () =>
                            showArticleEditor(context, article: article),
                      ),
                    );
                  }

                  return ConsoleTableRow(
                    columns: columns,
                    selected: checked,
                    onTap: () => showArticleEditor(context, article: article),
                    leading: canPublish
                        ? Checkbox(
                            value: checked,
                            onChanged: (_) => ref
                                .read(articleSelectionProvider.notifier)
                                .toggle(article.id),
                          )
                        : _gap,
                    cells: [
                      _HeadlineCell(article: article, locale: locale),
                      // The localised display name, not the slug: the slug is
                      // an identifier for deep links, and showing it here made
                      // the newsroom read machine keys instead of category
                      // names.
                      Text(
                        categoryNames[article.categorySlug] ??
                            article.categorySlug,
                        style: context.text.meta.copyWith(
                          color: context.scheme.onSurface,
                        ),
                      ),
                      if (canPublish)
                        Text(
                          article.authorName,
                          style: context.text.meta.copyWith(
                            color: context.scheme.onSurface,
                          ),
                        ),
                      Text(
                        AppDateFormat.time(
                          article.updatedAt,
                          context.languageCode,
                        ),
                        style: context.text.meta.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge.forArticle(article.status),
                      ),
                      _RowMenu(article: article),
                    ],
                  );
                },
              ),
            ),
            if (asTable) _PaginationBar(total: rows.length),
          ],
        );
      },
    );
  }

  /// Keeps the header labels aligned with cells when there is no checkbox.
  static const _gap = SizedBox(width: 18);
}

/// The 56dp footer: what is on screen, and how to move.
class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.total});

  final int total;

  static const _pageSize = 25;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = total < _pageSize ? total : _pageSize;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sectionBreak),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(top: BorderSide(color: context.colors.outline)),
      ),
      child: Row(
        children: [
          Text(
            l10n.rowsRange(total == 0 ? 0 : 1, shown, total),
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              side: BorderSide(color: context.colors.outline),
              foregroundColor: context.scheme.onSurface,
            ),
            child: Text(l10n.perPage(_pageSize)),
          ),
          const SizedBox(width: Spacing.cardInternal),
          _PageStep(icon: Icons.chevron_left_rounded, onPressed: null),
          const SizedBox(width: Spacing.chip),
          _PageStep(
            icon: Icons.chevron_right_rounded,
            onPressed: total > _pageSize ? () {} : null,
          ),
        ],
      ),
    );
  }
}

class _PageStep extends StatelessWidget {
  const _PageStep({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          side: BorderSide(color: context.colors.outline),
        ),
        child: Icon(icon, size: 18, color: context.scheme.onSurfaceVariant),
      ),
    );
  }
}

/// Per-row overflow. The actions a single row needs are the bulk ones minus
/// the selection, so they live behind a menu rather than six icons per line.
class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.article});

  final AdminArticleDto article;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      tooltip: context.l10n.rowActions,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: context.scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Headline plus the one-line editorial detail beneath it.
class _HeadlineCell extends StatelessWidget {
  const _HeadlineCell({required this.article, required this.locale});

  final AdminArticleDto article;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = article.translationFor(locale);

    // The sub-label carries the thing an editor most needs to notice: a
    // missing or stale translation, ahead of reading time. Both name the
    // language in the active UI language rather than hard-coding "English".
    final missing = article.missingLocales(const ['so', 'en']);
    final stale = article.staleLocales;

    final detail = missing.isNotEmpty
        ? l10n.missingTranslation(context.languageNameOf(missing.first))
        : stale.isNotEmpty
        ? l10n.translationBehindIn(context.languageNameOf(stale.first))
        : '${l10n.minRead(shown?.readingMinutes ?? 1)}'
              '${article.imageUrl != null ? ' · ${l10n.heroSet}' : ''}';

    final needsAttention = missing.isNotEmpty || stale.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // A 52×40 thumbnail, per the artboard's first grid column — an editor
        // scanning a list recognises the picture before the headline.
        Container(
          width: 52,
          height: 40,
          decoration: BoxDecoration(
            color: context.colors.imagePlaceholder,
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: article.imageUrl == null
              ? null
              : Image.network(article.imageUrl!, fit: BoxFit.cover),
        ),
        const SizedBox(width: Spacing.cardInternal),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (article.isBreaking) ...[
                    const StatusBadge(kind: BadgeKind.breaking),
                    const SizedBox(width: Spacing.chip),
                  ],
                  Flexible(
                    child: Text(
                      shown?.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.meta.copyWith(
                  color: needsAttention
                      ? context.scheme.error
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListSkeleton extends ConsumerWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = [
      ConsoleColumn(label: context.l10n.colHeadline, flex: 4),
      const ConsoleColumn(label: '', width: 110),
      const ConsoleColumn(label: '', width: 116),
    ];

    return ListView(
      children: [
        for (var i = 0; i < 8; i++) ConsoleTableRowSkeleton(columns: columns),
      ],
    );
  }
}
