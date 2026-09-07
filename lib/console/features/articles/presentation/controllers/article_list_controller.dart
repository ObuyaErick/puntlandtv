import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/admin_api/puntland_admin_api.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../auth/domain/entities/console_user.dart';

part 'article_list_controller.g.dart';

/// Everything the article list is narrowed by.
///
/// One value rather than four providers: the list, the chip counts and the
/// "clear filters" button all need to read the whole set, and a screen whose
/// filters live in separate notifiers is a screen where clearing them is four
/// writes and three rebuilds.
///
/// Null is "all" in every narrowing field. That is what lets them compose —
/// each one either narrows or says nothing.
@immutable
class ArticleQuery {
  const ArticleQuery({
    this.status = ArticleStatusFilter.all,
    this.categorySlug,
    this.locale,
    this.authorId,
  });

  final ArticleStatusFilter status;

  /// A category slug, not its display name: the name is per-locale and
  /// changes, the slug is the identity.
  final String? categorySlug;

  /// Articles that have a version in this language.
  final String? locale;

  final String? authorId;

  /// Whether anything at all is narrowing the list. Drives the enabled state
  /// of the clear button — an always-live "clear filters" on an unfiltered
  /// list is a control that does nothing.
  bool get isNarrowed =>
      status != ArticleStatusFilter.all ||
      categorySlug != null ||
      locale != null ||
      authorId != null;

  @override
  bool operator ==(Object other) =>
      other is ArticleQuery &&
      other.status == status &&
      other.categorySlug == categorySlug &&
      other.locale == locale &&
      other.authorId == authorId;

  @override
  int get hashCode => Object.hash(status, categorySlug, locale, authorId);
}

/// The active filters.
///
/// Each setter builds the whole value rather than going through a `copyWith`:
/// every narrowing field is nullable and null is meaningful, so a copyWith
/// could not tell "leave this alone" from "clear this".
@riverpod
class ArticleFilter extends _$ArticleFilter {
  @override
  ArticleQuery build() => const ArticleQuery();

  void select(ArticleStatusFilter value) => state = ArticleQuery(
    status: value,
    categorySlug: state.categorySlug,
    locale: state.locale,
    authorId: state.authorId,
  );

  void setCategory(String? slug) => state = ArticleQuery(
    status: state.status,
    categorySlug: slug,
    locale: state.locale,
    authorId: state.authorId,
  );

  void setLocale(String? code) => state = ArticleQuery(
    status: state.status,
    categorySlug: state.categorySlug,
    locale: code,
    authorId: state.authorId,
  );

  void setAuthor(String? id) => state = ArticleQuery(
    status: state.status,
    categorySlug: state.categorySlug,
    locale: state.locale,
    authorId: id,
  );

  void clear() => state = const ArticleQuery();
}

/// Staff as bylines, for the author filter.
@riverpod
Future<List<ConsoleUser>> articleAuthors(Ref ref) =>
    ref.watch(adminApiProvider).fetchStaff();

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
  final query = ref.watch(articleFilterProvider);

  return ref
      .watch(adminApiProvider)
      .fetchArticles(
        status: query.status,
        // Their own work, or whichever byline an Editor picked. The scoping is
        // not a filter a Journalist can widen — it replaces the choice rather
        // than defaulting it.
        authorId: scopeToSelf ? user.id : query.authorId,
        categorySlug: query.categorySlug,
        locale: query.locale,
      );
}

/// Counts for the filter chips, independent of the active filter — the chips
/// have to keep showing the other totals while one is selected.
@riverpod
Future<ArticleCounts> articleCounts(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const ArticleCounts.empty();

  final scopeToSelf = !user.can(Capability.publishArticles);
  final query = ref.watch(articleFilterProvider);

  // Everything but the status: the chips have to keep answering "how many
  // drafts are there *in this category*" while a different chip is selected.
  final all = await ref
      .watch(adminApiProvider)
      .fetchArticles(
        authorId: scopeToSelf ? user.id : query.authorId,
        categorySlug: query.categorySlug,
        locale: query.locale,
      );

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
///
/// `keepAlive` for the same reason the media library's actions provider needs
/// it: nothing watches an actions provider, so under auto-dispose the notifier is disposed before the
/// awaited write returns and the invalidation that follows throws on a dead
/// `Ref` — leaving the list showing the state the article was in before the
/// publish it just performed.
@Riverpod(keepAlive: true)
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

  Future<void> delete(String id) async {
    await ref.read(adminApiProvider).deleteArticle(id);
    ref
      ..invalidate(articleListProvider)
      ..invalidate(articleCountsProvider);
    ref.read(articleSelectionProvider.notifier).clear();
  }

  /// Starts a draft and answers with it, so the caller can route to its id.
  Future<AdminArticleDto> create({
    required String categorySlug,
    required String sourceLocale,
  }) async {
    final created = await ref
        .read(adminApiProvider)
        .createArticle(categorySlug: categorySlug, sourceLocale: sourceLocale);
    ref
      ..invalidate(articleListProvider)
      ..invalidate(articleCountsProvider);
    return created;
  }

  /// Re-reads the list after the editor has written to one article.
  ///
  /// The editor owns its own article and does not go through this notifier to
  /// save; it does need the list behind it to stop showing yesterday's status
  /// once it has.
  void refreshList() => ref
    ..invalidate(articleListProvider)
    ..invalidate(articleCountsProvider);
}
