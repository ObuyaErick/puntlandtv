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
    this.sourceLocale = 'so',
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
      sourceLocale: json['source_locale'] as String? ?? 'so',
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

  /// The language the newsroom writes in first. Every other translation is
  /// measured against it — most stories start in Somali.
  final String sourceLocale;

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

  /// The version to display for [locale].
  ///
  /// Falls back to the source language, then to anything present. Nothing in
  /// the console picks a language by hand: the active locale drives every
  /// label and every piece of localised content, so one switch re-hydrates the
  /// whole UI rather than leaving a screen half-translated.
  ArticleTranslationDto? translationFor(String locale) =>
      translations[locale] ??
      translations[sourceLocale] ??
      (translations.isEmpty ? null : translations.values.first);

  /// Required locales this article has no version in.
  List<String> missingLocales(List<String> required) => required
      .where((locale) => !translations.containsKey(locale))
      .toList(growable: false);

  /// Locales whose text is older than the source language's.
  ///
  /// Publishing does **not** hide a stale translation — the app keeps showing
  /// it, flagged. Hiding it would leave a reader with nothing, which is worse
  /// than slightly out-of-date copy. An editor clears the flag by
  /// re-confirming the translation.
  List<String> get staleLocales {
    final source = translations[sourceLocale];
    if (source == null) return const [];
    return translations.entries
        .where(
          (e) =>
              e.key != sourceLocale &&
              e.value.updatedAt.isBefore(source.updatedAt),
        )
        .map((e) => e.key)
        .toList(growable: false);
  }

  bool get hasStaleTranslation => staleLocales.isNotEmpty;

  /// True when this exists only in the source language.
  bool get isUntranslated => translations.length < 2;

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
    required this.updatedAt,
    this.excerpt,
    this.bodyHtml,
    this.updatedBy,
    this.caption,
  });

  factory ArticleTranslationDto.fromJson(Map<String, dynamic> json) =>
      ArticleTranslationDto(
        title: json['title'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        excerpt: json['excerpt'] as String?,
        bodyHtml: json['body_html'] as String?,
        updatedBy: json['updated_by'] as String?,
        caption: json['caption'] as String?,
      );

  final String title;

  /// When this language was last edited. The difference between two
  /// translations' timestamps is what makes one "behind" the other.
  final DateTime updatedAt;

  final String? excerpt;
  final String? bodyHtml;
  final String? updatedBy;

  /// Hero image caption, which is translated like everything else.
  final String? caption;

  int get wordCount => (bodyHtml ?? '')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;

  /// Roughly 200 words a minute, floor of one.
  int get readingMinutes => (wordCount / 200).ceil().clamp(1, 99);

  ArticleTranslationDto copyWith({
    String? title,
    String? excerpt,
    String? bodyHtml,
    String? caption,
    DateTime? updatedAt,
    String? updatedBy,
  }) => ArticleTranslationDto(
    title: title ?? this.title,
    updatedAt: updatedAt ?? this.updatedAt,
    excerpt: excerpt ?? this.excerpt,
    bodyHtml: bodyHtml ?? this.bodyHtml,
    updatedBy: updatedBy ?? this.updatedBy,
    caption: caption ?? this.caption,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'updated_at': updatedAt.toIso8601String(),
    'excerpt': excerpt,
    'body_html': bodyHtml,
    'updated_by': updatedBy,
    'caption': caption,
  };
}
