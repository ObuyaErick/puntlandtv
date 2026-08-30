import '../../../../core/api/dto/article_dto.dart';
import '../../../../core/api/dto/category_dto.dart';
import '../../../../core/api/dto/paged_dto.dart';
import '../../../../core/domain/page.dart';
import '../../domain/entities/article.dart';

/// DTO → entity. One direction only: nothing in this app uploads articles.
///
/// This file is the blast radius of a backend field rename. If the API starts
/// sending `headline` instead of `title`, the change stops here — no screen,
/// controller or test above it moves.
extension CategoryDtoX on CategoryDto {
  NewsCategory toEntity() =>
      NewsCategory(slug: slug, name: name, isDefault: isDefault);
}

extension ArticleSummaryDtoX on ArticleSummaryDto {
  ArticleSummary toEntity() => ArticleSummary(
    slug: slug,
    title: title,
    categorySlug: categorySlug,
    categoryName: categoryName,
    publishedAt: publishedAt,
    contentLanguage: contentLocale,
    excerpt: excerpt,
    imageUrl: imageUrl,
    readingMinutes: readingMinutes,
    isBreaking: isBreaking,
  );
}

extension ArticleDetailDtoX on ArticleDetailDto {
  Article toEntity() => Article(
    summary: ArticleSummary(
      slug: slug,
      title: title,
      categorySlug: categorySlug,
      categoryName: categoryName,
      publishedAt: publishedAt,
      contentLanguage: contentLocale,
      excerpt: excerpt,
      imageUrl: imageUrl,
      readingMinutes: readingMinutes,
    ),
    bodyHtml: bodyHtml,
    author: author,
    imageCaption: imageCaption,
    relatedSlugs: relatedSlugs,
  );
}

extension PagedArticleDtoX on PagedDto<ArticleSummaryDto> {
  Page<ArticleSummary> toEntity() => Page<ArticleSummary>(
    items: data.map((e) => e.toEntity()).toList(growable: false),
    nextCursor: nextCursor,
  );
}
