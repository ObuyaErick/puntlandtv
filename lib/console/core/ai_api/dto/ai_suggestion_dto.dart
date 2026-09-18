/// What the assistance layer can do in this deployment.
///
/// Fetched once per console session and consulted before any AI affordance is
/// rendered. The whole feature is optional — a deployment with no model key
/// configured is a supported, normal deployment — so the console's rule is
/// that it shows an assistance button only when the backend has said that
/// button will work. An affordance that always fails is worse than no
/// affordance at all: it teaches the newsroom to distrust the console.
class AiCapabilitiesDto {
  const AiCapabilitiesDto({
    required this.enabled,
    this.provider,
    this.model,
    this.features = const [],
  });

  factory AiCapabilitiesDto.fromJson(Map<String, dynamic> json) =>
      AiCapabilitiesDto(
        enabled: json['enabled'] as bool? ?? false,
        provider: json['provider'] as String?,
        model: json['model'] as String?,
        features: (json['features'] as List<dynamic>? ?? const [])
            .map((f) => f as String)
            .toList(growable: false),
      );

  /// The one every widget checks.
  static const disabled = AiCapabilitiesDto(enabled: false);

  final bool enabled;

  /// Which vendor answered, shown nowhere in the UI. It exists so a support
  /// question about a bad translation can be answered without reading logs.
  final String? provider;
  final String? model;

  /// Feature names the backend will actually serve. A text-only model omits
  /// `suggestAltText`, so the media panel's button disappears rather than
  /// failing when pressed.
  final List<String> features;

  bool has(AiFeature feature) => enabled && features.contains(feature.wireName);
}

/// The assistance features the console knows how to ask for.
enum AiFeature {
  translateArticle('translateArticle'),
  suggestExcerpt('suggestExcerpt'),
  suggestHeadlines('suggestHeadlines'),
  suggestAltText('suggestAltText'),
  suggestSynopsis('suggestSynopsis');

  const AiFeature(this.wireName);

  final String wireName;
}

/// A proposed translation of one article into one language.
///
/// Every field is a *suggestion*, not a value: nothing here has been written
/// anywhere, and nothing will be until an editor reviews it and accepts the
/// parts they want. That is the whole shape of this feature — the model
/// proposes, a person disposes — and it is why this type is not an
/// `ArticleTranslationDto`. Making it one would invite somebody to save it.
class ArticleTranslationSuggestion {
  const ArticleTranslationSuggestion({
    required this.articleId,
    required this.from,
    required this.to,
    required this.sourceUpdatedAt,
    required this.title,
    this.excerpt,
    this.bodyHtml,
    this.caption,
    this.provider,
    this.model,
    this.cached = false,
  });

  factory ArticleTranslationSuggestion.fromJson(Map<String, dynamic> json) =>
      ArticleTranslationSuggestion(
        articleId: json['articleId'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        sourceUpdatedAt: DateTime.parse(json['sourceUpdatedAt'] as String)
            .toLocal(),
        title: json['title'] as String? ?? '',
        excerpt: json['excerpt'] as String?,
        bodyHtml: json['bodyHtml'] as String?,
        caption: json['caption'] as String?,
        provider: json['provider'] as String?,
        model: json['model'] as String?,
        cached: json['cached'] as bool? ?? false,
      );

  final String articleId;

  /// The language translated from, and the one translated into.
  final String from;
  final String to;

  /// **The clock this was computed against.**
  ///
  /// The console flushes the source language before asking, so this is the
  /// `updatedAt` of the source translation the model actually read. Compared
  /// against the article's current source translation at the moment of apply:
  /// if it has moved, somebody rewrote the Somali while this panel was open,
  /// and accepting would overwrite the English with a translation of text that
  /// no longer exists. The review panel says so rather than letting it happen.
  final DateTime sourceUpdatedAt;

  final String title;
  final String? excerpt;
  final String? bodyHtml;
  final String? caption;

  final String? provider;
  final String? model;

  /// True when the backend answered from its cache — an unchanged article
  /// somebody already asked about. Surfaced nowhere; useful in a bug report.
  final bool cached;

  /// Whether there is anything here worth showing a reviewer.
  bool get isEmpty =>
      title.trim().isEmpty &&
      (excerpt ?? '').trim().isEmpty &&
      (bodyHtml ?? '').trim().isEmpty &&
      (caption ?? '').trim().isEmpty;

  /// Whether the source has moved since this was drafted.
  bool isStaleAgainst(DateTime? currentSourceUpdatedAt) =>
      currentSourceUpdatedAt != null &&
      currentSourceUpdatedAt.isAfter(sourceUpdatedAt);
}

/// A proposed standfirst for one language of one article.
class ExcerptSuggestion {
  const ExcerptSuggestion({
    required this.articleId,
    required this.locale,
    required this.excerpt,
  });

  factory ExcerptSuggestion.fromJson(Map<String, dynamic> json) =>
      ExcerptSuggestion(
        articleId: json['articleId'] as String,
        locale: json['locale'] as String,
        excerpt: json['excerpt'] as String? ?? '',
      );

  final String articleId;
  final String locale;
  final String excerpt;
}

/// Alternative headlines, best first.
class HeadlineSuggestion {
  const HeadlineSuggestion({
    required this.articleId,
    required this.locale,
    required this.headlines,
  });

  factory HeadlineSuggestion.fromJson(Map<String, dynamic> json) =>
      HeadlineSuggestion(
        articleId: json['articleId'] as String,
        locale: json['locale'] as String,
        headlines: (json['headlines'] as List<dynamic>? ?? const [])
            .map((h) => h as String)
            .toList(growable: false),
      );

  final String articleId;
  final String locale;
  final List<String> headlines;
}

/// Proposed text keyed by language code.
///
/// One type for alt text and for programme synopses because they are the same
/// shape — a short string per locale, reviewed in the field it will land in.
/// The two differ only in which panel asks.
class LocalisedSuggestion {
  const LocalisedSuggestion({required this.subjectId, required this.byLocale});

  factory LocalisedSuggestion.fromJson(
    Map<String, dynamic> json, {
    required String idKey,
    required String valueKey,
  }) => LocalisedSuggestion(
    subjectId: json[idKey] as String,
    byLocale: (json[valueKey] as Map<dynamic, dynamic>? ?? const {}).map(
      (key, value) => MapEntry(key as String, value as String),
    ),
  );

  final String subjectId;
  final Map<String, String> byLocale;

  String? forLocale(String locale) {
    final value = byLocale[locale]?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }
}

/// Refusal reasons the assistance endpoints raise, so the UI and the boundary
/// agree on what went wrong rather than each inventing a message.
///
/// Copied verbatim from `FailureCode` in the API's `src/common/failure.ts`.
/// Every one of these leaves the newsroom able to do the work by hand — none of
/// them may ever block a save — so the console's copy for each is an
/// explanation, never an error the operator has to resolve.
abstract final class AiFailureCode {
  /// No model provider is configured. The console hides its affordances, so an
  /// operator should never see this one.
  static const disabled = 'AI_DISABLED';

  /// Configured, but it did not answer.
  static const unavailable = 'AI_UNAVAILABLE';

  /// Our per-user ceiling, or the provider's.
  static const rateLimited = 'AI_RATE_LIMITED';

  /// Longer than the configured input ceiling.
  static const inputTooLarge = 'AI_INPUT_TOO_LARGE';

  /// The provider's safety filter declined.
  static const unsafeContent = 'AI_UNSAFE_CONTENT';

  /// The reply did not match the requested schema.
  static const malformedOutput = 'AI_MALFORMED_OUTPUT';

  /// A language outside the two this product publishes in.
  static const unsupportedLocale = 'AI_UNSUPPORTED_LOCALE';

  /// Asked to work from a language that has no text in it yet.
  static const nothingToTranslate = 'AI_NOTHING_TO_TRANSLATE';

  /// Asked to describe something that is not an image.
  static const notAnImage = 'AI_NOT_AN_IMAGE';
}
