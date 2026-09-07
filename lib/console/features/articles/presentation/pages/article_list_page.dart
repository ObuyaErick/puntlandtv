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
import '../../../../app/console_navigation.dart';
import '../../../../core/localised.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../operations/presentation/pages/categories_page.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_table.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/console_user.dart';
import '../controllers/article_list_controller.dart';
import '../widgets/article_row_card.dart';
import '../widgets/bulk_action_bar.dart';

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
          onPressed: () => _startDraft(context, ref),
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
            // An empty newsroom and a filter that matched nothing are not the
            // same problem, and telling someone to write their first article
            // when they have thirty behind a filter is how a working screen
            // gets reported as broken.
            final narrowed = ref.watch(articleFilterProvider).isNarrowed;
            return EmptyView(
              title: narrowed ? l10n.emptyFilteredArticles : l10n.emptyArticles,
              body: narrowed
                  ? l10n.emptyFilteredArticlesBody
                  : l10n.emptyArticlesBody,
              icon: narrowed
                  ? Icons.filter_alt_off_outlined
                  : Icons.article_outlined,
              actionLabel: narrowed ? l10n.clearFilters : null,
              onAction: narrowed
                  ? ref.read(articleFilterProvider.notifier).clear
                  : null,
            );
          }
          return _ArticleBody(rows: rows, canPublish: canPublish);
        },
      ),
    );
  }
}

/// Starts a draft and opens it.
///
/// The category is the first one configured rather than a choice made up
/// front: the story does not have a section yet, the publishing panel is where
/// that decision belongs, and a modal asking for one before a headline exists
/// is a question asked at the wrong moment.
Future<void> _startDraft(BuildContext context, WidgetRef ref) async {
  final categories = ref.read(categoryConfigProvider).value ?? const [];
  final messenger = context;

  try {
    final created = await ref
        .read(articleActionsProvider.notifier)
        .create(
          categorySlug: categories.isEmpty ? 'national' : categories.first.slug,
          sourceLocale: 'so',
        );
    if (!messenger.mounted) return;
    messenger.openArticle(created.id);
  } on Failure {
    if (!messenger.mounted) return;
    showConsoleToast(
      messenger,
      message: messenger.l10n.saveFailed,
      kind: ToastKind.error,
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
    final locale = context.languageCode;
    final query = ref.watch(articleFilterProvider);
    final controller = ref.read(articleFilterProvider.notifier);
    final categories = ref.watch(categoryConfigProvider).value ?? const [];
    final authors = ref.watch(articleAuthorsProvider).value ?? const [];

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

    final categoryName = categories
        .where((c) => c.slug == query.categorySlug)
        .map((c) => c.nameFor(locale))
        // A slug the configured categories no longer contain still has to
        // read as something: the filter is live, and silently showing "All"
        // while the list stays narrowed is the worst of both.
        .firstOrNull;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              // Keyed: the row scrolls, so anything reaching for a filter that
              // is off the end — a test, an accessibility scroll-to — needs to
              // be able to name the scroller.
              key: const Key('article-filters'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: Spacing.sectionBreak),
              children: [
                for (final (filter, label) in chips) ...[
                  Center(
                    child: ConsoleFilterChip(
                      label: label,
                      count: counts?.forFilter(filter) ?? 0,
                      selected: query.status == filter,
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
                  child: VerticalDivider(
                    width: 1,
                    color: context.colors.outline,
                  ),
                ),
                Center(
                  child: _FilterSelect<String?>(
                    key: const Key('filter-category'),
                    label: l10n.filterCategory(
                      categoryName ??
                          query.categorySlug ??
                          l10n.filterAllArticles,
                    ),
                    active: query.categorySlug != null,
                    value: query.categorySlug,
                    options: [
                      (null, l10n.filterAllArticles),
                      for (final category in categories)
                        (category.slug, category.nameFor(locale)),
                    ],
                    onSelected: controller.setCategory,
                  ),
                ),
                const SizedBox(width: Spacing.chip),
                Center(
                  child: _FilterSelect<String?>(
                    key: const Key('filter-locale'),
                    // The language name, not the raw code: a filter is prose like
                    // everything else on this screen.
                    label: l10n.filterLocale(
                      query.locale == null
                          ? l10n.filterAllArticles
                          : context.languageNameOf(query.locale!),
                    ),
                    active: query.locale != null,
                    value: query.locale,
                    options: [
                      (null, l10n.filterAllArticles),
                      for (final code in AdminArticleDto.requiredLocales)
                        (code, context.languageNameOf(code)),
                    ],
                    onSelected: controller.setLocale,
                  ),
                ),
                // No author filter for a Journalist: their list is already scoped to
                // their own byline, so the only choice the control could offer is
                // the one they are already on.
                if (canPublish) ...[
                  const SizedBox(width: Spacing.chip),
                  Center(
                    child: _FilterSelect<String?>(
                      key: const Key('filter-author'),
                      label: l10n.filterAuthor(
                        authors
                                .where((a) => a.id == query.authorId)
                                .map((a) => a.name)
                                .firstOrNull ??
                            l10n.filterAnyone,
                      ),
                      active: query.authorId != null,
                      value: query.authorId,
                      options: [
                        (null, l10n.filterAnyone),
                        for (final author in authors) (author.id, author.name),
                      ],
                      onSelected: controller.setAuthor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Outside the scroller, and deliberately. Eight controls do not fit
          // a 1440dp row, and the one that undoes them all is the one that
          // must never be the thing you have to scroll to find.
          Padding(
            padding: const EdgeInsets.only(
              left: Spacing.chip,
              right: Spacing.sectionBreak,
            ),
            child: TextButton(
              // Disabled on an unfiltered list rather than hidden: a control
              // that disappears is one people stop looking for.
              onPressed: query.isNarrowed ? controller.clear : null,
              child: Text(l10n.clearFilters),
            ),
          ),
        ],
      ),
    );
  }
}

/// A narrowing filter, rendered as a bordered select.
///
/// The chosen value is carried in the button's own label rather than only in
/// the open menu, so a filtered list says what it is filtered by without
/// anyone having to open anything.
class _FilterSelect<T> extends StatelessWidget {
  const _FilterSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.active = false,
  });

  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  /// Whether this filter is narrowing anything. Outlined when it is not,
  /// tinted when it is — one glance says which of three filters is on.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      tooltip: label,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final (optionValue, optionLabel) in options)
          PopupMenuItem(
            value: optionValue,
            child: Row(
              children: [
                Expanded(child: Text(optionLabel)),
                if (optionValue == value) ...[
                  const SizedBox(width: Spacing.cardInternal),
                  Icon(Icons.check_rounded, size: 18, color: colors.link),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.cardInternal),
        decoration: BoxDecoration(
          color: active ? colors.accentContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.button),
          border: Border.all(color: active ? colors.accent : colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.text.body.copyWith(
                color: active
                    ? colors.onAccentContainer
                    : context.scheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: active
                  ? colors.onAccentContainer
                  : context.scheme.onSurfaceVariant,
            ),
          ],
        ),
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
                        onTap: () => context.openArticle(article.id),
                      ),
                    );
                  }

                  return ConsoleTableRow(
                    columns: columns,
                    selected: checked,
                    onTap: () => context.openArticle(article.id),
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
                      _RowMenu(article: article, canPublish: canPublish),
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
class _RowMenu extends ConsumerWidget {
  const _RowMenu({required this.article, required this.canPublish});

  final AdminArticleDto article;
  final bool canPublish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = ref.read(articleActionsProvider.notifier);

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: () => context.openArticle(article.id),
          child: Text(l10n.openInEditor),
        ),
        if (canPublish)
          if (article.status == ArticleStatus.published)
            MenuItemButton(
              onPressed: () =>
                  actions.setStatus([article.id], ArticleStatus.draft),
              child: Text(l10n.unpublish),
            )
          else
            MenuItemButton(
              onPressed: () =>
                  actions.setStatus([article.id], ArticleStatus.published),
              child: Text(l10n.publishNow),
            ),
        MenuItemButton(
          onPressed: () => _confirmDelete(context, ref),
          child: Text(
            l10n.delete,
            style: TextStyle(color: context.scheme.error),
          ),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        tooltip: l10n.rowActions,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        icon: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: context.scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Deleting is asked about, unlike every other action here.
  ///
  /// The rest are reversible from the same menu; this one is not, and a
  /// published story removed by a mis-click is a URL that starts 404ing for
  /// readers who already have the link.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final title =
        article.translationFor(context.languageCode)?.title ?? article.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteArticleTitle, style: context.text.title),
        content: Text(l10n.deleteArticleBody(title), style: context.text.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.scheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(articleActionsProvider.notifier).delete(article.id);
    }
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
                    // Flexible: at 840 the headline column is narrow enough
                    // that the badge and the headline have to share.
                    const Flexible(
                      child: StatusBadge(kind: BadgeKind.breaking),
                    ),
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
