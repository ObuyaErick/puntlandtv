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
      const html =
          '<h2>Digniin</h2>'
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
      const html =
          '<p>Roobab.</p><h2>Digniin</h2><p>Dadka.</p>'
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
      expect(
        roundTrip('<p>Sanadka 2026 &amp; 2027</p>'),
        '<p>Sanadka 2026 &amp; 2027</p>',
      );
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

  group('pasted markup', () {
    // Everything here arrives from a clipboard and never from a body this
    // editor wrote, which is why none of it was caught by the round trip
    // above — and why all of it reached a story before this group existed.

    List<Map<String, dynamic>> ops(String html) =>
        articleHtmlToDelta(html).toJson().cast<Map<String, dynamic>>();

    String text(String html) => articleHtmlToDocument(html).toPlainText();

    test('a stylesheet is not prose', () {
      // What Word and Google Docs actually put on the clipboard. This used to
      // arrive as a paragraph of CSS above the story.
      const html =
          '<html><head><style>p.MsoNormal{margin:0;font-size:11pt}</style>'
          '</head><body><p>Roobab culus.</p></body></html>';

      expect(text(html), isNot(contains('MsoNormal')));
      expect(text(html), isNot(contains('font-size')));
      expect(text(html), contains('Roobab culus.'));
    });

    test('a script is not prose either', () {
      const html = '<div><script>alert(1)</script><p>Warbixin.</p></div>';
      expect(text(html), isNot(contains('alert')));
      expect(text(html), contains('Warbixin.'));
    });

    test('h1 becomes h2 and h5 becomes h3', () {
      // The body has two heading levels on purpose — see kArticleTags. A
      // pasted heading outside them used to land as an ordinary paragraph,
      // losing the fact that it was a heading at all.
      expect(
        ops('<h1>Digniin</h1>'),
        contains(
          equals({
            'insert': '\n',
            'attributes': {'header': 2},
          }),
        ),
      );
      expect(
        ops('<h5>Gobolada</h5>'),
        contains(
          equals({
            'insert': '\n',
            'attributes': {'header': 3},
          }),
        ),
      );
    });

    test('a table degrades to one line per cell, not one line total', () {
      const html =
          '<table><tbody>'
          '<tr><td>Gobol</td><td>Roob</td></tr>'
          '<tr><td>Nugaal</td><td>12mm</td></tr>'
          '</tbody></table>';

      expect(text(html).trim().split('\n'), [
        'Gobol',
        'Roob',
        'Nugaal',
        '12mm',
      ]);
    });

    test('a break inside a quote leaves both halves quoted', () {
      // The `<br>` used to be emitted as a bare newline inside the line's
      // runs, and a newline with no block style ends an unquoted line — so
      // the first half of the quote silently stopped being a quote.
      final quoted = ops('<blockquote>Kow<br>Labo</blockquote>')
          .where((op) => op['attributes']?['blockquote'] == true);

      expect(quoted, hasLength(2));
    });

    test('an image inside a paragraph gets a line of its own', () {
      // A Quill embed cannot share a line with text, and the paste path
      // composes its delta without the rules that would otherwise fix that.
      final delta = ops('<p>Sawir:<img src="https://cdn.pltv.so/a.png"></p>');
      final embed = delta.indexWhere((op) => op['insert'] is Map);

      expect(embed, greaterThan(0));
      expect(delta[embed - 1]['insert'], endsWith('\n'));
      expect(delta[embed + 1]['insert'], startsWith('\n'));
    });
  });

  group('pasting at a caret', () {
    test('a plain paragraph brings no trailing newline', () {
      // The document already owns the newline the caret sits on. A second one
      // splits the host paragraph and leaves a blank line behind — the
      // failure this library was written to prevent, through another door.
      expect(articlePasteDelta('<p>Roobab.</p>').toJson(), [
        {'insert': 'Roobab.'},
      ]);
    });

    test('two paragraphs keep the break between them', () {
      expect(articlePasteDelta('<p>Kow.</p><p>Labo.</p>').toJson(), [
        {'insert': 'Kow.\nLabo.'},
      ]);
    });

    test('a trailing heading keeps the newline its style lives on', () {
      // Dropping it would drop the heading: Quill carries a block style on
      // the newline that ends the line, not on its text.
      expect(articlePasteDelta('<h2>Digniin</h2>').toJson(), [
        {'insert': 'Digniin'},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
      ]);
    });

    test('an empty paste inserts nothing at all', () {
      // Not even the newline `articleHtmlToDelta` has to end a *document*
      // with: there is no document here, only something to compose into one.
      expect(articlePasteDelta('').toJson(), isEmpty);
    });
  });

  group('counting', () {
    test('word count ignores markup', () {
      expect(
        articleHtmlWordCount('<p>Mid <strong>labo</strong> saddex</p>'),
        3,
      );
      expect(articleHtmlWordCount(null), 0);
    });

    test('reading time floors at one minute', () {
      expect(articleReadingMinutes(0), 1);
      expect(articleReadingMinutes(412), 3);
    });
  });
}
