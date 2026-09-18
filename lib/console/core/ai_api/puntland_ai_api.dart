import 'dto/ai_suggestion_dto.dart';

/// The console's assistance surface.
///
/// **Deliberately not part of [PuntlandAdminApi].** Three reasons, in order of
/// weight:
///
/// 1. This one can be *absent*. A deployment with no model key configured is a
///    normal deployment, and an interface that may not exist is cleaner as its
///    own type than as six methods on the main one that always throw.
/// 2. It needs a different HTTP client. A whole-article translation routinely
///    runs past the console's 20-second receive timeout, and widening that
///    shared timeout would slow the failure of every ordinary request to match
///    the slowest thing the console can ask for.
/// 3. Nothing here writes. Every method returns a *suggestion* that a person
///    then reviews; an accepted one is saved through the admin API's existing
///    `saveArticleTranslation`. Keeping the two interfaces apart is how that
///    stays true — a translate method sitting beside a save method is an
///    invitation to wire them together, and the entire translation-freshness
///    model rests on there being exactly one way to write a translation.
///
/// Every method throws `Failure` and nothing else, with a code from
/// [AiFailureCode].
abstract interface class PuntlandAiApi {
  /// What this deployment can actually do.
  ///
  /// Asked once, before anything is rendered. Never throws: a console that
  /// cannot find out whether assistance exists must assume it does not, rather
  /// than showing buttons it has no reason to believe in.
  Future<AiCapabilitiesDto> fetchCapabilities();

  /// Proposes one language's version of an article, from another's.
  ///
  /// The article is named by id and the text is **not** sent: the backend reads
  /// the stored source translation itself. That is what lets the reply state
  /// the `sourceUpdatedAt` it worked from, and it is why the caller must flush
  /// the source language before asking — otherwise the model translates what
  /// was saved rather than what the journalist is looking at.
  ///
  /// [fields] narrows the request. Absent means all four.
  ///
  /// Throws [AiFailureCode.nothingToTranslate] when the source language is
  /// empty, and [AiFailureCode.inputTooLarge] for a story past the ceiling.
  Future<ArticleTranslationSuggestion> translateArticle({
    required String articleId,
    required String from,
    required String to,
    List<String>? fields,
  });

  /// Proposes a standfirst for [locale], written from that language's body.
  Future<ExcerptSuggestion> suggestExcerpt({
    required String articleId,
    required String locale,
  });

  /// Proposes alternative headlines for [locale].
  ///
  /// Plural on purpose. One suggestion is a replacement an editor either takes
  /// or does not; several are a choice, which is the thing actually being asked
  /// for when somebody wants help with a headline.
  Future<HeadlineSuggestion> suggestHeadlines({
    required String articleId,
    required String locale,
    int count,
  });

  /// Proposes alt text for an image, in every required language.
  ///
  /// Both languages at once because the rule is per-locale completeness: an
  /// image described only in Somali still blocks publishing, so suggesting one
  /// language would leave the operator exactly where they started.
  ///
  /// Throws [AiFailureCode.notAnImage] for anything else in the library.
  Future<LocalisedSuggestion> suggestAltText({
    required String assetId,
    List<String>? locales,
  });

  /// Proposes a programme's shelf synopsis, in every required language.
  Future<LocalisedSuggestion> suggestSynopsis({
    required String programId,
    List<String>? locales,
  });
}
