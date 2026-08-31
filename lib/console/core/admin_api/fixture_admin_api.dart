import 'dart:math';

import '../../../core/error/failure.dart';
import '../../features/auth/domain/entities/console_user.dart';
import 'dto/admin_article_dto.dart';
import 'dto/newsroom_summary_dto.dart';
import 'puntland_admin_api.dart';

/// [PuntlandAdminApi] over an in-memory store.
///
/// Writes are kept in memory for the session, so the console genuinely works:
/// an article saved here comes back changed, and Phase 6 wires this same store
/// to the reader app's fixtures so publishing in the console makes the story
/// appear in the app.
class FixtureAdminApi implements PuntlandAdminApi {
  FixtureAdminApi({this.latency = const Duration(milliseconds: 350)}) {
    _seed();
  }

  final Duration latency;

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

  void _seed() {
    final now = DateTime.now();

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
    }) {
      _articles[id] = AdminArticleDto(
        id: id,
        status: status,
        translations: {
          'so': ArticleTranslationDto(title: so, bodyHtml: '<p>$so</p>'),
          if (en != null)
            'en': ArticleTranslationDto(title: en, bodyHtml: '<p>$en</p>'),
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
      category: 'puntland',
      author: editor,
      minutesAgo: 12,
      scheduledFor: DateTime(now.year, now.month, now.day, 21, 30),
    );
    add(
      id: 'a-road',
      status: ArticleStatus.inReview,
      so: 'Wadada weyn oo dib loo furay',
      category: 'puntland',
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
      category: 'puntland',
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
