import '../../../core/error/failure.dart';
import 'dto/ai_suggestion_dto.dart';
import 'puntland_ai_api.dart';

/// What the console gets when no assistance is configured.
///
/// Every method refuses, and that is not the point — the point is
/// [fetchCapabilities] answering `enabled: false`, which is what every
/// affordance watches. Nothing should ever reach the other methods, because
/// nothing should ever render a button that would call them. They refuse
/// rather than returning empty suggestions so that a widget which forgot to
/// check fails loudly in a test instead of quietly showing an editor a blank
/// review panel and letting them wonder what they did wrong.
class DisabledAiApi implements PuntlandAiApi {
  const DisabledAiApi();

  @override
  Future<AiCapabilitiesDto> fetchCapabilities() async =>
      AiCapabilitiesDto.disabled;

  @override
  Future<ArticleTranslationSuggestion> translateArticle({
    required String articleId,
    required String from,
    required String to,
    List<String>? fields,
  }) => _refuse();

  @override
  Future<ExcerptSuggestion> suggestExcerpt({
    required String articleId,
    required String locale,
  }) => _refuse();

  @override
  Future<HeadlineSuggestion> suggestHeadlines({
    required String articleId,
    required String locale,
    int count = 3,
  }) => _refuse();

  @override
  Future<LocalisedSuggestion> suggestAltText({
    required String assetId,
    List<String>? locales,
  }) => _refuse();

  @override
  Future<LocalisedSuggestion> suggestSynopsis({
    required String programId,
    List<String>? locales,
  }) => _refuse();

  Future<Never> _refuse() => Future.error(
    const Failure(kind: FailureKind.server, code: AiFailureCode.disabled),
  );
}
