import '../../features/auth/domain/entities/console_user.dart';
import 'dto/admin_article_dto.dart';
import 'dto/admin_program_dto.dart';
import 'dto/broadcast_dto.dart';
import 'dto/console_config_dto.dart';
import 'dto/media_dto.dart';
import 'dto/newsroom_summary_dto.dart';
import 'dto/push_dto.dart';
import 'dto/schedule_dto.dart';
import 'dto/session_dto.dart';
import 'dto/staff_dto.dart';

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
  // ---- Session ----
  //
  // Signing in is part of this interface rather than a repository of its own,
  // because it is the same conversation with the same backend as everything
  // below it — and because it is the console's credentials that make the rest
  // of these calls answerable. `AuthRepository` sits above this, turning a
  // session into the `AuthState` the router guards on and deciding what is
  // remembered between launches; it does not speak HTTP.
  //
  // Deliberately absent from `PuntlandApi`: the reader app has no accounts, and
  // an interface it links must not be able to obtain staff credentials.

  /// Step one. Answers with a challenge, never a session.
  ///
  /// A correct password on its own does not sign anyone in — see
  /// [SecondFactorChallengeDto]. Refuses with `INVALID_CREDENTIALS` for a bad
  /// password, an unknown address and a suspended account alike: saying which
  /// one was wrong is free reconnaissance.
  Future<SecondFactorChallengeDto> signIn({
    required String email,
    required String password,
  });

  /// Step two. A correct code mints the session.
  ///
  /// Refuses with `INVALID_CODE` while attempts remain and `LOCKED_OUT` once
  /// they are spent. The count lives on the challenge server-side, so the
  /// lock-out survives a page reload — the only place it could be enforced.
  Future<ConsoleSessionDto> verifySecondFactor({
    required String email,
    required String code,
  });

  /// Re-establishes a session from a credential that outlived the process.
  ///
  /// Returns null when there is nothing to restore, rather than throwing: a
  /// cold start with no session is the ordinary case, not a failure. Anything
  /// else — a revoked token, a suspended account — throws.
  Future<ConsoleSessionDto?> restoreSession({String? refreshToken});

  /// Ends the session at the backend, not just locally.
  ///
  /// Revoking the refresh token is the part that matters: the access token
  /// stays cryptographically valid until it lapses, so a sign-out that only
  /// forgot it locally would leave a usable credential in whatever captured it.
  Future<void> signOut({String? refreshToken});

  // ---- Newsroom ----

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

  /// Staff, as bylines. A projection of [fetchStaffDirectory] for the screens
  /// that only need a name against an article.
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

  // ---- Media library ----

  /// Everything in the library, narrowed by [filter] and [query].
  ///
  /// [MediaKindFilter.needsAlt] is a filter on a *rule* rather than on a
  /// field, and it is applied here rather than in the widget so the count in
  /// the chip and the rows behind it cannot disagree.
  Future<List<MediaAssetDto>> fetchMedia({
    MediaKindFilter filter = MediaKindFilter.all,
    String? query,
  });

  Future<MediaAssetDto> fetchMediaAsset(String id);

  /// Saves the editable metadata: alt text per locale, and the credit.
  ///
  /// Everything else about an asset is set by the ingest pipeline and is not
  /// the newsroom's to change.
  Future<MediaAssetDto> saveMediaAsset(MediaAssetDto asset);

  /// Registers an upload.
  ///
  /// Returns the asset as it lands, which for an image means **with no alt
  /// text** — the library's job is to make that visible immediately rather
  /// than let an undescribed image sit in the grid looking finished.
  Future<MediaAssetDto> uploadMedia({
    required String filename,
    required MediaKind kind,
    required int byteSize,
  });

  /// Deletes an asset.
  ///
  /// Throws `Failure` with [MediaFailureCode.inUse] when an article still
  /// points at it. The UI blocks this too; the boundary must not depend on the
  /// UI having done so.
  Future<void> deleteMediaAsset(String id);

  /// Re-queues a failed transcode.
  Future<MediaAssetDto> retryMediaIngest(String id);

  // ---- Programmes and episodes ----

  Future<List<AdminProgramDto>> fetchPrograms();

  Future<AdminProgramDto> saveProgram(AdminProgramDto program);

  /// Episodes of one programme, newest first.
  ///
  /// Each carries its media asset whole rather than an id: the ingest state is
  /// what decides whether the episode can be published, and a second round
  /// trip to find that out is a second chance for the two to disagree.
  Future<List<AdminEpisodeDto>> fetchEpisodes(String programId);

  Future<AdminEpisodeDto> saveEpisode(AdminEpisodeDto episode);

  /// Moves an episode between states.
  ///
  /// Refuses a publish with an outstanding blocker — no source, a failed or
  /// unfinished transcode, or a missing locale title — with
  /// [ProgramFailureCode.episodeBlocked]. The UI blocks it too; the boundary
  /// must not depend on the UI having done so.
  Future<AdminEpisodeDto> setEpisodeStatus({
    required String id,
    required EpisodeStatus status,
    DateTime? scheduledFor,
  });

  // ---- Administration ----

  /// Every account, with the role and status the administration screen edits.
  Future<StaffDirectoryDto> fetchStaffDirectory();

  /// Changes a role.
  ///
  /// Refuses a change that would leave nobody able to administer the console,
  /// with [StaffFailureCode.lastAdmin]. The "not yourself" half of the rule is
  /// a session fact — a real backend takes the actor from the token, never from
  /// the request — so it is enforced in the UI against
  /// [StaffDirectoryDto.refusalForRoleChange] rather than passed in here.
  Future<StaffMemberDto> setStaffRole({
    required String id,
    required ConsoleRole role,
  });

  Future<StaffMemberDto> setStaffStatus({
    required String id,
    required StaffStatus status,
  });

  Future<ConsoleConfigDto> fetchConsoleConfig();

  /// Saves app configuration.
  ///
  /// Refuses a minimum build above the highest released one
  /// ([ConfigFailureCode.floorAboveRelease]) and a save with no enabled locales
  /// ([ConfigFailureCode.noLocales]). Both would take the product down for
  /// every reader at once, and neither is recoverable from inside the console.
  Future<ConsoleConfigDto> saveConsoleConfig(ConsoleConfigDto config);
}

enum ArticleStatusFilter { all, draft, inReview, scheduled, published }
