import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bar.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/article.dart';
import '../controllers/news_controllers.dart';
import '../widgets/article_card.dart';
import '../widgets/category_tabs.dart';

class NewsFeedPage extends ConsumerWidget {
  const NewsFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(categoriesProvider);
    final offline = ref.watch(isOfflineProvider);

    return Scaffold(
      appBar: PltvAppBar(onLiveTap: () => context.go(Routes.live)),
      body: Column(
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
          Expanded(child: _FeedBody(categorySlug: selected)),
        ],
      ),
    );
  }
}

class _FeedBody extends ConsumerWidget {
  const _FeedBody({required this.categorySlug});

  final String categorySlug;

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
      data: (feed) {
        if (feed.items.isEmpty) {
          return EmptyView(
            title: l10n.emptyCategoryTitle,
            body: l10n.emptyCategoryBody,
            icon: Icons.article_outlined,
          );
        }

        final lead = feed.items.first;
        final rest = feed.items.skip(1).toList(growable: false);

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: NotificationListener<ScrollNotification>(
            // Prefetch a page before the user reaches the bottom, so on a slow
            // connection the next rows are usually there by the time they
            // arrive rather than after a visible stall.
            onNotification: (notification) {
              final metrics = notification.metrics;
              if (metrics.pixels > metrics.maxScrollExtent - 600) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: Spacing.emptyState),
              itemCount: rest.length + (feed.hasMore ? 2 : 1),
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 0 : Spacing.cardInternal),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return LeadStoryCard(
                    article: lead,
                    onTap: () => _open(context, lead),
                  );
                }
                if (index - 1 >= rest.length) {
                  return const Padding(
                    padding: EdgeInsets.all(Spacing.gutter),
                    child: ArticleCardSkeleton(),
                  );
                }
                final article = rest[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.gutter,
                  ),
                  child: ArticleCard(
                    article: article,
                    onTap: () => _open(context, article),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _open(BuildContext context, ArticleSummary article) =>
      context.push(Routes.article(article.slug));
}
