import '../../../core/error/failure.dart';
import '../admin_api/dto/admin_article_dto.dart';
import '../admin_api/puntland_admin_api.dart';
import 'dto/ai_suggestion_dto.dart';
import 'puntland_ai_api.dart';

/// [PuntlandAiApi] with no model behind it.
///
/// The console has to be fully usable with no backend at all — that is the
/// standing rule `FixtureAdminApi` exists for — and "fully usable" has to
/// include the review panel, the pending state, the per-field accept and the
/// apply. All of that is real UI with real bugs in it, and none of it should
/// need an API key to exercise.
///
/// What it deliberately does **not** do is pretend to translate. A fixture that
/// returned convincing Somali would be a fixture someone eventually shipped a
/// screenshot of, and a developer reading the review panel should never be left
/// wondering whether the text in front of them came from a model. So the output
/// is openly synthetic — marked, deterministic, and structurally faithful:
/// every paragraph, heading, list item, link and image of the source survives,
/// because structure is the thing the review panel and the apply path actually
/// have to get right.
class FixtureAiApi implements PuntlandAiApi {
  FixtureAiApi({
    required this.admin,
    this.latency = const Duration(milliseconds: 900),
    this.enabled = true,
  });

  /// Read through rather than duplicated: a suggestion has to be *about* an
  /// article that exists, and seeding a second copy of the newsroom here would
  /// let the two drift until the review panel showed a headline the editor
  /// behind it had never seen.
  final PuntlandAdminApi admin;

  /// Long by default, and on purpose: a model call is slow, and a pending state
  /// that never lasts long enough to see is a pending state nobody tests. Set
  /// to zero in widget tests.
  final Duration latency;

  /// Lets a test drive the "no assistance configured" path without swapping in
  /// a different implementation.
  final bool enabled;

  Future<T> _respond<T>(T Function() build) async {
    await Future<void>.delayed(latency);
    return build();
  }

  @override
  Future<AiCapabilitiesDto> fetchCapabilities() async => enabled
      ? const AiCapabilitiesDto(
          enabled: true,
          provider: 'fixture',
          model: 'fixture-1',
          features: [
            'translateArticle',
            'suggestExcerpt',
            'suggestHeadlines',
            'suggestAltText',
            'suggestSynopsis',
          ],
        )
      : AiCapabilitiesDto.disabled;

  @override
  Future<ArticleTranslationSuggestion> translateArticle({
    required String articleId,
    required String from,
    required String to,
    List<String>? fields,
  }) async {
    final article = await admin.fetchArticle(articleId);
    final source = article.translations[from];
    if (source == null || source.title.trim().isEmpty) {
      throw const Failure(
        kind: FailureKind.server,
        code: AiFailureCode.nothingToTranslate,
      );
    }

    final wanted = fields ?? const ['title', 'excerpt', 'bodyHtml', 'caption'];
    bool has(String field) => wanted.contains(field);

    return _respond(
      () => ArticleTranslationSuggestion(
        articleId: articleId,
        from: from,
        to: to,
        sourceUpdatedAt: source.updatedAt,
        title: has('title') ? _mark(source.title, to) : '',
        excerpt: has('excerpt') ? _markOrNull(source.excerpt, to) : null,
        bodyHtml: has('bodyHtml') ? _markHtml(source.bodyHtml, to) : null,
        caption: has('caption') ? _markOrNull(source.caption, to) : null,
        provider: 'fixture',
        model: 'fixture-1',
      ),
    );
  }

  @override
  Future<ExcerptSuggestion> suggestExcerpt({
    required String articleId,
    required String locale,
  }) async {
    final translation = await _translationOf(articleId, locale);
    return _respond(
      () => ExcerptSuggestion(
        articleId: articleId,
        locale: locale,
        excerpt: '[${locale.toUpperCase()}] ${_firstSentence(translation)}',
      ),
    );
  }

  @override
  Future<HeadlineSuggestion> suggestHeadlines({
    required String articleId,
    required String locale,
    int count = 3,
  }) async {
    final translation = await _translationOf(articleId, locale);
    final base = translation.title.trim();

    // Three shapes rather than three rewordings, so the chooser UI is exercised
    // with options an editor could actually pick between.
    return _respond(
      () => HeadlineSuggestion(
        articleId: articleId,
        locale: locale,
        headlines: <String>[
          base,
          '$base — faahfaahin',
          base.length > 60 ? '${base.substring(0, 57)}...' : '$base (2)',
        ].take(count).toList(growable: false),
      ),
    );
  }

  @override
  Future<LocalisedSuggestion> suggestAltText({
    required String assetId,
    List<String>? locales,
  }) => _respond(
    () => LocalisedSuggestion(
      subjectId: assetId,
      byLocale: {
        for (final locale in locales ?? const ['so', 'en'])
          locale: '[${locale.toUpperCase()}] Sawir tijaabo ah — $assetId',
      },
    ),
  );

  @override
  Future<LocalisedSuggestion> suggestSynopsis({
    required String programId,
    List<String>? locales,
  }) => _respond(
    () => LocalisedSuggestion(
      subjectId: programId,
      byLocale: {
        for (final locale in locales ?? const ['so', 'en'])
          locale:
              '[${locale.toUpperCase()}] Barnaamij tijaabo ah oo lagu tijaabinayo '
              'muuqaalka console-ka. Ma aha qoraal la daabici karo.',
      },
    ),
  );

  Future<ArticleTranslationDto> _translationOf(
    String articleId,
    String locale,
  ) async {
    final article = await admin.fetchArticle(articleId);
    final translation = article.translations[locale];
    if (translation == null || translation.title.trim().isEmpty) {
      throw const Failure(
        kind: FailureKind.server,
        code: AiFailureCode.nothingToTranslate,
      );
    }
    return translation;
  }

  static String _mark(String value, String locale) =>
      '[${locale.toUpperCase()}] $value';

  static String? _markOrNull(String? value, String locale) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : _mark(trimmed, locale);
  }

  /// Marks the text of an HTML body while leaving every tag exactly where it
  /// was — which is the property the apply path has to survive, and the one a
  /// naive fixture that returned a flat string would never exercise.
  static String? _markHtml(String? html, String locale) {
    final trimmed = html?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    var first = true;
    return trimmed.replaceAllMapped(RegExp(r'>([^<]+)<'), (match) {
      final text = match.group(1)!;
      if (text.trim().isEmpty) return match.group(0)!;
      if (first) {
        first = false;
        return '>[${locale.toUpperCase()}] $text<';
      }
      return match.group(0)!;
    });
  }

  static String _firstSentence(ArticleTranslationDto translation) {
    final source = (translation.excerpt ?? translation.title).trim();
    final stop = source.indexOf('.');
    return stop > 0 ? source.substring(0, stop + 1) : source;
  }
}
