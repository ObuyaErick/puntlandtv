import 'dart:math';
import 'dart:typed_data';

import '../../../core/error/failure.dart';
import '../../features/auth/domain/entities/console_user.dart';
import 'dto/admin_article_dto.dart';
import 'dto/admin_program_dto.dart';
import 'dto/broadcast_dto.dart';
import 'dto/channel_dto.dart';
import 'dto/console_config_dto.dart';
import 'dto/media_dto.dart';
import 'dto/newsroom_summary_dto.dart';
import 'dto/push_dto.dart';
import 'dto/schedule_dto.dart';
import 'dto/session_dto.dart';
import 'dto/staff_dto.dart';
import 'puntland_admin_api.dart';

/// [PuntlandAdminApi] over an in-memory store.
///
/// Writes are kept in memory for the session, so the console genuinely works:
/// an article saved here comes back changed, and Phase 6 wires this same store
/// to the reader app's fixtures so publishing in the console makes the story
/// appear in the app.
class FixtureAdminApi implements PuntlandAdminApi {
  FixtureAdminApi({
    this.latency = const Duration(milliseconds: 350),
    DateTime? now,
  }) : _now = now ?? DateTime.now() {
    _seed();
  }

  final Duration latency;

  /// Injectable clock. The article list renders absolute wall-clock times, so
  /// seeding from a live `DateTime.now()` makes every golden shift by a minute
  /// between runs. Tests pin it; production leaves it alone.
  final DateTime _now;

  final _articles = <String, AdminArticleDto>{};
  final _random = Random();

  static const _staff = <ConsoleUser>[
    ConsoleUser(
      id: 'u-editor',
      name: 'A. Yuusuf',
      email: 'a.yuusuf@pltv.so',
      role: ConsoleRole.editor,
    ),
    ConsoleUser(
      id: 'u-journalist',
      name: 'F. Xasan',
      email: 'f.xasan@pltv.so',
      role: ConsoleRole.journalist,
    ),
    ConsoleUser(
      id: 'u-ops',
      name: 'M. Cali',
      email: 'm.cali@pltv.so',
      role: ConsoleRole.operations,
    ),
    ConsoleUser(
      id: 'u-admin',
      name: 'S. Warsame',
      email: 's.warsame@pltv.so',
      role: ConsoleRole.admin,
    ),
  ];

  Future<T> _respond<T>(T Function() build) async {
    await Future<void>.delayed(latency);
    return build();
  }

  // ---- Session ----

  /// The one code the fixture accepts.
  ///
  /// Any password is taken; the code is not. That keeps the demo usable while
  /// still exercising the failure path that matters — a wrong second factor,
  /// three times, locking the operator out.
  ///
  /// Six digits, like the one the backend issues. The PIN field is six boxes
  /// wide and submits itself when the last is filled, so a shorter code would
  /// leave the demo unable to complete a step the real flow completes on its
  /// own.
  static const validSecondFactorCode = '418902';

  /// Prefix for the fixture's stand-in refresh token.
  ///
  /// It encodes the account rather than proving anything, which is the honest
  /// shape for a fixture: there is no cryptography here to pretend otherwise,
  /// and the console's restore path needs *some* credential to resolve so that
  /// the code above it is written against the real flow.
  static const _tokenPrefix = 'fixture-session:';

  static ConsoleUser? _lookup(String email) {
    final wanted = email.trim().toLowerCase();
    for (final user in _staff) {
      if (user.email.toLowerCase() == wanted) return user;
    }
    return null;
  }

  @override
  Future<SecondFactorChallengeDto> signIn({
    required String email,
    required String password,
  }) => _respond(() {
    if (password.trim().isEmpty) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: 'INVALID_CREDENTIALS',
      );
    }
    // Deliberately the same refusal an unknown address gets: telling an
    // attacker which half was wrong is free reconnaissance.
    if (_lookup(email) == null) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: 'INVALID_CREDENTIALS',
      );
    }
    return SecondFactorChallengeDto(
      email: email,
      devCode: validSecondFactorCode,
    );
  });

  @override
  Future<ConsoleSessionDto> verifySecondFactor({
    required String email,
    required String code,
  }) => _respond(() {
    final user = _lookup(email);
    if (user == null) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: 'INVALID_CREDENTIALS',
      );
    }
    if (code.trim() != validSecondFactorCode) {
      throw const Failure(kind: FailureKind.unknown, code: 'INVALID_CODE');
    }
    return ConsoleSessionDto(
      user: user,
      accessToken: '$_tokenPrefix${user.id}',
      refreshToken: '$_tokenPrefix${user.id}',
    );
  });

  @override
  Future<ConsoleSessionDto?> restoreSession({String? refreshToken}) =>
      _respond(() {
        if (refreshToken == null || !refreshToken.startsWith(_tokenPrefix)) {
          return null;
        }
        final id = refreshToken.substring(_tokenPrefix.length);
        for (final user in _staff) {
          if (user.id == id) {
            return ConsoleSessionDto(
              user: user,
              accessToken: refreshToken,
              refreshToken: refreshToken,
            );
          }
        }
        return null;
      });

  @override
  Future<void> signOut({String? refreshToken}) => _respond(() {});

  /// The one reset code the fixture accepts.
  static const validResetCode = '654321';

  /// Outstanding reset codes, by address.
  ///
  /// Kept so the fixture can refuse a code nobody asked for, which is the
  /// failure the screen has to handle and the one a fixture that always said
  /// yes would hide.
  final _resetsRequested = <String>{};

  @override
  Future<PasswordResetChallengeDto> requestPasswordReset({
    required String email,
  }) => _respond(() {
    final address = email.trim().toLowerCase();

    // Recorded only for a real account — but the answer is the same either
    // way, which is the property worth reproducing here. A fixture that
    // refused an unknown address would let a screen be written against a
    // behaviour the backend deliberately does not have.
    if (_lookup(address) != null) _resetsRequested.add(address);

    return PasswordResetChallengeDto(
      email: address,
      devCode: _resetsRequested.contains(address) ? validResetCode : null,
    );
  });

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) => _respond(() {
    final address = email.trim().toLowerCase();

    if (!_resetsRequested.contains(address)) {
      throw const Failure(kind: FailureKind.unknown, code: 'RESET_EXPIRED');
    }
    if (code.trim() != validResetCode) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: 'RESET_CODE_INVALID',
      );
    }
    // The backend enforces a floor on length; the fixture enforces it too, so
    // the screen cannot be built against a boundary that only one of them has.
    if (password.length < 10) {
      throw const Failure(kind: FailureKind.unknown, code: 'VALIDATION_FAILED');
    }

    // Single-use, like the real one.
    _resetsRequested.remove(address);
  });

  // ---- Newsroom ----

  @override
  Future<NewsroomSummaryDto> fetchNewsroomSummary() => _respond(() {
    final published = _articles.values
        .where((a) => a.status == ArticleStatus.published)
        .toList();
    final soCount = published
        .where((a) => a.translations.containsKey('so'))
        .length;
    final enCount = published
        .where((a) => a.translations.containsKey('en'))
        .length;

    return NewsroomSummaryDto(
      // Derived from the channels' own state rather than written out here, so
      // the overview and live control cannot tell different stories.
      onAir: [
        for (final channel in _channelRows())
          if (channel.hasTv) _onAirFor(channel),
      ],
      publishedToday: published.length,
      publishedTodayByLocale: {'so': soCount, 'en': enCount},
      awaitingReview: _articles.values
          .where((a) => a.status == ArticleStatus.inReview)
          .length,
      breakingFlagged: _articles.values.where((a) => a.isBreaking).length,
      failedIngests: 2,
      failedIngestDetail:
          'Dood Furan ep. 18 — transcode 240p failed. Retry queued.',
    );
  });

  /// One channel's line on the overview: what is on now from its schedule,
  /// and its health from its broadcast state.
  OnAirDto _onAirFor(ChannelDto channel) {
    final control = _broadcasts[channel.key]!;
    final nowPlaying = _nowPlaying(channel.key);
    return OnAirDto(
      key: channel.key,
      name: channel.name,
      isLive: control.isLiveToReaders,
      programmeTitle: nowPlaying?.title ?? channel.name,
      elapsed: control.isLiveToReaders ? control.uptime : Duration.zero,
      renditions: [
        for (final rendition in control.renditions)
          RenditionDto(label: rendition.rung, healthy: rendition.healthy),
      ],
      concurrentViewers: control.concurrentViewers,
      radioOnAir: control.radioOnAir,
    );
  }

  @override
  Future<List<AdminArticleDto>> fetchArticles({
    ArticleStatusFilter status = ArticleStatusFilter.all,
    String? authorId,
    String? categorySlug,
    String? locale,
    String? query,
  }) => _respond(() {
    var rows = _articles.values.toList();

    if (status != ArticleStatusFilter.all) {
      final wanted = switch (status) {
        ArticleStatusFilter.draft => ArticleStatus.draft,
        ArticleStatusFilter.inReview => ArticleStatus.inReview,
        ArticleStatusFilter.scheduled => ArticleStatus.scheduled,
        ArticleStatusFilter.published => ArticleStatus.published,
        ArticleStatusFilter.all => ArticleStatus.draft,
      };
      rows = rows.where((a) => a.status == wanted).toList();
    }

    // Scoping to an author is how a Journalist sees only their own work.
    if (authorId != null) {
      rows = rows.where((a) => a.authorId == authorId).toList();
    }

    if (categorySlug != null) {
      rows = rows.where((a) => a.categorySlug == categorySlug).toList();
    }

    // The same test `missingLocales` uses, deliberately: the row already tells
    // an editor which languages a story is missing, and a filter that
    // disagreed with the note printed beside it would be read as a bug.
    if (locale != null) {
      rows = rows.where((a) => a.translations.containsKey(locale)).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final needle = query.toLowerCase();
      rows = rows
          .where(
            (a) => a.translations.values.any(
              (t) => t.title.toLowerCase().contains(needle),
            ),
          )
          .toList();
    }

    rows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return rows;
  });

  @override
  Future<AdminArticleDto> fetchArticle(String id) => _respond(() {
    final article = _articles[id];
    if (article == null) {
      throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404');
    }
    return article;
  });

  @override
  Future<AdminArticleDto> createArticle({
    required String categorySlug,
    required String sourceLocale,
    String title = '',
  }) => _respond(() {
    final id = newId();
    // The author is the actor, and the fixture has one signed-in actor it can
    // name: the editor. A real backend takes this from the token.
    final author = _staff.first;
    final created = AdminArticleDto(
      id: id,
      status: ArticleStatus.draft,
      translations: {
        sourceLocale: ArticleTranslationDto(
          title: title,
          updatedAt: _now,
          updatedBy: author.name,
        ),
      },
      categorySlug: categorySlug,
      slug: _slug(title, id),
      authorId: author.id,
      authorName: author.name,
      updatedAt: _now,
      sourceLocale: sourceLocale,
    );
    _articles[id] = created;
    return created;
  });

  @override
  Future<AdminArticleDto> saveArticleTranslation({
    required String id,
    required String locale,
    required String title,
    String? excerpt,
    String? bodyHtml,
    String? caption,
  }) => _respond(() {
    final article = _require(id);
    // One row, one clock. The rest of the article — including every other
    // language — is left exactly as it was, which is the whole basis of the
    // staleness comparison.
    final updated = article.withTranslation(
      locale,
      ArticleTranslationDto(
        title: title,
        excerpt: excerpt,
        bodyHtml: bodyHtml,
        caption: caption,
        updatedAt: _now,
        updatedBy: _staff.first.name,
      ),
    );
    _articles[id] = updated;
    return updated;
  });

  @override
  Future<AdminArticleDto> reconfirmArticleTranslation({
    required String id,
    required String locale,
  }) => _respond(() {
    final article = _require(id);
    final existing = article.translations[locale];
    if (existing == null) {
      throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404');
    }
    // `copyWith` on the translation, so the text is carried across untouched
    // and only the timestamp moves. That is the entire operation.
    final updated = article.withTranslation(
      locale,
      existing.copyWith(updatedAt: _now, updatedBy: _staff.first.name),
    );
    _articles[id] = updated;
    return updated;
  });

  @override
  Future<AdminArticleDto> updateArticle({
    required String id,
    String? categorySlug,
    String? imageId,
    bool clearImage = false,
    bool? isBreaking,
  }) => _respond(() {
    final article = _require(id);

    // Metadata does not age the story. Leaving `updatedAt` alone is what stops
    // a category change from marking every translation stale.
    final updated = article.copyWith(
      categorySlug: categorySlug,
      isBreaking: isBreaking,
      clearImage: clearImage,
      imageId: imageId,
      imageUrl: imageId == null ? null : _mediaById(imageId)?.url,
      imageAlt: imageId == null ? null : _mediaById(imageId)?.alt['so'],
    );
    _articles[id] = updated;
    return updated;
  });

  @override
  Future<AdminArticleDto> setArticleStatus({
    required String id,
    required ArticleStatus status,
    DateTime? scheduledFor,
  }) => _respond(() {
    final article = _require(id);
    final updated = article.copyWith(
      status: status,
      scheduledFor: scheduledFor,
      clearScheduledFor:
          scheduledFor == null && status != ArticleStatus.scheduled,
      publishedAt: status == ArticleStatus.published ? _now : null,
      clearPublishedAt: status != ArticleStatus.published,
    );
    _articles[id] = updated;
    return updated;
  });

  AdminArticleDto _require(String id) {
    final article = _articles[id];
    if (article == null) {
      throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404');
    }
    return article;
  }

  MediaAssetDto? _mediaById(String id) => _media[id];

  /// A URL segment from the headline, falling back to the id.
  ///
  /// Somali is written in the Latin alphabet, so this is the whole of it — no
  /// transliteration table, and the fallback covers a draft created before
  /// anyone has typed a headline.
  static String _slug(String title, String id) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r"['\u2019]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? id : slug;
  }

  @override
  Future<void> deleteArticle(String id) => _respond(() {
    _articles.remove(id);
  });

  @override
  Future<List<ConsoleUser>> fetchStaff() => _respond(() => _staff);

  // ---- Operations ----

  static const _rtmpBase = 'rtmp://puntland-ingest.tenslet.com:1937';
  static const _srtBase = 'srt://puntland-ingest.tenslet.com:8891';

  /// Shaped like the signed token the real server puts in a publish URL, so a
  /// fixture run wraps and truncates the way production does. Not a valid one.
  static const _fixtureToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJzdWIiOiJmaXh0dXJlIiwiYXVkIjoibWVkaWFtdHgtcHVibGlzaCJ9.'
      'ZmlfeHR1cmUtc2lnbmF0dXJlLW5vdC1hLXJlYWwtb25lLXNvLWl0LXdvbnQ';

  /// Publish URLs for one credential on one channel's path, assembled the way
  /// the server assembles them.
  static IngestKeyDto _ingestKey({
    required String channelKey,
    required String id,
    required String label,
    required String username,
    required DateTime createdAt,
    DateTime? lastUsedAt,
  }) => IngestKeyDto(
    id: id,
    label: label,
    username: username,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt,
    rtmpPublishUrl: '$_rtmpBase/$channelKey?user=$username&pass=$_fixtureToken',
    srtPublishUrl:
        '$_srtBase?streamid=publish:$channelKey:$username:$_fixtureToken',
    streamKey: '$channelKey?user=$username&pass=$_fixtureToken',
  );

  /// The channel list's settings, plus the facts about each channel the list
  /// describes it with that are not its broadcast state — when it went off
  /// air, when it was made. What each channel is *doing* lives in
  /// [_broadcasts] and is stamped onto these rows at read time, so the two can
  /// never disagree about whether a channel is on air.
  ///
  /// The five channels of the channel-list design review, one of every shape
  /// the list has to draw: the flagship live with TV and radio, a channel on
  /// air with no signal arriving, one readied but off air, a radio-only
  /// station, and a hidden one that has never been on air.
  late List<ChannelDto> _channels = [
    const ChannelDto(
      key: 'main',
      name: 'Puntland TV',
      position: 0,
      isPublished: true,
      hasTv: true,
      hasRadio: true,
      radioStreamUrl: 'https://radio.pltv.so/live.aac',
      radioStationName: 'Radio Puntland',
      radioFrequencyLabel: '88.5 FM · Garoowe',
      radioStreamHealthy: true,
    ),
    ChannelDto(
      key: 'pltv3',
      name: 'PLTV 3',
      position: 1,
      isPublished: true,
      hasTv: true,
      hasRadio: false,
      onAirSince: _now.subtract(const Duration(minutes: 12)),
      lastFrameAt: _now.subtract(const Duration(minutes: 3, seconds: 12)),
    ),
    ChannelDto(
      key: 'pltv2',
      name: 'PLTV 2',
      position: 2,
      isPublished: true,
      hasTv: true,
      hasRadio: false,
      offAirSince: DateTime(_now.year, _now.month, _now.day - 1, 23, 40),
    ),
    ChannelDto(
      key: 'radio-garowe',
      name: 'Radio Garowe',
      position: 3,
      isPublished: true,
      hasTv: false,
      hasRadio: true,
      radioStreamUrl: 'https://radio.pltv.so/garowe.aac',
      radioStationName: 'Radio Garowe',
      radioFrequencyLabel: '91.2 FM',
      radioOnAirSince: _now.subtract(const Duration(hours: 6, minutes: 12)),
      radioStreamHealthy: true,
    ),
    ChannelDto(
      key: 'sport',
      name: 'PLTV Sport',
      position: 4,
      isPublished: false,
      hasTv: true,
      hasRadio: false,
      createdAt: _now.subtract(const Duration(minutes: 8)),
      neverOnAir: true,
    ),
  ];

  /// Each channel's broadcast state, by key.
  late final Map<String, BroadcastControlDto> _broadcasts = {
    'main': _mainBroadcast,
    // The alarm: the operator has it on air and nothing is arriving, so the
    // readers still watching are looking at a spinner.
    'pltv3': _idleBroadcast(
      'pltv3',
      tvOnAir: true,
      concurrentViewers: 37,
      renditions: const [
        RenditionConfigDto(
          rung: 'source',
          url: 'https://api.pltv.so/hls/pltv3/index.m3u8',
          bitrateKbps: 2400,
          healthy: false,
          enabled: true,
          isProtected: true,
        ),
      ],
      slate: const {
        'so': SlateMessageDto(
          title: 'PLTV 3 ma socoto hadda',
          detail: 'Waxaan dib u bilaabeynaa dhawaan',
        ),
        'en': SlateMessageDto(
          title: 'PLTV 3 is off air',
          detail: 'Back shortly',
        ),
      },
    ),
    'sport': _idleBroadcast('sport'),
    'pltv2': _idleBroadcast(
      'pltv2',
      // Complete in both languages, so its toggle is the one that works.
      slate: const {
        'so': SlateMessageDto(
          title: 'PLTV 2 ma socoto hadda',
          detail: 'Waxaan dib u bilaabeynaa 20:00',
        ),
        'en': SlateMessageDto(
          title: 'PLTV 2 is off air',
          detail: 'Back at 20:00',
        ),
      },
    ),
    'radio-garowe': _idleBroadcast(
      'radio-garowe',
      radioOnAir: true,
      radioListeners: 640,
    ),
  };

  /// A channel with nothing arriving: off air, no ladder, no credentials —
  /// what a channel is the moment it is created.
  static BroadcastControlDto _idleBroadcast(
    String key, {
    bool tvOnAir = false,
    int concurrentViewers = 0,
    bool radioOnAir = false,
    int radioListeners = 0,
    List<RenditionConfigDto> renditions = const [],
    Map<String, SlateMessageDto> slate = const {},
  }) => BroadcastControlDto(
    channelKey: key,
    tvOnAir: tvOnAir,
    radioOnAir: radioOnAir,
    channelName: key,
    uptime: Duration.zero,
    concurrentViewers: concurrentViewers,
    radioListeners: radioListeners,
    renditions: renditions,
    slate: slate,
    ingest: IngestStatusDto(
      isPublishing: false,
      rtmpUrl: _rtmpBase,
      srtUrl: _srtBase,
      path: key,
    ),
  );

  late final BroadcastControlDto _mainBroadcast = BroadcastControlDto(
    channelKey: 'main',
    tvOnAir: true,
    radioOnAir: true,
    channelName: 'Puntland TV',
    uptime: const Duration(hours: 2, minutes: 4),
    concurrentViewers: 4182,
    radioListeners: 1904,
    // One rung, which is what the packager actually publishes: MediaMTX
    // remuxes rather than transcodes, so viewers receive whatever the studio
    // sends and there is nothing to choose between. This used to be a
    // three-rung 1080/720/240 ladder against `cdn.pltv.so` — a shape the
    // backend never had, which made the fixtures a demo of a product rather
    // than of this one.
    //
    // `protected` comes from the server, and with one rung that rung is it:
    // the console cannot offer to disable the only stream there is.
    renditions: const [
      RenditionConfigDto(
        rung: 'source',
        url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
        bitrateKbps: 2600,
        healthy: true,
        enabled: true,
        isProtected: true,
      ),
    ],
    // A real HLS stream, so the preview in a fixture run plays actual video
    // rather than showing a placeholder — the same URL the reader app's
    // fixtures use.
    ingest: IngestStatusDto(
      isPublishing: true,
      protocol: 'rtmp',
      publisher: '10.14.2.31:51884',
      videoLabel: '720p H264',
      rtmpUrl: _rtmpBase,
      srtUrl: _srtBase,
      path: 'main',
    ),
    ingestKeys: [
      _ingestKey(
        channelKey: 'main',
        id: 'key-studio',
        label: 'Studio OBS',
        username: 'studio-obs',
        createdAt: DateTime(2026, 8, 30, 9, 12),
        lastUsedAt: DateTime(2026, 9, 7, 18, 56),
      ),
      // Never used, which is the state the screen has to call out: a studio
      // still configured with the key this one was meant to replace.
      _ingestKey(
        channelKey: 'main',
        id: 'key-backup',
        label: 'Backup encoder',
        username: 'backup-encoder',
        createdAt: DateTime(2026, 9, 6, 14, 2),
      ),
    ],
    // Seeded with only Somali, so the on-air toggle starts blocked and the
    // screen has to explain why. More relevant now, not less: the slate gates
    // going on air as well as off, because a dropped signal shows it with
    // nobody watching.
    slate: const {
      'so': SlateMessageDto(
        title: 'Baahinta ma socoto hadda',
        detail: 'Waxaan dib u bilaabeynaa 18:00',
      ),
    },
  );

  late List<CategoryConfigDto> _categories = const [
    CategoryConfigDto(
      slug: 'national',
      names: {'so': 'Dalka', 'en': 'Puntland'},
      articleCount: 96,
      order: 0,
    ),
    CategoryConfigDto(
      slug: 'infrastructure',
      names: {'so': 'Horumarka', 'en': 'Infrastructure'},
      articleCount: 23,
      order: 1,
    ),
    CategoryConfigDto(
      slug: 'world',
      names: {'so': 'Caalamka', 'en': 'World'},
      articleCount: 61,
      order: 1,
    ),
    CategoryConfigDto(
      slug: 'sport',
      names: {'so': 'Ciyaaraha', 'en': 'Sport'},
      articleCount: 44,
      order: 2,
    ),
    CategoryConfigDto(
      slug: 'economy',
      names: {'so': 'Dhaqaalaha', 'en': 'Economy'},
      articleCount: 38,
      order: 3,
    ),
    // Untranslated on purpose: this is the row that demonstrates a category
    // being hidden from the English tab bar.
    CategoryConfigDto(
      slug: 'education',
      names: {'so': 'Waxbarasho'},
      articleCount: 17,
      order: 4,
    ),
  ];

  /// Each TV channel's day, by key. The flagship's carries the seeded gap and
  /// overlap; PLTV 3's is clean. PLTV 2 has nothing programmed, which is what
  /// its card says.
  late final Map<String, DayScheduleDto> _schedules = {
    'main': _seedSchedule(),
    'pltv3': _seedSecondSchedule(),
  };

  final _pushHistory = <PushHistoryEntryDto>[];

  // ---- Channels ----

  static Failure _refusal(String code) =>
      Failure(kind: FailureKind.unknown, code: code);

  ChannelDto _requireChannel(String key) {
    final channel = _channels.where((c) => c.key == key).firstOrNull;
    if (channel == null) {
      throw const Failure(
        kind: FailureKind.notFound,
        code: ChannelFailureCode.notFound,
      );
    }
    return channel;
  }

  /// The list as the server answers it: settings, with each channel's live
  /// status read from its broadcast state and its now-playing from its
  /// schedule.
  List<ChannelDto> _channelRows() => [
    for (final channel in [
      ..._channels,
    ]..sort((a, b) => a.position.compareTo(b.position)))
      if (_broadcasts[channel.key] case final broadcast?)
        _row(channel, broadcast),
  ];

  ChannelDto _row(ChannelDto channel, BroadcastControlDto broadcast) {
    final live = broadcast.isLiveToReaders;
    final slot = _nowPlaying(channel.key);
    return ChannelDto(
      key: channel.key,
      name: channel.name,
      position: channel.position,
      isPublished: channel.isPublished,
      hasTv: channel.hasTv,
      hasRadio: channel.hasRadio,
      radioStreamUrl: channel.radioStreamUrl,
      radioStationName: channel.radioStationName,
      radioFrequencyLabel: channel.radioFrequencyLabel,
      tvOnAir: broadcast.tvOnAir,
      radioOnAir: broadcast.radioOnAir,
      ingestPublishing: broadcast.ingest.isPublishing,
      concurrentViewers: broadcast.concurrentViewers,
      radioListeners: broadcast.radioListeners,
      // Measured from the uptime the broadcast state carries, so the list
      // and the control room agree about how long the channel has been up.
      liveSince: live ? _now.subtract(broadcast.uptime) : null,
      onAirSince: broadcast.tvOnAir ? channel.onAirSince : null,
      lastFrameAt: broadcast.tvOnAir && !broadcast.ingest.isPublishing
          ? channel.lastFrameAt
          : null,
      offAirSince: broadcast.tvOnAir ? null : channel.offAirSince,
      radioOnAirSince: broadcast.radioOnAir ? channel.radioOnAirSince : null,
      createdAt: channel.createdAt,
      nowPlayingTitle: slot?.title,
      nowPlayingEndsAt: slot?.endsAt,
      hasSchedule: channel.hasTv
          ? (_schedules[channel.key]?.slots.isNotEmpty ?? false)
          : null,
      renditions: [
        for (final rendition in broadcast.renditions)
          RenditionDto(label: rendition.rung, healthy: rendition.healthy),
      ],
      radioStreamHealthy: channel.radioStreamHealthy,
      neverOnAir: channel.neverOnAir,
      previewUrl: live ? broadcast.previewUrl : null,
    );
  }

  /// What is on [key] at the fixture's clock, from its schedule.
  ScheduleSlotDto? _nowPlaying(String key) => _schedules[key]?.ordered
      .where(
        (slot) => !slot.startsAt.isAfter(_now) && slot.endsAt.isAfter(_now),
      )
      .firstOrNull;

  /// One channel's broadcast state with its identity stamped on from the list.
  BroadcastControlDto _control(String key) {
    final channel = _requireChannel(key);
    return _broadcasts[key]!.copyWith(
      channelName: channel.name,
      isPublished: channel.isPublished,
      hasTv: channel.hasTv,
      hasRadio: channel.hasRadio,
      radioStationName: channel.radioStationName,
    );
  }

  @override
  Future<List<ChannelDto>> fetchChannels() => _respond(_channelRows);

  @override
  Future<List<ChannelDto>> createChannel({
    required String key,
    required ChannelSettingsDto settings,
  }) => _respond(() {
    // The same refusals the server makes, so the form's handling of them is
    // exercised by a fixture run rather than discovered against production.
    if (!ChannelDto.keyPattern.hasMatch(key) ||
        key.length > ChannelDto.keyMaxLength) {
      throw const Failure(kind: FailureKind.unknown, code: 'VALIDATION_FAILED');
    }
    if (_channels.any((c) => c.key == key)) {
      throw _refusal(ChannelFailureCode.keyTaken);
    }
    if (settings.isEmpty) throw _refusal(ChannelFailureCode.empty);

    _channels = [
      ..._channels,
      ChannelDto(
        key: key,
        name: settings.name.trim(),
        position: _channels.length,
        isPublished: false,
        hasTv: true,
        hasRadio: false,
      ).copyWith(settings: settings),
    ];
    _broadcasts[key] = _idleBroadcast(key);
    return _channelRows();
  });

  @override
  Future<List<ChannelDto>> updateChannel(
    String key,
    ChannelSettingsDto settings,
  ) => _respond(() {
    final channel = _requireChannel(key);
    final broadcast = _broadcasts[key]!;
    final tvInUse = broadcast.tvOnAir || broadcast.ingest.isPublishing;

    final unpublishing = !settings.isPublished && channel.isPublished;
    final droppingTv = !settings.hasTv && channel.hasTv;
    final droppingRadio = !settings.hasRadio && channel.hasRadio;
    if ((unpublishing || droppingTv) && tvInUse) {
      throw _refusal(ChannelFailureCode.onAir);
    }
    if ((unpublishing || droppingRadio) && broadcast.radioOnAir) {
      throw _refusal(ChannelFailureCode.onAir);
    }
    if (settings.isEmpty) throw _refusal(ChannelFailureCode.empty);

    _channels = [
      for (final row in _channels)
        row.key == key ? row.copyWith(settings: settings) : row,
    ];
    // Radio off follows the stream away, as on the server.
    if (!settings.hasRadio) {
      _broadcasts[key] = broadcast.copyWith(radioOnAir: false);
    }
    return _channelRows();
  });

  @override
  Future<List<ChannelDto>> reorderChannels(List<String> keys) => _respond(() {
    final known = {for (final c in _channels) c.key};
    final given = keys.toSet();
    final complete =
        given.length == keys.length &&
        given.length == known.length &&
        given.containsAll(known);
    if (!complete) throw _refusal(ChannelFailureCode.orderMismatch);

    _channels = [
      for (final channel in _channels)
        channel.copyWith(position: keys.indexOf(channel.key)),
    ];
    return _channelRows();
  });

  @override
  Future<List<ChannelDto>> deleteChannel(String key) => _respond(() {
    _requireChannel(key);
    final broadcast = _broadcasts[key]!;
    if (broadcast.tvOnAir ||
        broadcast.ingest.isPublishing ||
        broadcast.radioOnAir) {
      throw _refusal(ChannelFailureCode.onAir);
    }
    if (_channels.length <= 1) throw _refusal(ChannelFailureCode.last);

    final remaining = _channels.where((c) => c.key != key).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    _channels = [
      for (final (position, channel) in remaining.indexed)
        channel.copyWith(position: position),
    ];
    _broadcasts.remove(key);
    _schedules.remove(key);
    return _channelRows();
  });

  // ---- Operations ----

  @override
  Future<BroadcastControlDto> fetchBroadcastControl(String channelKey) =>
      _respond(() => _control(channelKey));

  @override
  Future<BroadcastControlDto> saveBroadcastControl(
    String channelKey,
    BroadcastControlDto value,
  ) => _respond(() {
    _requireChannel(channelKey);
    _broadcasts[channelKey] = value;
    return _control(channelKey);
  });

  @override
  Future<IngestKeyDto> createIngestKey(
    String channelKey, {
    required String label,
  }) => _respond(() {
    _requireChannel(channelKey);
    // The mint answers with the same shape as every other key, exactly as the
    // real endpoint does: the token in these URLs is derived from the row, so
    // there is nothing shown once for the console to treat differently.
    final username = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final key = _ingestKey(
      channelKey: channelKey,
      id: newId(),
      label: label,
      username: username,
      createdAt: DateTime.now(),
    );
    final broadcast = _broadcasts[channelKey]!;
    _broadcasts[channelKey] = broadcast.copyWith(
      ingestKeys: [...broadcast.ingestKeys, key],
    );
    return key;
  });

  @override
  Future<List<IngestKeyDto>> revokeIngestKey(String channelKey, String id) =>
      _respond(() {
        _requireChannel(channelKey);
        final broadcast = _broadcasts[channelKey]!;
        final remaining = broadcast.ingestKeys
            .where((key) => key.id != id)
            .toList(growable: false);
        _broadcasts[channelKey] = broadcast.copyWith(ingestKeys: remaining);
        return remaining;
      });

  @override
  Future<DayScheduleDto> fetchSchedule(String channelKey, DateTime day) =>
      _respond(() {
        _requireChannel(channelKey);
        return _schedules[channelKey] ??
            DayScheduleDto(
              day: DateTime(_now.year, _now.month, _now.day),
              slots: const [],
            );
      });

  @override
  Future<DayScheduleDto> saveSchedule(
    String channelKey,
    DayScheduleDto schedule,
  ) => _respond(() {
    _requireChannel(channelKey);
    return _schedules[channelKey] = schedule;
  });

  @override
  Future<List<CategoryConfigDto>> fetchCategories() =>
      _respond(() => _categories);

  @override
  Future<List<CategoryConfigDto>> saveCategories(
    List<CategoryConfigDto> categories,
  ) => _respond(() {
    // Upsert by slug, never delete — the real endpoint's contract. The count
    // stays the fixture's own: it is a fact about articles, not a setting the
    // console sends.
    final bySlug = {for (final row in _categories) row.slug: row};
    for (final input in categories) {
      bySlug[input.slug] = CategoryConfigDto(
        slug: input.slug,
        names: {
          for (final MapEntry(:key, :value) in input.names.entries)
            if (value.trim().isNotEmpty) key: value.trim(),
        },
        articleCount: bySlug[input.slug]?.articleCount ?? 0,
        order: input.order,
      );
    }
    return _categories = bySlug.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  });

  @override
  Future<List<CategoryConfigDto>> deleteCategory(String slug) => _respond(() {
    final row = _categories.where((c) => c.slug == slug).firstOrNull;
    if (row == null) {
      throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404');
    }
    if (!row.canDelete) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: CategoryFailureCode.inUse,
      );
    }
    return _categories = _categories
        .where((c) => c.slug != slug)
        .toList(growable: false);
  });

  @override
  Future<PushReachDto> fetchPushReach(Set<String> topics) => _respond(() {
    // Reach scales with how many topics are targeted, and the split reflects
    // the audience: Somali-preference devices are roughly two thirds.
    final base = 12000 + topics.length * 9000;
    return PushReachDto(
      byLocale: {'so': (base * 0.68).round(), 'en': (base * 0.32).round()},
    );
  });

  @override
  Future<List<PushHistoryEntryDto>> fetchPushHistory() => _respond(() {
    if (_pushHistory.isEmpty) {
      _pushHistory.addAll([
        PushHistoryEntryDto(
          id: 'p-1',
          title: 'Wadada weyn oo dib loo furay',
          sentAt: _now.subtract(const Duration(minutes: 2)),
          sentBy: 'A. Yuusuf',
          topic: 'breaking',
          delivered: 38410,
          targeted: 38902,
        ),
        PushHistoryEntryDto(
          id: 'p-2',
          title: 'Jadwalka barnaamijyada toddobaadkan',
          sentAt: _now.subtract(const Duration(hours: 4)),
          sentBy: 'M. Cali',
          topic: 'schedule',
          delivered: 36004,
          targeted: 38902,
        ),
      ]);
    }
    return List.unmodifiable(_pushHistory);
  });

  @override
  Future<PushHistoryEntryDto> sendPush(PushDraftDto draft) => _respond(() {
    // The UI blocks this, but the boundary must not rely on the UI having
    // done so — a half-translated alert is the exact failure this whole
    // feature exists to prevent.
    if (!draft.canSend) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: 'PUSH_INCOMPLETE_LOCALES',
      );
    }

    final entry = PushHistoryEntryDto(
      id: 'p-${_pushHistory.length + 3}',
      title: draft.message('so').title,
      sentAt: DateTime.now(),
      sentBy: 'A. Yuusuf',
      topic: draft.topics.first,
      delivered: 38902,
      targeted: 38902,
    );
    _pushHistory.insert(0, entry);
    return entry;
  });

  // ---- Programmes and episodes ----

  late final _programs = <String, AdminProgramDto>{
    for (final program in _seedPrograms()) program.id: program,
  };

  late final _episodes = <String, AdminEpisodeDto>{
    for (final episode in _seedEpisodes()) episode.id: episode,
  };

  @override
  Future<List<AdminProgramDto>> fetchPrograms() => _respond(() {
    final rows = _programs.values.toList()
      ..sort((a, b) => a.titleFor('so').compareTo(b.titleFor('so')));
    return rows;
  });

  @override
  Future<AdminProgramDto> saveProgram(AdminProgramDto program) => _respond(() {
    // Episode count belongs to the episodes, not to whatever the form posted.
    final saved = program.copyWith(
      episodeCount: _episodes.values
          .where((e) => e.programId == program.id)
          .length,
    );
    _programs[saved.id] = saved;
    return saved;
  });

  @override
  Future<List<AdminEpisodeDto>> fetchEpisodes(String programId) => _respond(() {
    final rows =
        _episodes.values
            .where((e) => e.programId == programId)
            .map(_withLiveSource)
            .toList()
          ..sort((a, b) => b.number.compareTo(a.number));
    return rows;
  });

  /// Re-reads an episode's source from the media store.
  ///
  /// Without this, an episode holds the asset as it looked when the fixture was
  /// seeded, and retrying a failed transcode in the library would leave the
  /// episodes screen still saying it had failed. The claim on
  /// [AdminEpisodeDto.source] is that there is one asset and one truth about
  /// whether it is ready; this is what makes that true rather than decorative.
  AdminEpisodeDto _withLiveSource(AdminEpisodeDto episode) {
    final id = episode.source?.id;
    if (id == null) return episode;
    final live = _media[id];
    return live == null ? episode : episode.copyWith(source: live);
  }

  @override
  Future<AdminEpisodeDto> saveEpisode(AdminEpisodeDto episode) => _respond(() {
    final stored = _episodes[episode.id];
    if (stored == null) {
      throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404');
    }
    // The source is the ingest pipeline's to set, not the form's — the same
    // reason a media save cannot post its own byte size.
    final saved = stored.copyWith(titles: episode.titles);
    _episodes[saved.id] = saved;
    return saved;
  });

  @override
  Future<AdminEpisodeDto> setEpisodeStatus({
    required String id,
    required EpisodeStatus status,
    DateTime? scheduledFor,
  }) => _respond(() {
    final episode = _episodes[id];
    if (episode == null) {
      throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404');
    }

    // Publishing an episode whose transcode is at 62% ships a programme that
    // opens to an error. The UI blocks it; this is why it cannot matter
    // whether the UI did.
    if (status == EpisodeStatus.published && !episode.canPublish) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: ProgramFailureCode.episodeBlocked,
      );
    }

    final updated = episode.copyWith(
      status: status,
      scheduledFor: scheduledFor,
      airedAt: status == EpisodeStatus.published
          ? (episode.airedAt ?? DateTime.now())
          : episode.airedAt,
    );
    _episodes[id] = updated;
    return updated;
  });

  List<AdminProgramDto> _seedPrograms() => [
    AdminProgramDto(
      id: 'evening-news',
      titles: const {'so': 'Warbaahinta Fiidka', 'en': 'Evening News'},
      synopses: const {
        'so': 'Wararka maalinta oo lasoo koobay, maalin kasta 21:00.',
        'en': 'The day\'s news, every evening at 21:00.',
      },
      cadence: ProgramCadence.daily,
      genre: ProgramGenre.news,
      episodeCount: 42,
      updatedAt: _now.subtract(const Duration(hours: 3)),
      artworkUrl: 'https://picsum.photos/seed/pltv-evening/600/600',
      isPublished: true,
    ),
    AdminProgramDto(
      id: 'dood-furan',
      titles: const {'so': 'Dood Furan', 'en': 'Open Debate'},
      synopses: const {'so': 'Dood toos ah oo ku saabsan arrimaha bulshada.'},
      cadence: ProgramCadence.weekly,
      genre: ProgramGenre.debate,
      episodeCount: 18,
      updatedAt: _now.subtract(const Duration(hours: 6)),
      artworkUrl: 'https://picsum.photos/seed/pltv-debate/600/600',
      isPublished: true,
    ),
    AdminProgramDto(
      id: 'suugaan-dhaqan',
      titles: const {'so': 'Suugaan iyo Dhaqan', 'en': 'Poetry and Culture'},
      cadence: ProgramCadence.weekly,
      genre: ProgramGenre.culture,
      episodeCount: 24,
      updatedAt: _now.subtract(const Duration(days: 1)),
      artworkUrl: 'https://picsum.photos/seed/pltv-culture/600/600',
      isPublished: true,
    ),
    // Published with no English title on purpose: this is the row that
    // demonstrates a programme live on the Somali shelf and invisible on the
    // English one.
    AdminProgramDto(
      id: 'barnaamijka-caruurta',
      titles: const {'so': 'Barnaamijka Caruurta'},
      cadence: ProgramCadence.weekly,
      genre: ProgramGenre.kids,
      episodeCount: 9,
      updatedAt: _now.subtract(const Duration(days: 2)),
      isPublished: true,
    ),
    // A draft nobody has finished — untitled in both, and correctly not live.
    AdminProgramDto(
      id: 'ciyaaraha-toddobaadka',
      titles: const {'so': 'Ciyaaraha Toddobaadka'},
      cadence: ProgramCadence.weekly,
      genre: ProgramGenre.sport,
      episodeCount: 0,
      updatedAt: _now.subtract(const Duration(days: 4)),
    ),
  ];

  /// Episodes seeded to cover every blocker at once.
  ///
  /// The two Dood Furan episodes deliberately point at the same media assets
  /// the library seeds as mid-transcode and failed — one asset, one truth about
  /// whether it is ready, visible from both screens.
  List<AdminEpisodeDto> _seedEpisodes() {
    final assets = _media;

    return [
      AdminEpisodeDto(
        id: 'ep-en-42',
        programId: 'evening-news',
        titles: const {'so': 'Warka fiidka', 'en': 'Evening bulletin'},
        number: 42,
        status: EpisodeStatus.published,
        duration: const Duration(minutes: 58),
        source: assets['m-warka-42'],
        airedAt: _now.subtract(const Duration(days: 1)),
      ),
      AdminEpisodeDto(
        id: 'ep-en-41',
        programId: 'evening-news',
        titles: const {'so': 'Warka fiidka', 'en': 'Evening bulletin'},
        number: 41,
        status: EpisodeStatus.published,
        duration: const Duration(minutes: 61),
        airedAt: _now.subtract(const Duration(days: 2)),
        source: assets['m-slate-bed'],
      ),
      // Attached, still transcoding: needs time, not a decision.
      AdminEpisodeDto(
        id: 'ep-df-18',
        programId: 'dood-furan',
        titles: const {'so': 'Dood ku saabsan biyaha', 'en': 'Water debate'},
        number: 18,
        status: EpisodeStatus.draft,
        duration: const Duration(minutes: 48, seconds: 12),
        source: assets['m-dood-18'],
      ),
      // Attached, transcode failed: needs a retry in the media library.
      AdminEpisodeDto(
        id: 'ep-df-17',
        programId: 'dood-furan',
        titles: const {'so': 'Dood ku saabsan waxbarashada'},
        number: 17,
        status: EpisodeStatus.draft,
        duration: const Duration(minutes: 51, seconds: 4),
        source: assets['m-dood-17'],
      ),
      // Nothing attached at all — a different problem, and the screen says so.
      AdminEpisodeDto(
        id: 'ep-df-16',
        programId: 'dood-furan',
        titles: const {'so': 'Dood ku saabsan dhaqaalaha', 'en': 'Economy'},
        number: 16,
        status: EpisodeStatus.draft,
        duration: Duration.zero,
      ),
      AdminEpisodeDto(
        id: 'ep-sd-24',
        programId: 'suugaan-dhaqan',
        titles: const {'so': 'Gabayada Xeebta', 'en': 'Coastal poetry'},
        number: 24,
        status: EpisodeStatus.scheduled,
        duration: const Duration(minutes: 44),
        source: assets['m-gabay-24'],
        scheduledFor: DateTime(_now.year, _now.month, _now.day, 19),
      ),
      AdminEpisodeDto(
        id: 'ep-bc-9',
        programId: 'barnaamijka-caruurta',
        titles: const {'so': 'Sheeko caruur'},
        number: 9,
        status: EpisodeStatus.published,
        duration: const Duration(minutes: 28),
        source: assets['m-slate-bed'],
        airedAt: _now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  // ---- Administration ----

  late StaffDirectoryDto _staffDirectory = StaffDirectoryDto(
    members: [
      StaffMemberDto(
        id: 'u-admin',
        name: 'S. Warsame',
        email: 's.warsame@pltv.so',
        role: ConsoleRole.admin,
        status: StaffStatus.active,
        createdAt: _now.subtract(const Duration(days: 420)),
        lastActiveAt: _now.subtract(const Duration(minutes: 4)),
        twoFactorEnrolled: true,
      ),
      StaffMemberDto(
        id: 'u-editor',
        name: 'A. Yuusuf',
        email: 'a.yuusuf@pltv.so',
        role: ConsoleRole.editor,
        status: StaffStatus.active,
        createdAt: _now.subtract(const Duration(days: 300)),
        lastActiveAt: _now.subtract(const Duration(minutes: 12)),
        twoFactorEnrolled: true,
      ),
      StaffMemberDto(
        id: 'u-journalist',
        name: 'F. Xasan',
        email: 'f.xasan@pltv.so',
        role: ConsoleRole.journalist,
        status: StaffStatus.active,
        createdAt: _now.subtract(const Duration(days: 96)),
        lastActiveAt: _now.subtract(const Duration(hours: 2)),
        twoFactorEnrolled: true,
      ),
      StaffMemberDto(
        id: 'u-ops',
        name: 'M. Cali',
        email: 'm.cali@pltv.so',
        role: ConsoleRole.operations,
        status: StaffStatus.active,
        createdAt: _now.subtract(const Duration(days: 210)),
        lastActiveAt: _now.subtract(const Duration(minutes: 38)),
        twoFactorEnrolled: true,
      ),
      // Invited and never signed in: holds a role, occupies a seat, counts for
      // nothing towards the last-admin rule.
      StaffMemberDto(
        id: 'u-invited-admin',
        name: 'H. Nuur',
        email: 'h.nuur@pltv.so',
        role: ConsoleRole.admin,
        status: StaffStatus.invited,
        createdAt: _now.subtract(const Duration(days: 2)),
      ),
      // No second factor: an account that cannot actually complete a sign-in.
      StaffMemberDto(
        id: 'u-stringer',
        name: 'K. Aadan',
        email: 'k.aadan@pltv.so',
        role: ConsoleRole.journalist,
        status: StaffStatus.active,
        createdAt: _now.subtract(const Duration(days: 21)),
        lastActiveAt: _now.subtract(const Duration(days: 6)),
      ),
      StaffMemberDto(
        id: 'u-former',
        name: 'Z. Faarax',
        email: 'z.faarax@pltv.so',
        role: ConsoleRole.editor,
        status: StaffStatus.suspended,
        createdAt: _now.subtract(const Duration(days: 610)),
        lastActiveAt: _now.subtract(const Duration(days: 74)),
        twoFactorEnrolled: true,
      ),
    ],
  );

  @override
  Future<StaffDirectoryDto> fetchStaffDirectory() =>
      _respond(() => _staffDirectory);

  @override
  Future<StaffMemberDto> setStaffRole({
    required String id,
    required ConsoleRole role,
  }) => _respond(() {
    final member = _requireMember(id);

    // The last-admin half of the rule needs no session: it is a fact about the
    // directory, so the boundary can and does enforce it.
    final losesAdmin =
        member.role == ConsoleRole.admin && role != ConsoleRole.admin;
    if (losesAdmin && _staffDirectory.isLastAdmin(id)) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: StaffFailureCode.lastAdmin,
      );
    }

    final updated = member.copyWith(role: role);
    _staffDirectory = _staffDirectory.withMember(updated);
    return updated;
  });

  @override
  Future<StaffMemberDto> setStaffStatus({
    required String id,
    required StaffStatus status,
  }) => _respond(() {
    final member = _requireMember(id);

    if (status == StaffStatus.suspended && _staffDirectory.isLastAdmin(id)) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: StaffFailureCode.lastAdmin,
      );
    }

    final updated = member.copyWith(status: status);
    _staffDirectory = _staffDirectory.withMember(updated);
    return updated;
  });

  StaffMemberDto _requireMember(String id) {
    final member = _staffDirectory.byId(id);
    if (member == null) {
      throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404');
    }
    return member;
  }

  late ConsoleConfigDto _config = ConsoleConfigDto(
    minimumSupportedBuild: 104,
    currentReleasedBuild: 118,
    locales: [
      // Somali strands the most content, which is the number that makes
      // disabling it a decision rather than a switch.
      LocaleOptionDto(
        code: 'so',
        enabled: true,
        articlesOnlyInThisLocale: _articlesOnlyIn('so'),
      ),
      LocaleOptionDto(
        code: 'en',
        enabled: true,
        articlesOnlyInThisLocale: _articlesOnlyIn('en'),
      ),
    ],
    flags: const [
      FeatureFlagDto(
        key: 'radio_tab',
        enabled: true,
        description: 'Shows the radio destination in the app tab bar.',
      ),
      FeatureFlagDto(
        key: 'vod_downloads',
        enabled: false,
        description: 'Offline episode downloads. Wi-Fi only when on.',
      ),
      FeatureFlagDto(
        key: 'article_comments',
        enabled: false,
        description:
            'Reader comments. Needs moderation staffing before it '
            'goes on.',
      ),
      FeatureFlagDto(
        key: 'breaking_banner',
        enabled: true,
        description: 'In-app breaking banner above the feed.',
      ),
    ],
    updatedAt: _now.subtract(const Duration(days: 5)),
    updatedBy: 'S. Warsame',
  );

  @override
  Future<ConsoleConfigDto> fetchConsoleConfig() => _respond(() => _config);

  @override
  Future<ConsoleConfigDto> saveConsoleConfig(ConsoleConfigDto config) =>
      _respond(() {
        // Both of these lock every reader out of the product, and neither is
        // recoverable from inside the console — the first needs a store
        // release. The UI blocks both; the boundary must not rely on it.
        if (config.minimumSupportedBuild > _config.currentReleasedBuild) {
          throw const Failure(
            kind: FailureKind.unknown,
            code: ConfigFailureCode.floorAboveRelease,
          );
        }
        if (config.enabledLocales.isEmpty) {
          throw const Failure(
            kind: FailureKind.unknown,
            code: ConfigFailureCode.noLocales,
          );
        }

        _config = ConsoleConfigDto(
          minimumSupportedBuild: config.minimumSupportedBuild,
          // Not the client's to move: it is a fact about what shipped.
          currentReleasedBuild: _config.currentReleasedBuild,
          locales: config.locales,
          flags: config.flags,
          dataSaverDefault: config.dataSaverDefault,
          updatedAt: DateTime.now(),
          updatedBy: 'S. Warsame',
        );
        return _config;
      });

  /// Published articles that exist in [locale] and in no other language.
  int _articlesOnlyIn(String locale) => _articles.values
      .where(
        (a) =>
            a.status == ArticleStatus.published &&
            a.translations.containsKey(locale) &&
            a.translations.length == 1,
      )
      .length;

  // ---- Media library ----

  late final _media = <String, MediaAssetDto>{
    for (final asset in _seedMedia()) asset.id: asset,
  };

  @override
  Future<List<MediaAssetDto>> fetchMedia({
    MediaKindFilter filter = MediaKindFilter.all,
    String? query,
  }) => _respond(() {
    var rows = _media.values.toList();

    // The rule filter and the kind filters are the same control in the UI, so
    // they are the same parameter here — but they narrow on different things,
    // and only one of them can be a `kind ==` test.
    if (filter == MediaKindFilter.needsAlt) {
      rows = rows.where((a) => a.blocksPublishing).toList();
    } else if (filter.kind != null) {
      rows = rows.where((a) => a.kind == filter.kind).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final needle = query.trim().toLowerCase();
      rows = rows
          .where(
            (a) =>
                a.filename.toLowerCase().contains(needle) ||
                a.alt.values.any((t) => t.toLowerCase().contains(needle)) ||
                (a.credit ?? '').toLowerCase().contains(needle),
          )
          .toList();
    }

    rows.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return rows;
  });

  @override
  Future<MediaAssetDto> fetchMediaAsset(String id) =>
      _respond(() => _requireAsset(id));

  @override
  Future<MediaAssetDto> saveMediaAsset(MediaAssetDto asset) => _respond(() {
    // Only the newsroom-editable fields are taken from the incoming value.
    // Everything else belongs to the ingest pipeline, and letting a form post
    // a new byte size or a forged usage list would make the delete rule a
    // suggestion.
    final stored = _requireAsset(asset.id);
    final saved = stored.copyWith(alt: asset.alt, credit: asset.credit);
    _media[saved.id] = saved;
    return saved;
  });

  @override
  Future<MediaAssetDto> uploadMedia({
    required String filename,
    required MediaKind kind,
    required int byteSize,
    Uint8List? bytes,
  }) => _respond(() {
    final id = 'm-${_random.nextInt(1 << 32).toRadixString(16)}';
    final asset = MediaAssetDto(
      id: id,
      kind: kind,
      filename: filename,
      url: _fixtureUrl(id, bytes),
      byteSize: byteSize,
      uploadedAt: DateTime.now(),
      uploadedBy: 'A. Yuusuf',
      width: kind == MediaKind.image ? 2048 : null,
      height: kind == MediaKind.image ? 1365 : null,
      // An image is servable the moment it lands; video is not, and pretending
      // otherwise is what produces a programme that will not play.
      processing: kind == MediaKind.image
          ? MediaProcessingState.ready
          : MediaProcessingState.processing,
      transcodeProgress: kind == MediaKind.image ? 1 : 0,
    );
    _media[id] = asset;
    return asset;
  });

  /// Where a fixture upload's bytes live.
  ///
  /// There is no server behind this class, so an asset registered with a real
  /// file has nowhere to be fetched from — `https://cdn.pltv.so/media/…` is a
  /// hostname nobody serves, and a pasted screenshot would render as a broken
  /// box the moment it landed. A `data:` URL is the only form that is true
  /// here: the fixture *is* the storage, so the bytes go in the field that
  /// says where the bytes are.
  ///
  /// **Capped, and the cap is not tidiness.** `ArticleDraft.bodyHtml` re-runs
  /// the delta-to-HTML converter every time it is read; `isDirtyAgainst` reads
  /// it, `isDirty` reads that once per locale, and the editor page asks
  /// `isDirty` on every keystroke. An uncapped megabyte of base64 sitting in
  /// the document puts that megabyte in the typing path — in the only mode
  /// anything is ever demonstrated in. Above the cap the asset falls back to
  /// the unservable URL, which renders as the broken box it honestly is.
  String _fixtureUrl(String id, Uint8List? bytes) {
    const cap = 512 * 1024;
    if (bytes == null || bytes.isEmpty || bytes.length > cap) {
      return 'https://cdn.pltv.so/media/$id';
    }
    final format = ImageFormat.of(bytes);
    if (format == null) return 'https://cdn.pltv.so/media/$id';
    return UriData.fromBytes(bytes, mimeType: format.mimeType).toString();
  }

  @override
  Future<void> deleteMediaAsset(String id) => _respond(() {
    final asset = _requireAsset(id);
    if (!asset.canDelete) {
      throw const Failure(
        kind: FailureKind.unknown,
        code: MediaFailureCode.inUse,
      );
    }
    _media.remove(id);
  });

  @override
  Future<MediaAssetDto> retryMediaIngest(String id) => _respond(() {
    final asset = _requireAsset(id);
    // A retry re-queues; it does not succeed instantly. Showing "ready" here
    // would be the console lying about the pipeline.
    final requeued = asset.copyWith(
      processing: MediaProcessingState.processing,
      transcodeProgress: 0,
    );
    _media[id] = requeued;
    return requeued;
  });

  MediaAssetDto _requireAsset(String id) {
    final asset = _media[id];
    if (asset == null) {
      throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404');
    }
    return asset;
  }

  /// Seeded so every state the library has to render is on screen at once:
  /// a fully described image, one missing English alt, one missing both, a
  /// video mid-transcode, a failed transcode, and an audio bed in use.
  List<MediaAssetDto> _seedMedia() {
    MediaAssetDto image(
      String id,
      String filename, {
      String? so,
      String? en,
      String? credit,
      int minutesAgo = 0,
      int byteSize = 840 * 1024,
      int width = 2048,
      int height = 1365,
      List<MediaUsageDto> usedIn = const [],
    }) => MediaAssetDto(
      id: id,
      kind: MediaKind.image,
      filename: filename,
      url: 'https://cdn.pltv.so/media/$id.jpg',
      thumbnailUrl: 'https://cdn.pltv.so/media/$id-thumb.jpg',
      byteSize: byteSize,
      uploadedAt: _now.subtract(Duration(minutes: minutesAgo)),
      uploadedBy: _staff[0].name,
      alt: {'so': ?so, 'en': ?en},
      credit: credit,
      width: width,
      height: height,
      usedIn: usedIn,
    );

    return [
      image(
        'm-highway',
        'wadada-weyn-2026-08.jpg',
        so: 'Wadada weyn ee Boosaaso oo dib loo furay, gawaari ku socda',
        en: 'Traffic moving on the reopened Bosaso highway',
        credit: 'PLTV / M. Cali',
        minutesAgo: 38,
        usedIn: const [
          MediaUsageDto(
            articleId: 'a-road',
            title: 'Wadada weyn oo dib loo furay',
            isPublished: false,
          ),
        ],
      ),
      // Described in Somali only: the state the library exists to surface.
      // The editor's gate would let this publish, because an alt string does
      // exist — it is just not the reader's language.
      image(
        'm-school',
        'dugsiga-sare-furitaan.jpg',
        so: 'Ardayda dugsiga sare oo fasalka gudaha ah maalinta furitaanka',
        minutesAgo: 96,
        credit: 'PLTV',
        usedIn: const [
          MediaUsageDto(
            articleId: 'a-schools',
            title: 'Dugsiyada sare oo bilaabay sannad dugsiyeedka cusub',
            isPublished: true,
          ),
        ],
      ),
      // Undescribed entirely — how every upload starts.
      image(
        'm-livestock',
        'suuqa-xoolaha-galkacyo.jpg',
        minutesAgo: 14,
        byteSize: 3 * 1024 * 1024,
        credit: 'F. Xasan',
      ),
      image(
        'm-rain',
        'roobab-gobolka-bari.jpg',
        so: 'Roobab ku da\'aya waddo ciid ah oo gobolka bari ah',
        en: 'Rain falling on a dirt road in the eastern region',
        credit: 'Reuters',
        minutesAgo: 210,
        byteSize: 1240 * 1024,
      ),
      MediaAssetDto(
        id: 'm-dood-18',
        kind: MediaKind.video,
        filename: 'dood-furan-ep18.mp4',
        url: 'https://cdn.pltv.so/media/m-dood-18.m3u8',
        thumbnailUrl: 'https://cdn.pltv.so/media/m-dood-18-poster.jpg',
        byteSize: 1840 * 1024 * 1024,
        uploadedAt: _now.subtract(const Duration(minutes: 22)),
        uploadedBy: _staff[2].name,
        width: 1920,
        height: 1080,
        duration: const Duration(minutes: 48, seconds: 12),
        processing: MediaProcessingState.processing,
        transcodeProgress: 0.62,
      ),
      // The failed ingest the overview screen already counts. Same event, two
      // surfaces — the counter says how many, this says which and why.
      MediaAssetDto(
        id: 'm-dood-17',
        kind: MediaKind.video,
        filename: 'dood-furan-ep17.mp4',
        url: 'https://cdn.pltv.so/media/m-dood-17.m3u8',
        byteSize: 2100 * 1024 * 1024,
        uploadedAt: _now.subtract(const Duration(hours: 5)),
        uploadedBy: _staff[2].name,
        width: 1920,
        height: 1080,
        duration: const Duration(minutes: 51, seconds: 4),
        processing: MediaProcessingState.failed,
        transcodeProgress: 0.34,
        failureReason: 'Transcode 240p failed — source audio track missing.',
      ),
      MediaAssetDto(
        id: 'm-warka-42',
        kind: MediaKind.video,
        filename: 'warka-fiidka-42.mp4',
        url: 'https://cdn.pltv.so/media/m-warka-42.m3u8',
        thumbnailUrl: 'https://cdn.pltv.so/media/m-warka-42-poster.jpg',
        byteSize: 1620 * 1024 * 1024,
        uploadedAt: _now.subtract(const Duration(days: 1)),
        uploadedBy: _staff[2].name,
        width: 1920,
        height: 1080,
        duration: const Duration(minutes: 58),
      ),
      MediaAssetDto(
        id: 'm-gabay-24',
        kind: MediaKind.video,
        filename: 'suugaan-gabayada-xeebta.mp4',
        url: 'https://cdn.pltv.so/media/m-gabay-24.m3u8',
        thumbnailUrl: 'https://cdn.pltv.so/media/m-gabay-24-poster.jpg',
        byteSize: 1180 * 1024 * 1024,
        uploadedAt: _now.subtract(const Duration(hours: 9)),
        uploadedBy: _staff[2].name,
        width: 1920,
        height: 1080,
        duration: const Duration(minutes: 44),
      ),
      MediaAssetDto(
        id: 'm-slate-bed',
        kind: MediaKind.audio,
        filename: 'continuity-bed-loop.m4a',
        url: 'https://cdn.pltv.so/media/m-slate-bed.m4a',
        byteSize: 2 * 1024 * 1024,
        uploadedAt: _now.subtract(const Duration(days: 3)),
        uploadedBy: _staff[2].name,
        duration: const Duration(minutes: 2, seconds: 30),
      ),
    ];
  }

  DayScheduleDto _seedSchedule() {
    final day = DateTime(_now.year, _now.month, _now.day);
    ScheduleSlotDto at(
      String id,
      String title,
      int hour,
      int minute,
      int minutes, {
      String? genre,
      bool live = false,
      bool repeat = false,
    }) => ScheduleSlotDto(
      id: id,
      title: title,
      startsAt: DateTime(day.year, day.month, day.day, hour, minute),
      duration: Duration(minutes: minutes),
      genre: genre,
      isLive: live,
      isRepeat: repeat,
    );

    // Seeded with one gap and one overlap, matching the canvas — the screen's
    // job is to surface them, so the fixture has to contain them.
    return DayScheduleDto(
      day: day,
      slots: [
        at('s1', 'Barnaamijka Caruurta', 18, 0, 30, genre: 'Kids'),
        at('s2', 'Suugaan iyo Dhaqan', 19, 0, 60, genre: 'Culture'),
        at(
          's3',
          'Wararka Duhurnimo (repeat)',
          20,
          0,
          60,
          genre: 'News',
          repeat: true,
        ),
        at('s4', 'Warbaahinta Fiidka', 21, 0, 60, genre: 'News', live: true),
        at('s5', 'Dood Furan', 22, 0, 60, genre: 'Debate'),
        at('s6', 'Wararka Habeenkii', 22, 30, 30, genre: 'News'),
      ],
    );
  }

  /// PLTV 2's evening: different programmes over the same hours as the
  /// flagship, and clean — no gap, no overlap.
  DayScheduleDto _seedSecondSchedule() {
    final day = DateTime(_now.year, _now.month, _now.day);
    ScheduleSlotDto at(
      String id,
      String title,
      int hour,
      int minute,
      int minutes, {
      String? genre,
      bool live = false,
    }) => ScheduleSlotDto(
      id: id,
      title: title,
      startsAt: DateTime(day.year, day.month, day.day, hour, minute),
      duration: Duration(minutes: minutes),
      genre: genre,
      isLive: live,
    );

    return DayScheduleDto(
      day: day,
      slots: [
        at('p1', 'Ciyaaraha Maanta', 19, 0, 60, genre: 'Sport'),
        at('p2', 'Wararka PLTV 2', 20, 0, 30, genre: 'News', live: true),
        at('p3', 'Diinta iyo Nolosha', 20, 30, 60, genre: 'Religion'),
      ],
    );
  }

  void _seed() {
    final now = _now;

    void add({
      required String id,
      required ArticleStatus status,
      required String so,
      String? en,
      required String category,
      required ConsoleUser author,
      int minutesAgo = 0,
      bool breaking = false,
      DateTime? scheduledFor,
      // Minutes by which the English version trails the Somali one. Non-zero
      // seeds the "translation behind" state the editor has to surface.
      int englishBehindMinutes = 0,
    }) {
      final editedAt = now.subtract(Duration(minutes: minutesAgo));
      _articles[id] = AdminArticleDto(
        id: id,
        status: status,
        translations: {
          'so': ArticleTranslationDto(
            title: so,
            bodyHtml: '<p>$so</p>',
            updatedAt: editedAt,
            updatedBy: author.name,
          ),
          if (en != null)
            'en': ArticleTranslationDto(
              title: en,
              bodyHtml: '<p>$en</p>',
              updatedAt: editedAt.subtract(
                Duration(minutes: englishBehindMinutes),
              ),
              updatedBy: author.name,
            ),
        },
        categorySlug: category,
        slug: _slug(so, id),
        authorId: author.id,
        authorName: author.name,
        updatedAt: now.subtract(Duration(minutes: minutesAgo)),
        scheduledFor: scheduledFor,
        publishedAt: status == ArticleStatus.published
            ? now.subtract(Duration(minutes: minutesAgo))
            : null,
        isBreaking: breaking,
      );
    }

    final editor = _staff[0];
    final journalist = _staff[1];

    add(
      id: 'a-rains',
      status: ArticleStatus.scheduled,
      so: 'Saadaasha hawada: roobab culus gobolada bariga',
      en: 'Heavy rains forecast for the eastern regions',
      category: 'national',
      author: editor,
      minutesAgo: 12,
      englishBehindMinutes: 90,
      scheduledFor: DateTime(now.year, now.month, now.day, 21, 30),
    );
    add(
      id: 'a-road',
      status: ArticleStatus.inReview,
      so: 'Wadada weyn oo dib loo furay',
      category: 'infrastructure',
      author: journalist,
      minutesAgo: 40,
      breaking: true,
    );
    add(
      id: 'a-football',
      status: ArticleStatus.draft,
      so: 'Tartanka kubbadda cagta ee gobolada',
      en: 'Regional football tournament kicks off Monday',
      category: 'sport',
      author: journalist,
      minutesAgo: 90,
    );
    add(
      id: 'a-schools',
      status: ArticleStatus.published,
      so: 'Dugsiyada sare oo bilaabay sannad dugsiyeedka cusub',
      en: 'Secondary schools begin the new academic year',
      category: 'education',
      author: editor,
      minutesAgo: 180,
    );
    add(
      id: 'a-drainage',
      status: ArticleStatus.published,
      so: 'Shaqooyinka biyo-mareenka oo dhammaaday saddex degmo',
      category: 'national',
      author: editor,
      minutesAgo: 300,
    );
    add(
      id: 'a-livestock',
      status: ArticleStatus.published,
      so: 'Qiimaha suuqa xoolaha oo deggan',
      en: 'Livestock market prices steady',
      category: 'economy',
      author: journalist,
      minutesAgo: 420,
    );
  }

  /// Used by the seeded ids when a new article is created in the editor.
  String newId() => 'a-${_random.nextInt(1 << 32).toRadixString(16)}';
}
