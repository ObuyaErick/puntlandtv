import '../../../../core/domain/page.dart';
import '../entities/article.dart';

/// What the news feature needs, expressed without reference to how it is
/// fetched.
///
/// Note the absence of anything HTTP: no status codes, no headers, no
/// `Response`. Presentation code depends on this interface, so the feed's
/// controller would compile unchanged against a database, a file, or a
/// carrier pigeon.
abstract interface class NewsRepository {
  Future<List<NewsCategory>> categories();

  /// [categorySlug] null (or `'top'`) means the mixed top-news feed.
  /// [cursor] null starts at the head.
  Future<Page<ArticleSummary>> articles({String? categorySlug, String? cursor});

  Future<Article> article(String slug);

  Future<List<ArticleSummary>> related(List<String> slugs);
}
