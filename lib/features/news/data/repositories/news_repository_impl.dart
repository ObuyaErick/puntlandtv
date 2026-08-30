import '../../../../core/api/puntland_api.dart';
import '../../../../core/domain/page.dart';
import '../../domain/entities/article.dart';
import '../../domain/repositories/news_repository.dart';
import '../mappers/news_mappers.dart';

class NewsRepositoryImpl implements NewsRepository {
  const NewsRepositoryImpl(this._api);

  final PuntlandApi _api;

  @override
  Future<List<NewsCategory>> categories() async {
    final dtos = await _api.fetchCategories();
    return dtos.map((e) => e.toEntity()).toList(growable: false);
  }

  @override
  Future<Page<ArticleSummary>> articles({
    String? categorySlug,
    String? cursor,
  }) async {
    final page = await _api.fetchArticles(
      categorySlug: categorySlug,
      cursor: cursor,
    );
    return page.toEntity();
  }

  @override
  Future<Article> article(String slug) async {
    final dto = await _api.fetchArticle(slug);
    return dto.toEntity();
  }

  @override
  Future<List<ArticleSummary>> related(List<String> slugs) async {
    final dtos = await _api.fetchArticlesBySlugs(slugs);
    return dtos.map((e) => e.toEntity()).toList(growable: false);
  }
}
