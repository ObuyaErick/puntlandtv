import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_html.dart';

/// The body is stored as HTML and edited as a Quill document, so every save is
/// a round trip. These tests are the contract that trip is held to: the second
/// pass must equal the first, or a story drifts a little every time somebody
/// opens it.
void main() {
  String roundTrip(String html) =>
      documentToArticleHtml(articleHtmlToDocument(html));

  group('round trip', () {
    test('consecutive paragraphs keep their break', () {
      // The bug that cost `flutter_quill_delta_from_html` its place here: this
      // came back as one paragraph reading `One.Two.`
      expect(roundTrip('<p>One.</p><p>Two.</p>'), '<p>One.</p><p>Two.</p>');
    });

    test('inline emphasis survives', () {
      const html = '<p>Dadka <strong>deggan</strong> oo <em>ay</em> tahay.</p>';
      expect(roundTrip(html), html);
    });

    test('headings, quotes and lists survive', () {
      const html = '<h2>Digniin</h2>'
          '<h3>Gobolada</h3>'
          '<blockquote>Diyaargarowga hortiisa roobka.</blockquote>'
          '<ul><li>Mid</li><li>Labo</li></ul>'
          '<ol><li>Kow</li></ol>';
      expect(roundTrip(html), html);
    });

    test('links keep their href and gain nothing else', () {
      const html = '<p><a href="https://pltv.so">Warbixin</a></p>';
      expect(roundTrip(html), html);
      expect(roundTrip(html), isNot(contains('target')));
    });

    test('a second pass changes nothing', () {
      const html = '<p>Roobab.</p><h2>Digniin</h2><p>Dadka.</p>'
          '<blockquote>Hadal.</blockquote><ul><li>Mid</li></ul>';
      final once = roundTrip(html);
      expect(roundTrip(once), once);
      // And a third, because the failure mode being guarded is accumulation.
      expect(roundTrip(roundTrip(once)), once);
    });

    test('source formatting is not content', () {
      // Newlines and indentation between block tags must not become blank
      // paragraphs in the story.
      expect(
        roundTrip('<p>One.</p>\n\n  <p>Two.</p>\n'),
        '<p>One.</p><p>Two.</p>',
      );
    });

    test('entities decode once and re-encode once', () {
      expect(roundTrip('<p>Sanadka 2026 &amp; 2027</p>'),
          '<p>Sanadka 2026 &amp; 2027</p>');
    });
  });

  group('empty bodies', () {
    test('a null body opens as an empty document, not a failure', () {
      expect(isArticleDocumentEmpty(articleHtmlToDocument(null)), isTrue);
    });

    test('an empty document serialises to nothing at all', () {
      // Not `<p><br></p>` — that is a body, and it would satisfy every
      // "has this been written yet" check between here and the app.
      expect(documentToArticleHtml(articleHtmlToDocument(null)), '');
      expect(documentToArticleHtml(articleHtmlToDocument('   ')), '');
    });
  });

  group('unparseable markup', () {
    test('keeps the words when it cannot keep the formatting', () {
      final doc = articleHtmlToDocument('<p>Roobab <weird>culus</weird>.</p>');
      expect(doc.toPlainText(), contains('Roobab'));
      expect(doc.toPlainText(), contains('culus'));
    });
  });

  group('counting', () {
    test('word count ignores markup', () {
      expect(articleHtmlWordCount('<p>Mid <strong>labo</strong> saddex</p>'), 3);
      expect(articleHtmlWordCount(null), 0);
    });

    test('reading time floors at one minute', () {
      expect(articleReadingMinutes(0), 1);
      expect(articleReadingMinutes(412), 3);
    });
  });
}
