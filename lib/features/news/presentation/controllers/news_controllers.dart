import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/page.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/article.dart';

part 'news_controllers.g.dart';

/// The category tabs. Cached for the session — categories change on the scale
/// of months, and re-fetching them on every tab switch wastes a request on a
/// metered connection.
@Riverpod(keepAlive: true)
Future<List<NewsCategory>> categories(Ref ref) {
  return ref.watch(newsRepositoryProvider).categories();
}

/// Which tab is selected. Held above the feed so switching tabs does not
/// rebuild the controller for the tab you left.
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String build() => 'top';

  void select(String slug) => state = slug;
}

/// A feed's loaded pages, plus the state of any in-flight *additional* page.
///
/// [loadMoreError] is separate from the `AsyncValue`'s own error on purpose: a
/// failure while appending page three must not blank out pages one and two.
/// The distinction is the difference between "couldn't load more" and "lost
/// your place", and on an intermittent connection the second is unforgivable.
@immutable
class FeedState {
  const FeedState({
    required this.page,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final Page<ArticleSummary> page;
  final bool loadingMore;
  final Failure? loadMoreError;

  List<ArticleSummary> get items => page.items;
  bool get hasMore => page.hasMore;

  FeedState copyWith({
    Page<ArticleSummary>? page,
    bool? loadingMore,
    Failure? loadMoreError,
    bool clearError = false,
  }) => FeedState(
    page: page ?? this.page,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: clearError ? null : (loadMoreError ?? this.loadMoreError),
  );
}

/// One category's feed, with cursor pagination.
///
/// Note what this class does *not* contain: no HTTP, no JSON, no status codes.
/// It asks a `NewsRepository` for a [Page] and holds the result — it would work
/// unchanged against a local database.
@riverpod
class Feed extends _$Feed {
  @override
  Future<FeedState> build(String categorySlug) async {
    final page = await ref
        .watch(newsRepositoryProvider)
        .articles(categorySlug: _slugOrNull);
    return FeedState(page: page);
  }

  String? get _slugOrNull => categorySlug == 'top' ? null : categorySlug;

  /// Pull-to-refresh. Discards the cursor and starts from the head.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(newsRepositoryProvider)
          .articles(categorySlug: _slugOrNull);
      return FeedState(page: page);
    });
  }

  /// Appends the next page.
  ///
  /// Safe to call repeatedly from a scroll listener: re-entrant calls while a
  /// page is in flight are dropped, which is the bug that otherwise produces
  /// duplicated rows during a fast scroll.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncValue.data(
      current.copyWith(loadingMore: true, clearError: true),
    );

    try {
      final next = await ref
          .read(newsRepositoryProvider)
          .articles(categorySlug: _slugOrNull, cursor: current.page.nextCursor);
      state = AsyncValue.data(FeedState(page: current.page.append(next)));
    } on Failure catch (failure) {
      state = AsyncValue.data(
        current.copyWith(loadingMore: false, loadMoreError: failure),
      );
    }
  }
}

/// A single article, falling back to the bookmarked copy when the network
/// fails — which is what makes "save for offline" work at the point of use
/// rather than only on the saved list.
@riverpod
Future<Article> articleDetail(Ref ref, String slug) async {
  final bookmarks = ref.watch(bookmarkRepositoryProvider);
  try {
    return await ref.watch(newsRepositoryProvider).article(slug);
  } on Failure {
    final cached = await bookmarks.cached(slug);
    if (cached != null) return cached;
    rethrow;
  }
}

@riverpod
Future<List<ArticleSummary>> relatedArticles(Ref ref, List<String> slugs) {
  return ref.watch(newsRepositoryProvider).related(slugs);
}
