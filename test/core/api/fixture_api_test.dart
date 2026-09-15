import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/core/api/fixture_puntland_api.dart';
import 'package:puntland/core/api/puntland_api.dart';
import 'package:puntland/core/error/failure.dart';

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

  group('channels', () {
    test('lists every channel with the same keys in both languages', () async {
      final english = await apiFor('en').fetchChannels();
      final somali = await apiFor('so').fetchChannels();

      expect(english.map((c) => c.key), ['main', 'pltv2', 'radio-garowe']);
      expect(
        somali.map((c) => c.key),
        english.map((c) => c.key),
        reason: 'a channel key is a route segment and must not vary by locale',
      );

      final garowe = english.last;
      expect(garowe.hasTv, isFalse);
      expect(garowe.hasRadio, isTrue);
    });

    test('live and radio are served per channel', () async {
      final api = apiFor('en');

      final main = await api.fetchLiveStatus('main');
      final pltv2 = await api.fetchLiveStatus('pltv2');
      expect(main.channelKey, 'main');
      expect(pltv2.channelKey, 'pltv2');
      expect(main.isLive, isTrue);
      expect(pltv2.isLive, isFalse);

      final garowe = await api.fetchRadioStatus('radio-garowe');
      expect(garowe.channelKey, 'radio-garowe');
    });

    test('an unknown key is CHANNEL_NOT_FOUND', () async {
      final api = apiFor('en');

      expect(
        () => api.fetchLiveStatus('does-not-exist'),
        throwsA(
          isA<Failure>()
              .having((f) => f.kind, 'kind', FailureKind.notFound)
              .having((f) => f.code, 'code', 'CHANNEL_NOT_FOUND'),
        ),
      );
      expect(
        () => api.fetchRadioStatus('does-not-exist'),
        throwsA(isA<Failure>()),
      );
    });

    test('a medium the channel does not carry is not found too', () async {
      final api = apiFor('en');

      // Radio-only has no live row; TV-only has no radio row. The API answers
      // both with the same 404.
      expect(
        () => api.fetchLiveStatus('radio-garowe'),
        throwsA(isA<Failure>()),
      );
      expect(() => api.fetchRadioStatus('pltv2'), throwsA(isA<Failure>()));
    });
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
