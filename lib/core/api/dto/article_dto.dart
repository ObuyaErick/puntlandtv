import 'package:json_annotation/json_annotation.dart';

part 'article_dto.g.dart';

/// Feed-sized article payload. Deliberately smaller than [ArticleDetailDto]:
/// the body is the expensive field and the feed never shows it.
@JsonSerializable()
class ArticleSummaryDto {
  const ArticleSummaryDto({
    required this.slug,
    required this.title,
    required this.categorySlug,
    required this.categoryName,
    required this.publishedAt,
    required this.contentLocale,
    this.excerpt,
    this.imageUrl,
    this.readingMinutes,
    this.isBreaking = false,
  });

  factory ArticleSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ArticleSummaryDtoFromJson(json);

  final String slug;
  final String title;

  @JsonKey(name: 'category_slug')
  final String categorySlug;

  @JsonKey(name: 'category_name')
  final String categoryName;

  @JsonKey(name: 'published_at')
  final DateTime publishedAt;

  /// The language this article was written in, which is independent of the
  /// user's UI language. Drives font selection and screen-reader pronunciation.
  @JsonKey(name: 'content_locale')
  final String contentLocale;

  final String? excerpt;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'reading_minutes')
  final int? readingMinutes;

  @JsonKey(name: 'is_breaking')
  final bool isBreaking;

  Map<String, dynamic> toJson() => _$ArticleSummaryDtoToJson(this);
}

@JsonSerializable()
class ArticleDetailDto {
  const ArticleDetailDto({
    required this.slug,
    required this.title,
    required this.categorySlug,
    required this.categoryName,
    required this.publishedAt,
    required this.contentLocale,
    required this.bodyHtml,
    this.excerpt,
    this.imageUrl,
    this.imageCaption,
    this.author,
    this.readingMinutes,
    this.relatedSlugs = const [],
  });

  factory ArticleDetailDto.fromJson(Map<String, dynamic> json) =>
      _$ArticleDetailDtoFromJson(json);

  final String slug;
  final String title;

  @JsonKey(name: 'category_slug')
  final String categorySlug;

  @JsonKey(name: 'category_name')
  final String categoryName;

  @JsonKey(name: 'published_at')
  final DateTime publishedAt;

  @JsonKey(name: 'content_locale')
  final String contentLocale;

  /// Sanitised HTML. Sanitisation is the backend's job — the app renders what
  /// it is given and does not police it.
  @JsonKey(name: 'body_html')
  final String bodyHtml;

  final String? excerpt;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'image_caption')
  final String? imageCaption;

  final String? author;

  @JsonKey(name: 'reading_minutes')
  final int? readingMinutes;

  @JsonKey(name: 'related_slugs')
  final List<String> relatedSlugs;

  Map<String, dynamic> toJson() => _$ArticleDetailDtoToJson(this);
}
