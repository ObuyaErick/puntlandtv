import 'dto/app_config_dto.dart';
import 'dto/article_dto.dart';
import 'dto/category_dto.dart';
import 'dto/live_dto.dart';
import 'dto/paged_dto.dart';
import 'dto/program_dto.dart';

/// The complete network surface of the app, as an interface.
///
/// This is the seam that keeps the API layer independent of the UI, and it
/// works in both directions:
///
/// * **Downward** — nothing here imports Flutter. This file and everything it
///   references is pure Dart, so the whole API layer is testable in a plain
///   `dart test` with no widget binding.
/// * **Upward** — nothing above the repositories may reference this type or
///   any `*Dto`. Screens consume domain entities via repository interfaces, so
///   a change to a JSON field name stops at the mapper.
///
/// Two implementations ship: [HttpPuntlandApi] against the real backend, and
/// [FixturePuntlandApi] against bundled JSON. Because they satisfy the same
/// contract, the app runs end-to-end today and switches to the live API by
/// changing one provider — see `core/api/api_providers.dart`.
///
/// Every method throws [Failure] and nothing else.
abstract interface class PuntlandApi {
  /// Startup config: stream URLs, minimum build, feature flags.
  Future<AppConfigDto> fetchConfig();

  /// Live channel status. Returns `isLive: false` plus a localised slate
  /// message when the broadcaster is off air.
  Future<LiveStatusDto> fetchLiveStatus();

  /// Radio stream endpoint and station metadata.
  Future<RadioStatusDto> fetchRadioStatus();

  /// News categories, ordered, with localised display names.
  Future<List<CategoryDto>> fetchCategories();

  /// One page of the feed. [categorySlug] null means "top news".
  Future<PagedDto<ArticleSummaryDto>> fetchArticles({
    String? categorySlug,
    String? cursor,
    int limit = 20,
  });

  /// A single article including its HTML body.
  Future<ArticleDetailDto> fetchArticle(String slug);

  /// Summaries for an article's related stories.
  Future<List<ArticleSummaryDto>> fetchArticlesBySlugs(List<String> slugs);

  /// Video-on-demand programmes.
  Future<List<ProgramDto>> fetchPrograms();

  /// One page of episodes, newest first.
  Future<PagedDto<EpisodeDto>> fetchEpisodes({
    String? programId,
    String? cursor,
    int limit = 20,
  });

  /// Registers this device for push, with the locale it wants alerts in.
  ///
  /// Per-language topics exist because a push payload arrives pre-written —
  /// it cannot be translated on the device.
  Future<void> registerDevice({
    required String token,
    required String languageCode,
    required List<String> topics,
  });
}
