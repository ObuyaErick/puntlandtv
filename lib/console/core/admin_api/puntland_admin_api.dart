import '../../features/auth/domain/entities/console_user.dart';
import 'dto/admin_article_dto.dart';
import 'dto/broadcast_dto.dart';
import 'dto/newsroom_summary_dto.dart';
import 'dto/push_dto.dart';
import 'dto/schedule_dto.dart';

/// The console's write surface.
///
/// **Deliberately not part of `PuntlandApi`.** The reader app links that
/// interface; it must not be able to publish an article, take the channel off
/// air, or send a push to every phone in the region. Keeping the two
/// interfaces separate makes that a compile-time property rather than a
/// promise made in code review — `tool/check_layers.dart` enforces that no app
/// feature imports anything under `console/`.
///
/// Like `PuntlandApi`, this ships with a fixture implementation so the console
/// is buildable and demonstrable before the backend exists. Every method
/// throws `Failure` and nothing else.
abstract interface class PuntlandAdminApi {
  /// The overview screen's counters and today's queue.
  Future<NewsroomSummaryDto> fetchNewsroomSummary();

  /// Articles in every state, not just published ones.
  ///
  /// [authorId] scopes the list to one person, which is how a Journalist sees
  /// only their own drafts.
  Future<List<AdminArticleDto>> fetchArticles({
    ArticleStatusFilter status = ArticleStatusFilter.all,
    String? authorId,
    String? query,
  });

  Future<AdminArticleDto> fetchArticle(String id);

  Future<AdminArticleDto> saveArticle(AdminArticleDto article);

  /// Moves an article between states. Separate from [saveArticle] because a
  /// state change is audited and a content edit is not.
  Future<AdminArticleDto> setArticleStatus({
    required String id,
    required ArticleStatus status,
    DateTime? scheduledFor,
  });

  Future<void> deleteArticle(String id);

  /// Staff directory, for the users screen and author attribution.
  Future<List<ConsoleUser>> fetchStaff();

  // ---- Operations ----

  Future<BroadcastControlDto> fetchBroadcastControl();

  Future<BroadcastControlDto> saveBroadcastControl(BroadcastControlDto value);

  Future<DayScheduleDto> fetchSchedule(DateTime day);

  Future<DayScheduleDto> saveSchedule(DayScheduleDto schedule);

  Future<List<CategoryConfigDto>> fetchCategories();

  Future<List<CategoryConfigDto>> saveCategories(
    List<CategoryConfigDto> categories,
  );

  /// How many devices an alert would reach, split by language preference.
  Future<PushReachDto> fetchPushReach(Set<String> topics);

  Future<List<PushHistoryEntryDto>> fetchPushHistory();

  /// Sends an alert. Refuses a draft that is not complete in every required
  /// locale — the UI blocks this too, but the boundary should not depend on
  /// the UI having done so.
  Future<PushHistoryEntryDto> sendPush(PushDraftDto draft);
}

enum ArticleStatusFilter { all, draft, inReview, scheduled, published }
