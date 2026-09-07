import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_paste.dart';

/// What a paste is allowed to become.
///
/// The expensive mistake this suite exists to prevent is **reading ordinary
/// prose as markdown**. Markdown folds a soft line break into a space, so text
/// wrongly converted comes back with its lines merged — two sentences run
/// together in published copy, which is the same failure the HTML converter
/// sets `multiLineParagraph: false` to avoid. Every negative case below is a
/// sentence a Somali journalist could plausibly paste.
void main() {
  String textOf(ArticlePasteAction action) {
    final delta = (action as InsertPastedDelta).delta;
    return delta
        .toList()
        .where((op) => op.isInsert && op.data is String)
        .map((op) => op.data as String)
        .join();
  }

  List<Map<String, dynamic>> opsOf(ArticlePasteAction action) =>
      (action as InsertPastedDelta).delta.toJson().cast<Map<String, dynamic>>();

  group('markdown detection · yes', () {
    test('a heading', () {
      expect(looksLikeMarkdown('# Digniin roobaad'), isTrue);
      expect(looksLikeMarkdown('### Gobolada'), isTrue);
    });

    test('a quote', () {
      expect(looksLikeMarkdown('> Waa arrin culus, ayuu yiri.'), isTrue);
    });

    test('a fenced block', () {
      expect(looksLikeMarkdown('```\nkow\n```'), isTrue);
    });

    test('two bullets in a row', () {
      expect(looksLikeMarkdown('- Nugaal\n- Bari\n- Karkaar'), isTrue);
    });

    test('two numbered items in a row', () {
      expect(looksLikeMarkdown('1. Kow\n2. Labo'), isTrue);
    });

    test('two inline markers', () {
      expect(
        looksLikeMarkdown(
          'Waxaa **la sheegay** in [warbixinta](https://pltv.so) la daabacay.',
        ),
        isTrue,
      );
    });
  });

  group('markdown detection · no', () {
    test('a single dashed line is dialogue, not a list', () {
      // The reason list markers need a second item: this is how attribution
      // and asides are written, and converting it merges it into whatever
      // follows.
      expect(looksLikeMarkdown('- Waa runtaa, ayuu yiri wasiirku.'), isFalse);
    });

    test('a hash with no space is a tag, not a heading', () {
      expect(looksLikeMarkdown('#Puntland waa gobol.'), isFalse);
    });

    test('one bold run is not enough', () {
      expect(looksLikeMarkdown('Waxaa jira **hal** eray oo xoogan.'), isFalse);
    });

    test('plain prose across several lines', () {
      expect(
        looksLikeMarkdown(
          'Roobab culus ayaa ka da\'ay gobolka Nugaal.\n'
          'Dadka deggan ayaa laga codsaday inay taxaddaraan.',
        ),
        isFalse,
      );
    });

    test('something far too large to be an article', () {
      expect(looksLikeMarkdown('# ${'x' * 200000}'), isFalse);
    });
  });

  group('markdown conversion', () {
    test('headings, emphasis, lists and links all arrive', () {
      final action = decidePaste(
        plainText:
            '## Digniin\n\n'
            'Waxaa **la sheegay** in [warbixinta](https://pltv.so) la daabacay.\n\n'
            '- Nugaal\n'
            '- Bari\n',
      );

      expect(action, isA<InsertPastedDelta>());
      expect((action as InsertPastedDelta).wasReformatted, isTrue);

      final ops = opsOf(action);
      expect(
        ops,
        contains(
          equals({
            'insert': '\n',
            'attributes': {'header': 2},
          }),
        ),
      );
      expect(
        ops,
        contains(
          equals({
            'insert': 'la sheegay',
            'attributes': {'bold': true},
          }),
        ),
      );
      expect(
        ops,
        contains(
          equals({
            'insert': 'warbixinta',
            'attributes': {'link': 'https://pltv.so'},
          }),
        ),
      );
      expect(
        ops.where((op) => op['attributes']?['list'] == 'bullet'),
        hasLength(2),
      );
    });

    test('a markdown heading above h3 is flattened, not dropped', () {
      final action = decidePaste(plainText: '# Kow\n\n> Labo\n');
      expect(
        opsOf(action),
        contains(
          equals({
            'insert': '\n',
            'attributes': {'header': 2},
          }),
        ),
      );
    });

    test('raw HTML in markdown meets the same rules as pasted HTML', () {
      // GitHub-flavoured markdown passes HTML through, so it reaches the same
      // parser a browser paste does — and the same drop list. A journalist
      // gets bold from `<strong>`; nobody gets a script into a story.
      final action = decidePaste(
        plainText:
            '# Digniin\n\n'
            'Waxaa <strong>la sheegay</strong> <script>alert(1)</script>.\n',
      );

      expect(textOf(action), isNot(contains('alert')));
      expect(textOf(action), isNot(contains('script')));
      expect(
        opsOf(action),
        contains(
          equals({
            'insert': 'la sheegay',
            'attributes': {'bold': true},
          }),
        ),
      );
    });
  });

  group('order of preference', () {
    test('HTML wins over markdown-looking plain text', () {
      // Every rich source puts both flavours on the clipboard, and the HTML is
      // what the source actually meant.
      final action = decidePaste(
        html: '<p>Warbixin <strong>degdeg</strong> ah.</p>',
        plainText: '# Warbixin\n\n- kow\n- labo',
      );

      expect((action as InsertPastedDelta).wasReformatted, isFalse);
      expect(textOf(action), contains('Warbixin degdeg ah.'));
      expect(textOf(action), isNot(contains('#')));
    });

    test('image bytes win over the HTML that came with them', () {
      // A browser's "copy image" puts both on the clipboard. Taking the HTML
      // would hotlink someone else's server from a published story.
      final action = decidePaste(
        html: '<img src="https://example.com/a.png">',
        imageBytes: _png,
      );

      expect(action, isA<UploadPastedImage>());
      expect((action as UploadPastedImage).bytes, _png);
    });

    test('a stylesheet does not count as content', () {
      // What Word puts on the clipboard when only a picture was copied. If the
      // HTML branch claimed it, the paste would insert nothing at all.
      final action = decidePaste(
        html:
            '<html><head><style>p{margin:0}</style></head><body></body></html>',
        plainText: 'Roobab culus ayaa da\'ay.',
      );
      expect(action, isA<PasteNotHandled>());
    });
  });

  group('declining', () {
    test('ordinary prose is left to the ordinary paste', () {
      // Which is also what keeps copying *inside* the editor working: Flutter
      // puts only plain text on the system clipboard, so an internal copy
      // reaches here as prose and falls through to flutter_quill, which
      // restores the styles and embeds from the delta it kept.
      expect(
        decidePaste(plainText: 'Roobab culus ayaa ka da\'ay Nugaal.'),
        isA<PasteNotHandled>(),
      );
    });

    test('an empty clipboard', () {
      expect(decidePaste(), isA<PasteNotHandled>());
      expect(decidePaste(html: '', plainText: ''), isA<PasteNotHandled>());
    });
  });
}

/// The smallest valid PNG, so the format sniffer has something real to read.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);
