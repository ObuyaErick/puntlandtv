/// A news category, identified by its stable [slug].
///
/// [name] is localised by the backend and changes with the request locale, so
/// nothing may key off it.
class NewsCategory {
  const NewsCategory({
    required this.slug,
    required this.name,
    this.isDefault = false,
  });

  final String slug;
  final String name;
  final bool isDefault;

  @override
  bool operator ==(Object other) =>
      other is NewsCategory && other.slug == slug && other.name == name;

  @override
  int get hashCode => Object.hash(slug, name);
}

/// Feed-sized article. Carries no body — that is [Article].
class ArticleSummary {
  const ArticleSummary({
    required this.slug,
    required this.title,
    required this.categorySlug,
    required this.categoryName,
    required this.publishedAt,
    required this.contentLanguage,
    this.excerpt,
    this.imageUrl,
    this.readingMinutes,
    this.isBreaking = false,
  });

  final String slug;
  final String title;
  final String categorySlug;
  final String categoryName;
  final DateTime publishedAt;

  /// The language the newsroom wrote this in — independent of the UI language.
  /// Used to wrap the text in the right `Locale` so fonts and screen-reader
  /// pronunciation follow the content, not the chrome.
  final String contentLanguage;

  final String? excerpt;
  final String? imageUrl;
  final int? readingMinutes;
  final bool isBreaking;

  @override
  bool operator ==(Object other) =>
      other is ArticleSummary && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;
}

/// A full article, including its sanitised HTML body.
class Article {
  const Article({
    required this.summary,
    required this.bodyHtml,
    this.author,
    this.imageCaption,
    this.relatedSlugs = const [],
  });

  final ArticleSummary summary;

  /// Sanitised upstream. Rendered as-is.
  final String bodyHtml;

  final String? author;
  final String? imageCaption;
  final List<String> relatedSlugs;

  String get slug => summary.slug;
  String get title => summary.title;
}
