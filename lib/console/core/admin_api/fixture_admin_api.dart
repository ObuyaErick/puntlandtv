import 'dart:math';

import '../../../core/error/failure.dart';
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
        if (refreshToken == null ||
            !refreshToken.startsWith(_tokenPrefix)) {
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
      throw const Failure(
        kind: FailureKind.unknown,
        code: 'VALIDATION_FAILED',
      );
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
      onAir: OnAirDto(
        isLive: true,
        programmeTitle: 'Warbaahinta Fiidka',
        elapsed: const Duration(hours: 2, minutes: 4),
        renditions: const [
          RenditionDto(label: '1080p', healthy: true),
          RenditionDto(label: '720p', healthy: true),
          RenditionDto(label: '240p', healthy: true),
        ],
        concurrentViewers: 4182,
        radioOnAir: true,
      ),
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

  @override
  Future<List<AdminArticleDto>> fetchArticles({
    ArticleStatusFilter status = ArticleStatusFilter.all,
    String? authorId,
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
  Future<AdminArticleDto> saveArticle(AdminArticleDto article) => _respond(() {
    final saved = article.copyWith();
    _articles[saved.id] = saved;
    return saved;
  });

  @override
  Future<AdminArticleDto> setArticleStatus({
    required String id,
    required ArticleStatus status,
    DateTime? scheduledFor,
  }) => _respond(() {
    final article = _articles[id];
    if (article == null) {
      throw const Failure(kind: FailureKind.notFound, code: 'HTTP_404');
    }
    final updated = article.copyWith(
      status: status,
      scheduledFor: scheduledFor,
      publishedAt: status == ArticleStatus.published ? DateTime.now() : null,
    );
    _articles[id] = updated;
    return updated;
  });

  @override
  Future<void> deleteArticle(String id) => _respond(() {
    _articles.remove(id);
  });

  @override
  Future<List<ConsoleUser>> fetchStaff() => _respond(() => _staff);

  // ---- Operations ----

  late BroadcastControlDto _broadcast = BroadcastControlDto(
    tvOnAir: true,
    radioOnAir: true,
    channelName: 'Puntland TV — main',
    uptime: const Duration(hours: 2, minutes: 4),
    concurrentViewers: 4182,
    radioListeners: 1904,
    renditions: const [
      RenditionConfigDto(
        rung: '1080p',
        url: 'https://cdn.pltv.so/live/1080/index.m3u8',
        bitrateKbps: 4500,
        healthy: true,
        enabled: true,
      ),
      RenditionConfigDto(
        rung: '720p',
        url: 'https://cdn.pltv.so/live/720/index.m3u8',
        bitrateKbps: 2200,
        healthy: true,
        enabled: true,
      ),
      RenditionConfigDto(
        rung: '240p',
        url: 'https://cdn.pltv.so/live/240/index.m3u8',
        bitrateKbps: 420,
        healthy: true,
        enabled: true,
      ),
    ],
    // Seeded with only Somali, so the off-air toggle starts blocked and the
    // screen has to explain why.
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

  late DayScheduleDto _schedule = _seedSchedule();

  final _pushHistory = <PushHistoryEntryDto>[];

  @override
  Future<BroadcastControlDto> fetchBroadcastControl() =>
      _respond(() => _broadcast);

  @override
  Future<BroadcastControlDto> saveBroadcastControl(BroadcastControlDto value) =>
      _respond(() => _broadcast = value);

  @override
  Future<DayScheduleDto> fetchSchedule(DateTime day) =>
      _respond(() => _schedule);

  @override
  Future<DayScheduleDto> saveSchedule(DayScheduleDto schedule) =>
      _respond(() => _schedule = schedule);

  @override
  Future<List<CategoryConfigDto>> fetchCategories() =>
      _respond(() => _categories);

  @override
  Future<List<CategoryConfigDto>> saveCategories(
    List<CategoryConfigDto> categories,
  ) => _respond(() => _categories = categories);

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
  }) => _respond(() {
    final id = 'm-${_random.nextInt(1 << 32).toRadixString(16)}';
    final asset = MediaAssetDto(
      id: id,
      kind: kind,
      filename: filename,
      url: 'https://cdn.pltv.so/media/$id',
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
