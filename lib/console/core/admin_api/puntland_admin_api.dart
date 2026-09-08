import 'dart:typed_data';

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

  /// Step one of a forgotten password: asks for a reset code.
  ///
  /// Succeeds for an address the backend has never seen, and returns the same
  /// thing it returns for a real one. That is not politeness — a reset form
  /// that answers differently is an account-enumeration oracle, and the console
  /// must not be the thing that gives one away. See
  /// [PasswordResetChallengeDto].
  Future<PasswordResetChallengeDto> requestPasswordReset({
    required String email,
  });

  /// Step two: sets the new password.
  ///
  /// Refuses with `RESET_CODE_INVALID` while attempts remain and
  /// `RESET_EXPIRED` once the code is spent, expired, or was never issued —
  /// one refusal for all three, so the failure cannot be read as "that address
  /// does exist".
  ///
  /// Does **not** sign anyone in. The operator returns to the form and passes
  /// the second factor like anyone else: a reset that minted a session would be
  /// a way around it, and "I forgot my password" is exactly the story an
  /// attacker tells.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  });

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
  /// Every narrowing parameter is null-means-all, and they compose: the list
  /// screen sends whichever of them the newsroom has set. [authorId] scopes
  /// the list to one person, which is both how an Editor narrows to a byline
  /// and how a Journalist sees only their own drafts.
  ///
  /// [locale] asks for articles that *have* a translation in that language,
  /// not ones missing it — the language a story exists in is the thing an
  /// editor filters by; what is missing is already said in words on the row.
  Future<List<AdminArticleDto>> fetchArticles({
    ArticleStatusFilter status = ArticleStatusFilter.all,
    String? authorId,
    String? categorySlug,
    String? locale,
    String? query,
  });

  Future<AdminArticleDto> fetchArticle(String id);

  /// Starts a story: a draft with a slug and one empty translation.
  ///
  /// Separate from saving one, and deliberately so. An article has an identity
  /// before it has any text — the id is what the autosave below writes
  /// against, and what the URL an editor sends a colleague is built from. A
  /// console that only created articles on first save would have nothing to
  /// autosave *to*, which is how a first draft gets lost.
  Future<AdminArticleDto> createArticle({
    required String categorySlug,
    required String sourceLocale,
    String title = '',
  });

  /// Writes one language's text, and nothing else.
  ///
  /// **The write the editor actually performs.** Article metadata and article
  /// prose are edited by different people at different moments — a sub-editor
  /// setting a category is not touching the Somali body — and saving them
  /// together means each save silently restates the other's fields. Worse, it
  /// makes freshness meaningless: the whole model rests on comparing one
  /// translation's `updatedAt` with another's, and a save that stamped every
  /// locale would clear the stale flag on a language nobody had opened.
  ///
  /// So this touches exactly one [ArticleTranslationDto] and moves exactly one
  /// clock. See [updateArticle] for the other half.
  Future<AdminArticleDto> saveArticleTranslation({
    required String id,
    required String locale,
    required String title,
    String? excerpt,
    String? bodyHtml,
    String? caption,
  });

  /// Marks a translation as still faithful, without changing a word of it.
  ///
  /// The "re-confirm translation" button. An editor who has read the English
  /// against a changed Somali and judged it still correct needs a way to say
  /// so; the only thing that clears a stale flag is a newer timestamp, and the
  /// alternative — retyping a character to force a save — would be a lie in
  /// the audit trail. Touches `updatedAt` and nothing else.
  Future<AdminArticleDto> reconfirmArticleTranslation({
    required String id,
    required String locale,
  });

  /// Writes the article's own fields: category, hero image, breaking flag.
  ///
  /// Null means "leave alone" for every parameter, which is what makes this
  /// safe to call from a metadata panel that only knows about the one control
  /// the operator touched. Detaching the hero image is [clearImage], because
  /// null is already spoken for.
  ///
  /// The image is attached **by asset id**: the backend can then refuse one
  /// that has not finished ingesting, and the library can answer "what breaks
  /// if I delete this" — neither of which a URL can express.
  Future<AdminArticleDto> updateArticle({
    required String id,
    String? categorySlug,
    String? imageId,
    bool clearImage = false,
    bool? isBreaking,
  });

  /// Moves an article between states, and records who moved it.
  ///
  /// Separate from the content writes because a state change is audited and an
  /// edit is not: publishing is the moment the newsroom becomes answerable for
  /// a story, and "who published this, and from what" has to survive the next
  /// edit that overwrites the prose.
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

  /// Mints an ingest credential for an encoder.
  ///
  /// The returned [IngestKeyDto.secret] is populated on this call and on no
  /// other — the server keeps only a scrypt hash, so there is nothing to read
  /// back later. The console has to show it once and say so.
  Future<IngestKeyDto> createIngestKey({required String label});

  /// Revokes one, answering with the credentials that remain.
  ///
  /// The remaining list rather than nothing, so the screen re-renders from the
  /// server's account of things instead of removing a row locally and hoping.
  Future<List<IngestKeyDto>> revokeIngestKey(String id);

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

  /// Registers an upload, carrying [bytes] when the caller has the file.
  ///
  /// Returns the asset as it lands, which for an image means **with no alt
  /// text** — the library's job is to make that visible immediately rather
  /// than let an undescribed image sit in the grid looking finished.
  ///
  /// **One upload, with an optional payload — not two doctrines.** Everything
  /// that puts a file in this library has, until now, been a registration: the
  /// media screen's drop zone stands in for a file picker it does not have,
  /// and posts a filename and a size. Pasting a screenshot into an article is
  /// the first caller that actually holds the file, and the drop zone is the
  /// next one. Giving that caller its own method would leave the library with
  /// two ways in and two sets of rules to keep in step; [bytes] being optional
  /// keeps the alt-text rule, the ingest state and the usage bookkeeping in
  /// one place regardless of how the file arrived.
  Future<MediaAssetDto> uploadMedia({
    required String filename,
    required MediaKind kind,
    required int byteSize,
    Uint8List? bytes,
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
