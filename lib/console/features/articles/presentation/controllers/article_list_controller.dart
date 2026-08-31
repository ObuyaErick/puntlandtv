import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/admin_api/puntland_admin_api.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../auth/domain/entities/console_user.dart';

part 'article_list_controller.g.dart';

/// Which filter chip is active.
@riverpod
class ArticleFilter extends _$ArticleFilter {
  @override
  ArticleStatusFilter build() => ArticleStatusFilter.all;

  void select(ArticleStatusFilter value) => state = value;
}

/// Rows currently ticked, for the bulk action bar.
@riverpod
class ArticleSelection extends _$ArticleSelection {
  @override
  Set<String> build() => const {};

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void clear() => state = const {};

  void selectAll(Iterable<String> ids) => state = ids.toSet();
}

/// The article list, scoped to what the signed-in user may see.
///
/// A Journalist cannot publish, so showing them everyone's queue would be
/// noise they cannot act on — the list is scoped to their own work at the
/// source rather than filtered in the widget.
@riverpod
Future<List<AdminArticleDto>> articleList(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];

  final scopeToSelf = !user.can(Capability.publishArticles);

  return ref
      .watch(adminApiProvider)
      .fetchArticles(
        status: ref.watch(articleFilterProvider),
        authorId: scopeToSelf ? user.id : null,
      );
}

/// Counts for the filter chips, independent of the active filter — the chips
/// have to keep showing the other totals while one is selected.
@riverpod
Future<ArticleCounts> articleCounts(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const ArticleCounts.empty();

  final scopeToSelf = !user.can(Capability.publishArticles);
  final all = await ref
      .watch(adminApiProvider)
      .fetchArticles(authorId: scopeToSelf ? user.id : null);

  int count(ArticleStatus status) =>
      all.where((a) => a.status == status).length;

  return ArticleCounts(
    all: all.length,
    draft: count(ArticleStatus.draft),
    inReview: count(ArticleStatus.inReview),
    scheduled: count(ArticleStatus.scheduled),
    published: count(ArticleStatus.published),
  );
}

@immutable
class ArticleCounts {
  const ArticleCounts({
    required this.all,
    required this.draft,
    required this.inReview,
    required this.scheduled,
    required this.published,
  });

  const ArticleCounts.empty()
    : all = 0,
      draft = 0,
      inReview = 0,
      scheduled = 0,
      published = 0;

  final int all;
  final int draft;
  final int inReview;
  final int scheduled;
  final int published;

  int forFilter(ArticleStatusFilter filter) => switch (filter) {
    ArticleStatusFilter.all => all,
    ArticleStatusFilter.draft => draft,
    ArticleStatusFilter.inReview => inReview,
    ArticleStatusFilter.scheduled => scheduled,
    ArticleStatusFilter.published => published,
  };
}

/// Bulk and single-row actions.
@riverpod
class ArticleActions extends _$ArticleActions {
  @override
  void build() {}

  Future<void> setStatus(Iterable<String> ids, ArticleStatus status) async {
    final api = ref.read(adminApiProvider);
    for (final id in ids) {
      await api.setArticleStatus(id: id, status: status);
    }
    ref
      ..invalidate(articleListProvider)
      ..invalidate(articleCountsProvider);
    ref.read(articleSelectionProvider.notifier).clear();
  }

  Future<void> save(AdminArticleDto article) async {
    await ref.read(adminApiProvider).saveArticle(article);
    ref
      ..invalidate(articleListProvider)
      ..invalidate(articleCountsProvider);
  }
}
