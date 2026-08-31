/// The lifecycle an article moves through in the newsroom.
///
/// The reader app never sees anything but [published], which is why this lives
/// in the console's API surface rather than the shared one.
enum ArticleStatus {
  draft,
  inReview,
  scheduled,
  published,
  failed;

  static ArticleStatus fromJson(String value) => ArticleStatus.values
      .firstWhere((s) => s.name == value, orElse: () => ArticleStatus.draft);

  String toJson() => name;
}

/// An article as the newsroom sees it: every locale, every state, plus the
/// editorial metadata the reader app has no use for.
class AdminArticleDto {
  const AdminArticleDto({
    required this.id,
    required this.status,
    required this.translations,
    required this.categorySlug,
    required this.authorId,
    required this.authorName,
    required this.updatedAt,
    this.scheduledFor,
    this.publishedAt,
    this.isBreaking = false,
    this.imageUrl,
    this.imageAlt,
  });

  factory AdminArticleDto.fromJson(Map<String, dynamic> json) {
    return AdminArticleDto(
      id: json['id'] as String,
      status: ArticleStatus.fromJson(json['status'] as String),
      translations: {
        for (final entry
            in (json['translations'] as Map<String, dynamic>).entries)
          entry.key: ArticleTranslationDto.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
      categorySlug: json['category_slug'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      scheduledFor: json['scheduled_for'] == null
          ? null
          : DateTime.parse(json['scheduled_for'] as String),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      isBreaking: json['is_breaking'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      imageAlt: json['image_alt'] as String?,
    );
  }

  final String id;
  final ArticleStatus status;

  /// Keyed by language code. An article may exist in Somali only, English
  /// only, or both — the editor's job is to make the pairing visible rather
  /// than let the two versions drift apart unnoticed.
  final Map<String, ArticleTranslationDto> translations;

  final String categorySlug;
  final String authorId;
  final String authorName;
  final DateTime updatedAt;
  final DateTime? scheduledFor;
  final DateTime? publishedAt;
  final bool isBreaking;
  final String? imageUrl;

  /// Required before an image can be attached; the media library enforces it.
  final String? imageAlt;

  /// The locales this article exists in, ordered so Somali reads first —
  /// it is the majority publishing language.
  List<String> get locales {
    final keys = translations.keys.toList()
      ..sort((a, b) => a == 'so' ? -1 : (b == 'so' ? 1 : a.compareTo(b)));
    return keys;
  }

  /// "so + en" or "so only", as the canvas labels it.
  String localeSummary(String onlySuffix) =>
      locales.length > 1 ? locales.join(' + ') : '${locales.first} $onlySuffix';

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.toJson(),
    'translations': {
      for (final entry in translations.entries) entry.key: entry.value.toJson(),
    },
    'category_slug': categorySlug,
    'author_id': authorId,
    'author_name': authorName,
    'updated_at': updatedAt.toIso8601String(),
    'scheduled_for': scheduledFor?.toIso8601String(),
    'published_at': publishedAt?.toIso8601String(),
    'is_breaking': isBreaking,
    'image_url': imageUrl,
    'image_alt': imageAlt,
  };

  AdminArticleDto copyWith({
    ArticleStatus? status,
    Map<String, ArticleTranslationDto>? translations,
    DateTime? scheduledFor,
    DateTime? publishedAt,
    bool? isBreaking,
  }) => AdminArticleDto(
    id: id,
    status: status ?? this.status,
    translations: translations ?? this.translations,
    categorySlug: categorySlug,
    authorId: authorId,
    authorName: authorName,
    updatedAt: DateTime.now(),
    scheduledFor: scheduledFor ?? this.scheduledFor,
    publishedAt: publishedAt ?? this.publishedAt,
    isBreaking: isBreaking ?? this.isBreaking,
    imageUrl: imageUrl,
    imageAlt: imageAlt,
  );
}

/// One language's version of an article.
class ArticleTranslationDto {
  const ArticleTranslationDto({
    required this.title,
    this.excerpt,
    this.bodyHtml,
  });

  factory ArticleTranslationDto.fromJson(Map<String, dynamic> json) =>
      ArticleTranslationDto(
        title: json['title'] as String,
        excerpt: json['excerpt'] as String?,
        bodyHtml: json['body_html'] as String?,
      );

  final String title;
  final String? excerpt;
  final String? bodyHtml;

  Map<String, dynamic> toJson() => {
    'title': title,
    'excerpt': excerpt,
    'body_html': bodyHtml,
  };
}
