import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/core/domain/page.dart';
import 'package:puntland/core/error/failure.dart';
import 'package:puntland/core/providers/repository_providers.dart';
import 'package:puntland/features/news/domain/entities/article.dart';
import 'package:puntland/features/news/domain/repositories/news_repository.dart';
import 'package:puntland/features/news/presentation/controllers/news_controllers.dart';
import 'package:riverpod/riverpod.dart';

/// A repository that never touches a network.
///
/// The fact that this is ~30 lines and needs no HTTP mock, no `Dio` adapter and
/// no JSON is the practical payoff of the layering: the controller depends on
/// an interface, so the test substitutes a plain Dart object.
class FakeNewsRepository implements NewsRepository {
  FakeNewsRepository({this.failOnCursor});

  /// When set, requesting this cursor throws — used to prove that a failed
  /// *additional* page does not discard the pages already loaded.
  final String? failOnCursor;

  int articleCalls = 0;

  @override
  Future<List<NewsCategory>> categories() async => const [
    NewsCategory(slug: 'top', name: 'Top news', isDefault: true),
  ];

  @override
  Future<Page<ArticleSummary>> articles({
    String? categorySlug,
    String? cursor,
  }) async {
    articleCalls++;
    if (cursor != null && cursor == failOnCursor) {
      throw const Failure(kind: FailureKind.timeout, code: 'NETWORK_TIMEOUT');
    }
    final start = int.tryParse(cursor ?? '0') ?? 0;
    return Page<ArticleSummary>(
      items: List.generate(2, (i) => _article('a${start + i}')),
      nextCursor: start >= 4 ? null : '${start + 2}',
    );
  }

  @override
  Future<Article> article(String slug) async =>
      Article(summary: _article(slug), bodyHtml: '<p>body</p>');

  @override
  Future<List<ArticleSummary>> related(List<String> slugs) async =>
      slugs.map(_article).toList();

  ArticleSummary _article(String slug) => ArticleSummary(
    slug: slug,
    title: 'Title $slug',
    categorySlug: 'top',
    categoryName: 'Top news',
    publishedAt: DateTime(2026, 8, 30),
    contentLanguage: 'so',
  );
}

void main() {
  ProviderContainer containerWith(FakeNewsRepository repo) {
    final container = ProviderContainer(
      overrides: [newsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('loads the first page', () async {
    final container = containerWith(FakeNewsRepository());
    final state = await container.read(feedProvider('top').future);

    expect(state.items, hasLength(2));
    expect(state.hasMore, isTrue);
  });

  test('loadMore appends rather than replaces', () async {
    final container = containerWith(FakeNewsRepository());
    await container.read(feedProvider('top').future);

    await container.read(feedProvider('top').notifier).loadMore();

    final state = container.read(feedProvider('top')).value!;
    expect(state.items, hasLength(4));
    expect(state.items.map((a) => a.slug), [
      'a0',
      'a1',
      'a2',
      'a3',
    ], reason: 'pages must concatenate in order, with no duplicates');
  });

  test('concurrent loadMore calls are coalesced into one request', () async {
    final repo = FakeNewsRepository();
    final container = containerWith(repo);
    await container.read(feedProvider('top').future);
    final callsAfterFirstPage = repo.articleCalls;

    final notifier = container.read(feedProvider('top').notifier);
    await Future.wait([
      notifier.loadMore(),
      notifier.loadMore(),
      notifier.loadMore(),
    ]);

    expect(
      repo.articleCalls - callsAfterFirstPage,
      1,
      reason:
          'a scroll listener fires repeatedly; without guarding, the same '
          'page loads several times and rows duplicate',
    );
  });

  test('a failed next page keeps the pages already loaded', () async {
    final container = containerWith(FakeNewsRepository(failOnCursor: '2'));
    await container.read(feedProvider('top').future);

    await container.read(feedProvider('top').notifier).loadMore();

    final state = container.read(feedProvider('top')).value;
    expect(state, isNotNull, reason: 'the feed must not blank out');
    expect(state!.items, hasLength(2));
    expect(state.loadMoreError?.code, 'NETWORK_TIMEOUT');
    expect(state.loadingMore, isFalse);
  });
}
