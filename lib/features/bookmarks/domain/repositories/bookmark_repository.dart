import '../../../news/domain/entities/article.dart';

/// Device-local saved articles.
///
/// There are no accounts in the MVP, so bookmarks never leave the phone —
/// which is also why this repository has no [PuntlandApi] dependency and never
/// fails with a network [Failure].
///
/// Saving stores the article *body* as well as the summary, because the point
/// of the feature is reading with no connection.
abstract interface class BookmarkRepository {
  /// Saved articles, newest save first.
  Future<List<ArticleSummary>> saved();

  /// The cached full article, or null if the body was never stored.
  Future<Article?> cached(String slug);

  Future<void> save(Article article);

  Future<void> remove(String slug);

  /// Slugs of everything saved. Emits on every change so bookmark buttons
  /// across the app stay in sync without re-querying.
  Stream<Set<String>> watchSavedSlugs();

  /// Current value, for a synchronous first paint before the stream emits.
  Set<String> get savedSlugs;
}
