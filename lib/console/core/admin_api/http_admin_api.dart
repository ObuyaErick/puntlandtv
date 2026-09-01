import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/api_exception.dart';
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
import 'console_credentials.dart';
import 'puntland_admin_api.dart';

/// [PuntlandAdminApi] over HTTP, against `puntland-api`.
///
/// The counterpart to `HttpPuntlandApi`, and it earns its keep the same way:
/// every thrown object becomes a [Failure], so nothing above this class has a
/// reason to import `dio` or to know what a status code is.
///
/// Two things differ from the reader's client, both because this one *writes*.
///
/// **Request bodies are built here rather than taken from `toJson()`.** The
/// admin DTOs are read-shaped — `AdminArticleDto` carries `author_name`,
/// `updated_at`, `image_url`; `MediaAssetDto` carries `byte_size` and
/// `processing`. None of those are the console's to set, and several exist on
/// the backend precisely to be refused. Posting a DTO whole would rely on the
/// server stripping the fields it owns; naming the writable ones here makes the
/// write surface something you can read off this file, and means a field added
/// to a DTO tomorrow is not silently sent as an edit.
///
/// **Requests speak the API's parameter names, responses are parsed by the
/// DTOs' own `fromJson`.** So bodies and queries are lower-camel
/// (`categorySlug`, `authorId`) while responses are snake (`category_slug`) —
/// not an inconsistency to tidy away later but the two vocabularies meeting:
/// one belongs to the backend's DTOs, the other to `json_serializable`.
/// Enum values are symmetric — `enum.name` in both directions.
class HttpAdminApi implements PuntlandAdminApi {
  HttpAdminApi(this._dio, this._credentials);

  final Dio _dio;

  /// Shared with the repository that persists them. See [ConsoleCredentials]:
  /// the backend makes each refresh token single-use, so a renewal performed
  /// here has to become visible to whoever writes it to storage.
  final ConsoleCredentials _credentials;

  /// Guards against two refreshes racing.
  ///
  /// A screen that fires four requests at once meets four `401`s at once. Each
  /// would otherwise spend the refresh token, and three would fail — because
  /// the first rotation revoked the token the others were holding. They wait on
  /// one renewal instead.
  Future<ConsoleSessionDto?>? _renewal;

  // ---- Session ----

  @override
  Future<SecondFactorChallengeDto> signIn({
    required String email,
    required String password,
  }) => _send(
    'POST',
    '/v1/auth/sign-in',
    SecondFactorChallengeDto.fromJson,
    body: {'email': email, 'password': password},
    authenticated: false,
  );

  @override
  Future<ConsoleSessionDto> verifySecondFactor({
    required String email,
    required String code,
  }) async {
    final session = await _send(
      'POST',
      '/v1/auth/second-factor',
      ConsoleSessionDto.fromJson,
      body: {'email': email, 'code': code},
      authenticated: false,
    );
    _hold(session);
    return session;
  }

  @override
  Future<ConsoleSessionDto?> restoreSession({String? refreshToken}) async {
    try {
      final session = await _send(
        'POST',
        '/v1/auth/refresh',
        ConsoleSessionDto.fromJson,
        // Sent for a build with no cookie jar. The browser build has no value
        // to send — the token is an httpOnly cookie, which the backend reads in
        // preference to the body anyway.
        body: {'refreshToken': ?refreshToken},
        authenticated: false,
      );
      _hold(session);
      return session;
    } on Failure catch (failure) {
      // No session to restore is the ordinary state of a cold start, not a
      // failure worth surfacing. Anything else is.
      if (_isUnauthenticated(failure)) {
        _credentials.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut({String? refreshToken}) async {
    try {
      await _dio.post<dynamic>(
        '/v1/auth/logout',
        data: {'refreshToken': ?(refreshToken ?? _credentials.refreshToken)},
      );
    } catch (_) {
      // A sign-out that cannot reach the backend still has to sign the operator
      // out locally: leaving them looking at a console they believe they have
      // left is worse than a refresh token that lapses on its own schedule.
    } finally {
      _credentials.clear();
    }
  }

  void _hold(ConsoleSessionDto session) => _credentials.hold(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
  );

  static bool _isUnauthenticated(Failure failure) =>
      failure.code == 'HTTP_401' ||
      failure.code == 'INVALID_CREDENTIALS' ||
      failure.code == 'TWO_FACTOR_NOT_ENROLLED';

  /// Exchanges the refresh token for a new pair, once, however many callers ask.
  Future<ConsoleSessionDto?> _renew() {
    return _renewal ??= restoreSession(
      refreshToken: _credentials.refreshToken,
    ).whenComplete(() => _renewal = null);
  }

  // ---- Newsroom ----

  @override
  Future<NewsroomSummaryDto> fetchNewsroomSummary() =>
      _get('/v1/admin/newsroom/summary', NewsroomSummaryDto.fromJson);

  // ---- Articles ----

  @override
  Future<List<AdminArticleDto>> fetchArticles({
    ArticleStatusFilter status = ArticleStatusFilter.all,
    String? authorId,
    String? query,
  }) => _getList(
    '/v1/admin/articles',
    AdminArticleDto.fromJson,
    // The backend narrows this to the actor for a role without publish rights,
    // whatever is asked for here. A Journalist seeing only their own drafts is
    // a property of the token, not of this parameter.
    query: {'status': status.name, 'authorId': ?authorId, 'query': ?query},
  );

  @override
  Future<AdminArticleDto> fetchArticle(String id) =>
      _get('/v1/admin/articles/$id', AdminArticleDto.fromJson);

  @override
  Future<AdminArticleDto> saveArticle(AdminArticleDto article) => _send(
    'PUT',
    '/v1/admin/articles/${article.id}',
    AdminArticleDto.fromJson,
    // `status` is absent deliberately: a state change is audited and goes
    // through [setArticleStatus]. So is the hero image — `AdminArticleDto`
    // carries `image_url`, and the backend attaches by asset id after checking
    // the asset is ready, which a URL cannot express. Sending nothing leaves
    // the current image alone; clearing one needs an id-carrying field on the
    // DTO first.
    body: {
      'id': article.id,
      'categorySlug': article.categorySlug,
      'sourceLocale': article.sourceLocale,
      'isBreaking': article.isBreaking,
      'translations': {
        for (final entry in article.translations.entries)
          entry.key: {
            'title': entry.value.title,
            'excerpt': ?entry.value.excerpt,
            'bodyHtml': ?entry.value.bodyHtml,
            'caption': ?entry.value.caption,
          },
      },
    },
  );

  @override
  Future<AdminArticleDto> setArticleStatus({
    required String id,
    required ArticleStatus status,
    DateTime? scheduledFor,
  }) => _send(
    'POST',
    '/v1/admin/articles/$id/status',
    AdminArticleDto.fromJson,
    body: {
      'status': status.name,
      'scheduledFor': ?scheduledFor?.toIso8601String(),
    },
  );

  @override
  Future<void> deleteArticle(String id) => _delete('/v1/admin/articles/$id');

  @override
  Future<List<ConsoleUser>> fetchStaff() =>
      _getList('/v1/admin/staff', _consoleUserFromJson);

  // ---- Operations ----

  @override
  Future<BroadcastControlDto> fetchBroadcastControl() =>
      _get('/v1/admin/broadcast', BroadcastControlDto.fromJson);

  @override
  Future<BroadcastControlDto> saveBroadcastControl(BroadcastControlDto value) =>
      _send(
        'PUT',
        '/v1/admin/broadcast',
        BroadcastControlDto.fromJson,
        // Uptime, viewer and listener counts are measurements, not settings:
        // they come back on the response and are not sent. A rendition's
        // `healthy` and `bitrate_kbps` are the encoder's for the same reason —
        // only `enabled` is an operator decision.
        body: {
          'tvOnAir': value.tvOnAir,
          'radioOnAir': value.radioOnAir,
          'channelName': value.channelName,
          'renditions': [
            for (final rendition in value.renditions)
              {'rung': rendition.rung, 'enabled': rendition.enabled},
          ],
          'slate': {
            for (final entry in value.slate.entries)
              entry.key: {
                'title': entry.value.title,
                'detail': entry.value.detail,
              },
          },
        },
      );

  @override
  Future<DayScheduleDto> fetchSchedule(DateTime day) => _get(
    '/v1/admin/schedule',
    _dayScheduleFromJson,
    query: {'day': day.toIso8601String()},
  );

  @override
  Future<DayScheduleDto> saveSchedule(DayScheduleDto schedule) => _send(
    'PUT',
    '/v1/admin/schedule',
    _dayScheduleFromJson,
    // The whole day goes at once. Per-slot writes would make the gap and
    // overlap check meaningless, since the issues are a property of the day.
    //
    // `resolveOverlaps` is not sent: [DayScheduleDto.resolveOverlaps] is a
    // console action the operator takes and can see the result of before
    // saving, so what arrives here is already the intended schedule.
    body: {
      'day': schedule.day.toIso8601String(),
      'slots': [
        for (final slot in schedule.ordered)
          {
            'id': slot.id,
            'title': slot.title,
            'startsAt': slot.startsAt.toIso8601String(),
            'durationMinutes': slot.duration.inMinutes,
            'genre': ?slot.genre,
            'isLive': slot.isLive,
            'isRepeat': slot.isRepeat,
          },
      ],
    },
  );

  @override
  Future<List<CategoryConfigDto>> fetchCategories() =>
      _getList('/v1/admin/categories', CategoryConfigDto.fromJson);

  @override
  Future<List<CategoryConfigDto>> saveCategories(
    List<CategoryConfigDto> categories,
  ) => _sendList(
    'PUT',
    '/v1/admin/categories',
    CategoryConfigDto.fromJson,
    // `article_count` is a count, not a setting, and is not sent back.
    body: {
      'categories': [
        for (final category in categories)
          {
            'slug': category.slug,
            'names': category.names,
            'order': category.order,
          },
      ],
    },
  );

  @override
  Future<PushReachDto> fetchPushReach(Set<String> topics) => _get(
    '/v1/admin/push/reach',
    PushReachDto.fromJson,
    query: {'topics': topics.join(',')},
  );

  @override
  Future<List<PushHistoryEntryDto>> fetchPushHistory() =>
      _getList('/v1/admin/push/history', _pushHistoryEntryFromJson);

  @override
  Future<PushHistoryEntryDto> sendPush(PushDraftDto draft) => _send(
    'POST',
    '/v1/admin/push',
    _pushHistoryEntryFromJson,
    body: {
      'messages': {
        for (final entry in draft.messages.entries)
          entry.key: {'title': entry.value.title, 'body': entry.value.body},
      },
      'topics': draft.topics.toList(),
      'deepLink': ?draft.deepLink,
      'fallback': draft.fallback,
    },
  );

  // ---- Media library ----

  @override
  Future<List<MediaAssetDto>> fetchMedia({
    MediaKindFilter filter = MediaKindFilter.all,
    String? query,
  }) => _getList(
    '/v1/admin/media',
    MediaAssetDto.fromJson,
    // The response also carries the filter chips' counts, computed over the
    // whole library. `fetchMedia` returns only the rows, so they are dropped
    // here — `MediaCounts` is recomputed from what the screen holds.
    query: {'filter': filter.name, 'query': ?query},
  );

  @override
  Future<MediaAssetDto> fetchMediaAsset(String id) =>
      _get('/v1/admin/media/$id', MediaAssetDto.fromJson);

  @override
  Future<MediaAssetDto> saveMediaAsset(MediaAssetDto asset) => _send(
    'PUT',
    '/v1/admin/media/${asset.id}',
    MediaAssetDto.fromJson,
    // Alt text and credit are the only editable metadata. Everything else about
    // an asset is the ingest pipeline's, which is why this is not the DTO whole.
    body: {'alt': asset.alt, 'credit': asset.credit},
  );

  @override
  Future<MediaAssetDto> uploadMedia({
    required String filename,
    required MediaKind kind,
    required int byteSize,
  }) => _send('POST', '/v1/admin/media/register', MediaAssetDto.fromJson, body: {
    'filename': filename,
    'kind': kind.name,
    'byteSize': byteSize,
  });

  @override
  Future<void> deleteMediaAsset(String id) => _delete('/v1/admin/media/$id');

  @override
  Future<MediaAssetDto> retryMediaIngest(String id) =>
      _send('POST', '/v1/admin/media/$id/retry', MediaAssetDto.fromJson);

  // ---- Programmes and episodes ----

  @override
  Future<List<AdminProgramDto>> fetchPrograms() =>
      _getList('/v1/admin/programs', AdminProgramDto.fromJson);

  @override
  Future<AdminProgramDto> saveProgram(AdminProgramDto program) => _send(
    'PUT',
    '/v1/admin/programs',
    AdminProgramDto.fromJson,
    // `episode_count` belongs to the episodes and `artwork_url` is an asset's,
    // attached by id after an ingest check — neither is posted from the form.
    body: {
      'id': program.id,
      'titles': program.titles,
      'synopses': program.synopses,
      'cadence': program.cadence.name,
      'genre': program.genre.name,
      'isPublished': program.isPublished,
    },
  );

  @override
  Future<List<AdminEpisodeDto>> fetchEpisodes(String programId) => _getList(
    '/v1/admin/programs/$programId/episodes',
    AdminEpisodeDto.fromJson,
  );

  @override
  Future<AdminEpisodeDto> saveEpisode(AdminEpisodeDto episode) => _send(
    'PUT',
    '/v1/admin/programs/${episode.programId}/episodes',
    AdminEpisodeDto.fromJson,
    // The source is not sent, matching the fixture: it is the ingest pipeline's
    // to set, and an episode that could name its own source could name a ready
    // one it does not own. Attaching is its own request because it is its own
    // gate — `PUT /v1/admin/episodes/:id/source` — and needs an asset id, which
    // this DTO does not carry separately from the asset itself.
    body: {
      'id': episode.id,
      'number': episode.number,
      'titles': episode.titles,
      'durationSeconds': episode.duration.inSeconds,
    },
  );

  @override
  Future<AdminEpisodeDto> setEpisodeStatus({
    required String id,
    required EpisodeStatus status,
    DateTime? scheduledFor,
  }) => _send(
    'POST',
    '/v1/admin/episodes/$id/status',
    AdminEpisodeDto.fromJson,
    body: {
      'status': status.name,
      'scheduledFor': ?scheduledFor?.toIso8601String(),
    },
  );

  // ---- Administration ----

  @override
  Future<StaffDirectoryDto> fetchStaffDirectory() =>
      _get('/v1/admin/users', StaffDirectoryDto.fromJson);

  @override
  Future<StaffMemberDto> setStaffRole({
    required String id,
    required ConsoleRole role,
  }) => _send(
    'PATCH',
    '/v1/admin/users/$id/role',
    StaffMemberDto.fromJson,
    body: {'role': role.name},
  );

  @override
  Future<StaffMemberDto> setStaffStatus({
    required String id,
    required StaffStatus status,
  }) => _send(
    'PATCH',
    '/v1/admin/users/$id/status',
    StaffMemberDto.fromJson,
    body: {'status': status.name},
  );

  @override
  Future<ConsoleConfigDto> fetchConsoleConfig() =>
      _get('/v1/admin/config', ConsoleConfigDto.fromJson);

  @override
  Future<ConsoleConfigDto> saveConsoleConfig(ConsoleConfigDto config) => _send(
    'PUT',
    '/v1/admin/config',
    ConsoleConfigDto.fromJson,
    // `current_released_build` is the ceiling the minimum is checked against.
    // It is release infrastructure's to report, not the console's to raise —
    // a config screen that could raise its own ceiling could set a floor above
    // every build in the field and lock every reader out at once.
    body: {
      'minimumSupportedBuild': config.minimumSupportedBuild,
      'dataSaverDefault': config.dataSaverDefault,
      'locales': [
        for (final locale in config.locales)
          {'code': locale.code, 'enabled': locale.enabled},
      ],
      'flags': [
        for (final flag in config.flags)
          {'key': flag.key, 'enabled': flag.enabled},
      ],
    },
  );

  // ---- Payload shapes with no `fromJson` of their own ----

  /// `fetchStaff` is bylines: a name against an article, not an account.
  static ConsoleUser _consoleUserFromJson(Map<String, dynamic> json) =>
      ConsoleUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: ConsoleRole.values.firstWhere(
          (role) => role.name == json['role'],
          orElse: () => ConsoleRole.journalist,
        ),
      );

  /// The response also carries `issues`, `is_publishable` and
  /// `programmed_minutes`. They are not read: [DayScheduleDto] computes all
  /// three from the slots, and parsing the server's copy would create two
  /// answers to the same question that could disagree.
  static DayScheduleDto _dayScheduleFromJson(Map<String, dynamic> json) =>
      DayScheduleDto(
        day: DateTime.parse(json['day'] as String),
        slots: (json['slots'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(ScheduleSlotDto.fromJson)
            .toList(growable: false),
      );

  static PushHistoryEntryDto _pushHistoryEntryFromJson(
    Map<String, dynamic> json,
  ) => PushHistoryEntryDto(
    id: json['id'] as String,
    title: json['title'] as String,
    sentAt: DateTime.parse(json['sent_at'] as String),
    sentBy: json['sent_by'] as String,
    topic: json['topic'] as String,
    delivered: json['delivered'] as int,
    targeted: json['targeted'] as int,
  );

  // ---- Transport ----

  /// Every request goes through here, so the credential is attached in one
  /// place and a lapsed access token is renewed in one place.
  ///
  /// A `401` on an authenticated call is not the operator's problem to solve:
  /// the access token is short-lived by design, and bouncing someone to the
  /// login form because their session aged out mid-edit would lose the edit.
  /// One renewal, then one retry. If the renewal comes back empty the session
  /// really is over, and the original `401` is what the caller should see.
  Future<Response<dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    try {
      return await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: _headers(authenticated)),
      );
    } on DioException catch (error) {
      final isLapsed =
          authenticated && error.response?.statusCode == 401;
      if (!isLapsed) rethrow;

      ConsoleSessionDto? renewed;
      try {
        renewed = await _renew();
      } catch (_) {
        // A renewal that fails for its own reasons must not replace the error
        // the caller was actually given.
        rethrow;
      }
      if (renewed == null) rethrow;

      return await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: _headers(true)),
      );
    }
  }

  /// The bearer header, when there is a token and the call wants it.
  ///
  /// The browser build usually has no token to attach — the backend set an
  /// httpOnly cookie and the client cannot read it, which is the point — and
  /// the cookie rides along on its own because `withCredentials` is set.
  Map<String, dynamic>? _headers(bool authenticated) {
    if (!authenticated) return null;
    final token = _credentials.accessToken;
    return token == null ? null : {'Authorization': 'Bearer $token'};
  }

  Future<T> _get<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _request('GET', path, query: query);
      return parse(_requireBody(res.data));
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _request('GET', path, query: query);
      return _rowsOf(res.data).map(parse).toList(growable: false);
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  Future<T> _send<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final res = await _request(
        method,
        path,
        body: body,
        authenticated: authenticated,
      );
      return parse(_requireBody(res.data));
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  Future<List<T>> _sendList<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _request(method, path, body: body);
      return _rowsOf(res.data).map(parse).toList(growable: false);
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  Future<void> _delete(String path) async {
    try {
      await _request('DELETE', path);
    } catch (e, st) {
      throw ApiExceptionMapper.map(e, st);
    }
  }

  static Map<String, dynamic> _requireBody(dynamic body) {
    if (body is! Map<String, dynamic>) {
      throw const Failure(
        kind: FailureKind.malformedResponse,
        code: 'EMPTY_BODY',
      );
    }
    return body;
  }

  /// Tolerates a bare array and a `{data: [...]}` envelope.
  ///
  /// Both occur: most admin lists are bare, the media library's is enveloped
  /// alongside the chip counts. Accepting either also means a proxy that
  /// unwraps one cannot take the console down.
  static Iterable<Map<String, dynamic>> _rowsOf(dynamic body) => switch (body) {
    List<dynamic>() => body.cast<Map<String, dynamic>>(),
    Map<String, dynamic>() =>
      (body['data'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
    _ => const <Map<String, dynamic>>[],
  };
}
