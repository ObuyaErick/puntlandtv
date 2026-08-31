import 'dart:math';

import '../../../core/error/failure.dart';
import '../../features/auth/domain/entities/console_user.dart';
import 'dto/admin_article_dto.dart';
import 'dto/broadcast_dto.dart';
import 'dto/newsroom_summary_dto.dart';
import 'dto/push_dto.dart';
import 'dto/schedule_dto.dart';
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
