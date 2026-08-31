import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/admin_api/dto/admin_article_dto.dart';

/// The translation-linking rule the editor is built around: a translation is
/// "behind" when its own text is older than the source language's.
void main() {
  final now = DateTime(2026, 8, 31, 21, 12);

  AdminArticleDto article({
    required Duration englishBehind,
    bool withEnglish = true,
  }) => AdminArticleDto(
    id: 'a-1',
    status: ArticleStatus.draft,
    sourceLocale: 'so',
    translations: {
      'so': ArticleTranslationDto(
        title: 'Saadaasha hawada',
        updatedAt: now,
        bodyHtml: '<p>${'word ' * 412}</p>',
      ),
      if (withEnglish)
        'en': ArticleTranslationDto(
          title: 'Weather forecast',
          updatedAt: now.subtract(englishBehind),
        ),
    },
    categorySlug: 'puntland',
    authorId: 'u-1',
    authorName: 'F. Xasan',
    updatedAt: now,
  );

  group('staleness', () {
    test('a translation edited before the source is stale', () {
      final a = article(englishBehind: const Duration(minutes: 90));

      expect(a.staleLocales, ['en']);
      expect(a.hasStaleTranslation, isTrue);
    });

    test('a translation edited alongside the source is current', () {
      final a = article(englishBehind: Duration.zero);

      expect(a.staleLocales, isEmpty);
      expect(a.hasStaleTranslation, isFalse);
    });

    test('the source language is never its own stale translation', () {
      final a = article(englishBehind: const Duration(hours: 5));

      expect(
        a.staleLocales,
        isNot(contains('so')),
        reason: 'the source cannot lag behind itself',
      );
    });

    test('a single-language article is untranslated, not stale', () {
      final a = article(englishBehind: Duration.zero, withEnglish: false);

      expect(a.isUntranslated, isTrue);
      expect(
        a.hasStaleTranslation,
        isFalse,
        reason:
            'nothing to be behind — the row should read "no translation", '
            'which is a different problem with a different fix',
      );
    });

    test('re-confirming clears the flag', () {
      final a = article(englishBehind: const Duration(minutes: 90));
      final source = a.translations['so']!;

      final reconfirmed = a.copyWith(
        translations: {
          ...a.translations,
          'en': a.translations['en']!.copyWith(updatedAt: source.updatedAt),
        },
      );

      expect(reconfirmed.staleLocales, isEmpty);
    });
  });

  group('locale ordering and summary', () {
    test('somali reads first, being the majority publishing language', () {
      final a = article(englishBehind: Duration.zero);
      expect(a.locales, ['so', 'en']);
    });
  });

  group('derived reading time', () {
    test('counts words in the body, ignoring markup', () {
      final translation = article(englishBehind: Duration.zero)
          .translations['so']!;

      expect(translation.wordCount, 412);
      expect(translation.readingMinutes, 3);
    });

    test('never reports zero minutes for a short article', () {
      final short = ArticleTranslationDto(
        title: 't',
        updatedAt: now,
        bodyHtml: '<p>Three words here</p>',
      );
      expect(short.readingMinutes, 1);
    });
  });
}
