import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/core/api/fixture_puntland_api.dart';
import 'package:puntland/core/api/puntland_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PuntlandApi apiFor(String language) =>
      FixturePuntlandApi(languageCode: () => language, latency: Duration.zero);

  test('serves content in the requested language', () async {
    final english = await apiFor('en').fetchCategories();
    final somali = await apiFor('so').fetchCategories();

    expect(english.first.name, 'Top news');
    expect(somali.first.name, 'Wararka ugu sarreeya');

    expect(
      english.map((c) => c.slug),
      somali.map((c) => c.slug),
      reason:
          'slugs are the stable key and must not vary by locale — only '
          'display names are localised',
    );
  });

  test('paginates by cursor and stops at the end', () async {
    final api = apiFor('en');
    final first = await api.fetchArticles(limit: 3);

    expect(first.data, hasLength(3));
    expect(first.nextCursor, isNotNull);

    final second = await api.fetchArticles(cursor: first.nextCursor, limit: 3);
    expect(
      second.data.map((a) => a.slug),
      isNot(anyElement(isIn(first.data.map((a) => a.slug)))),
      reason: 'pages must not overlap',
    );

    var page = second;
    var guard = 0;
    while (page.nextCursor != null && guard++ < 10) {
      page = await api.fetchArticles(cursor: page.nextCursor, limit: 3);
    }
    expect(page.nextCursor, isNull, reason: 'pagination must terminate');
  });

  test('filters by category', () async {
    final sport = await apiFor('en').fetchArticles(categorySlug: 'sport');
    expect(sport.data, isNotEmpty);
    expect(sport.data.every((a) => a.categorySlug == 'sport'), isTrue);
  });

  test('resolves relative timestamps so fixtures do not rot', () async {
    final page = await apiFor('en').fetchArticles(limit: 1);
    final published = page.data.first.publishedAt;
    final age = DateTime.now().difference(published);

    expect(
      age.inMinutes,
      lessThan(60),
      reason:
          'the lead story is authored as {{now-12m}} and must resolve '
          'relative to now, or every story reads "6 months ago" within a week',
    );
    expect(age.isNegative, isFalse);
  });

  test('an article carries its own content language', () async {
    final article = await apiFor('so')
        .fetchArticle('heavy-rains-forecast-eastern-regions');
    expect(article.contentLocale, 'so');
    expect(article.bodyHtml, contains('<p>'));
    expect(article.relatedSlugs, isNot(contains(article.slug)));
  });

  test('a missing article is a not-found failure, not a crash', () async {
    expect(
      () => apiFor('en').fetchArticle('does-not-exist'),
      throwsA(
        isA<Object>().having((e) => e.toString(), 'code', contains('HTTP_404')),
      ),
    );
  });
}
