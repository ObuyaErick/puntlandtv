import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/responsive/adaptive_layout.dart';
import '../../../../core/responsive/window_size.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bar.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/article.dart';
import '../controllers/news_controllers.dart';
import '../widgets/article_card.dart';
import '../widgets/category_tabs.dart';
import 'article_page.dart';

/// The article open in the detail pane at expanded widths.
///
/// Null means "nothing selected yet", which the pane renders as a prompt
/// rather than an empty rectangle.
class SelectedArticle extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String slug) => state = slug;

  void clear() => state = null;
}

final selectedArticleProvider = NotifierProvider<SelectedArticle, String?>(
  SelectedArticle.new,
);

class NewsFeedPage extends ConsumerWidget {
  const NewsFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(categoriesProvider);
    final offline = ref.watch(isOfflineProvider);

    return WindowSizeScope(
      builder: (context, size) {
        final listDetail = size.isAtLeastExpanded;

        final feedColumn = Column(
          children: [
            if (offline) const OfflineBanner(),
            categories.when(
              data: (list) => CategoryTabs(
                categories: list,
                selectedSlug: selected,
                onSelected: ref.read(selectedCategoryProvider.notifier).select,
              ),
              loading: () => const SizedBox(height: 46),
              error: (_, _) => const SizedBox(height: 46),
            ),
            Expanded(
              child: _FeedBody(categorySlug: selected, listDetail: listDetail),
            ),
          ],
        );

        return Scaffold(
          appBar: PltvAppBar(onLiveTap: () => context.go(Routes.live)),
          body: listDetail
              ? Row(
                  children: [
                    // The list pane stays a comfortable single-column width;
                    // the detail pane takes the rest.
                    SizedBox(width: 420, child: feedColumn),
                    VerticalDivider(
                      width: 1,
                      color: context.colors.outlineSubtle,
                    ),
                    const Expanded(child: _DetailPane()),
                  ],
                )
              : feedColumn,
        );
      },
    );
  }
}

/// The right-hand pane at expanded widths.
class _DetailPane extends ConsumerWidget {
  const _DetailPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slug = ref.watch(selectedArticleProvider);

    if (slug == null) {
      return EmptyView(
        title: context.l10n.selectArticleTitle,
        body: context.l10n.selectArticleBody,
        icon: Icons.article_outlined,
      );
    }

    // Reuses the whole article screen rather than a cut-down copy, so the two
    // never drift. It measures itself against the pane, not the window.
    return ArticlePage(slug: slug, embedded: true);
  }
}

class _FeedBody extends ConsumerWidget {
  const _FeedBody({required this.categorySlug, required this.listDetail});

  final String categorySlug;
  final bool listDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final feed = ref.watch(feedProvider(categorySlug));
    final controller = ref.read(feedProvider(categorySlug).notifier);

    return feed.when(
      loading: () => const FeedSkeleton(),
      error: (error, _) => ErrorView(
        failure: error is Failure
            ? error
            : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
        onRetry: controller.refresh,
        onSecondary: () => context.go(Routes.saved),
      ),
      data: (feedState) {
        if (feedState.items.isEmpty) {
          return EmptyView(
            title: l10n.emptyCategoryTitle,
            body: l10n.emptyCategoryBody,
            icon: Icons.article_outlined,
          );
        }

        return WindowSizeScope(
          builder: (context, size) {
            // Two columns only at medium. In list-detail the list pane is
            // narrow, so it stays a single column however wide the window is.
            final columns = !listDetail && size == WindowSizeClass.medium
                ? 2
                : 1;

            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: NotificationListener<ScrollNotification>(
                // Prefetch a page before the user reaches the bottom, so on a
                // slow connection the next rows are usually there by the time
                // they arrive rather than after a visible stall.
                onNotification: (notification) {
                  final metrics = notification.metrics;
                  if (metrics.pixels > metrics.maxScrollExtent - 600) {
                    controller.loadMore();
                  }
                  return false;
                },
                child: _FeedScroll(
                  items: feedState.items,
                  columns: columns,
                  hasMore: feedState.hasMore,
                  onOpen: (article) => _open(context, ref, article),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _open(BuildContext context, WidgetRef ref, ArticleSummary article) {
    if (listDetail) {
      ref.read(selectedArticleProvider.notifier).select(article.slug);
      return;
    }
    context.push(Routes.article(article.slug));
  }
}

/// Lead story, then the rest as either a single column or two.
class _FeedScroll extends StatelessWidget {
  const _FeedScroll({
    required this.items,
    required this.columns,
    required this.hasMore,
    required this.onOpen,
  });

  final List<ArticleSummary> items;
  final int columns;
  final bool hasMore;
  final ValueChanged<ArticleSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    final lead = items.first;
    final rest = items.skip(1).toList(growable: false);

    return CustomScrollView(
      slivers: [
        // The lead runs full-bleed across both columns; it is the one item
        // that should not be boxed into a cell.
        SliverToBoxAdapter(
          child: ContentCap(
            child: LeadStoryCard(article: lead, onTap: () => onOpen(lead)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.gutter,
            Spacing.cardInternal,
            Spacing.gutter,
            Spacing.emptyState,
          ),
          sliver: SliverList.separated(
            itemCount: (rest.length / columns).ceil(),
            separatorBuilder: (_, _) =>
                const SizedBox(height: Spacing.cardInternal),
            itemBuilder: (context, rowIndex) {
              final rowItems = rest
                  .skip(rowIndex * columns)
                  .take(columns)
                  .toList(growable: false);

              if (columns == 1) {
                return ArticleCard(
                  article: rowItems.first,
                  onTap: () => onOpen(rowItems.first),
                );
              }

              // Rows of cards rather than a `SliverGrid`. A grid needs a fixed
              // `mainAxisExtent`, and that number can only be estimated from
              // type metrics — an estimate that was already 4px short here and
              // would drift again with any change to the headline or the text
              // scale. `IntrinsicHeight` costs one extra layout pass over two
              // children and removes the guess entirely.
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) const SizedBox(width: Spacing.cardInternal),
                      Expanded(
                        child: i < rowItems.length
                            ? ArticleCard(
                                article: rowItems[i],
                                onTap: () => onOpen(rowItems[i]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (hasMore)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.gutter),
            sliver: SliverToBoxAdapter(child: ArticleCardSkeleton()),
          ),
      ],
    );
  }
}
