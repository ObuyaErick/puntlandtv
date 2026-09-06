import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_body_editor.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_embeds.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_html.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/theme/app_theme.dart';

/// Embeds in the body.
///
/// `QuillEditor` does not degrade when it meets an embeddable it has no builder
/// for: `_getEmbedBuilder` throws mid-build, Flutter substitutes an
/// `ErrorWidget`, and `RenderEditor` refuses that as a child. The failure
/// reaches the journalist as an assertion about render object types filling the
/// space where their article was. Inserting one image URL did exactly that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<QuillController> pumpEditor(
    WidgetTester tester, {
    String? bodyHtml,
  }) async {
    final controller = QuillController(
      document: articleHtmlToDocument(bodyHtml),
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);

    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        supportedLocales: const [Locale('en', 'US'), Locale('so')],
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppL10n.delegate,
          SoMaterialLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: ArticleBodyEditor(controller: controller, locale: 'so'),
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  testWidgets('an image in the body renders instead of throwing', (t) async {
    await pumpEditor(
      t,
      bodyHtml: '<p>Roobab.</p><img src="https://cdn.pltv.so/hero.jpg">',
    );

    expect(t.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('inserting an image keeps the editor alive', (t) async {
    final controller = await pumpEditor(t, bodyHtml: '<p>Roobab.</p>');

    controller.replaceText(
      0,
      0,
      BlockEmbed.image('https://cdn.pltv.so/hero.jpg'),
      const TextSelection.collapsed(offset: 1),
    );
    await t.pump();

    // The bug: this threw `UnimplementedError` during build, and the editor
    // was replaced by a RenderErrorBox assertion.
    expect(t.takeException(), isNull);
    expect(find.byType(ArticleBodyEditor), findsOneWidget);
  });

  testWidgets('a pasted image renders from its bytes, not over the network', (
    t,
  ) async {
    // A fixture upload hands back a `data:` URL — it is the storage, so the
    // bytes go where the bytes are. `Image.network` cannot open one on the VM,
    // where `NetworkImage` goes through `HttpClient` and the test harness
    // answers 400 to everything, so an image the operator can plainly see in a
    // browser would be a broken box in every test that looks at one.
    clearInlineImageCache();
    await pumpEditor(t, bodyHtml: '<p>Roobab.</p><img src="$_dataUrl">');

    expect(t.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
    expect(t.widget<Image>(find.byType(Image)).image, isA<MemoryImage>());
  });

  testWidgets('a pasted image is decoded once, not once per frame', (t) async {
    // `MemoryImage` keys Flutter's image cache by list identity, so re-parsing
    // the URI on each build re-decodes the picture every frame — for every
    // pasted image, while someone is typing.
    clearInlineImageCache();
    await pumpEditor(t, bodyHtml: '<img src="$_dataUrl">');

    final first = t.widget<Image>(find.byType(Image)).image;
    await t.pump();
    final second = t.widget<Image>(find.byType(Image)).image;

    expect((first as MemoryImage).bytes, same((second as MemoryImage).bytes));
  });

  testWidgets('a placeholder is shown while a paste is still uploading', (
    t,
  ) async {
    final controller = await pumpEditor(t, bodyHtml: '<p>Roobab.</p>');

    controller.replaceText(
      0,
      0,
      const PendingImageEmbed('paste-0'),
      const TextSelection.collapsed(offset: 1),
    );
    await t.pump();

    expect(t.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('an embed with no builder costs one line, not the article', (
    t,
  ) async {
    final controller = await pumpEditor(t, bodyHtml: '<p>Roobab.</p>');

    controller.replaceText(
      0,
      0,
      const BlockEmbed('video', 'https://cdn.pltv.so/clip.mp4'),
      const TextSelection.collapsed(offset: 1),
    );
    await t.pump();

    expect(t.takeException(), isNull);
    // The prose either side of it is still there and still editable.
    expect(find.byType(QuillEditor), findsOneWidget);
    expect(controller.document.toPlainText(), contains('Roobab.'));
  });

  group('round trip', () {
    test('an image survives HTML → document → HTML', () {
      const html = '<p>Roobab.</p><img src="https://cdn.pltv.so/hero.jpg">';
      final once = documentToArticleHtml(articleHtmlToDocument(html));

      expect(once, contains('src="https://cdn.pltv.so/hero.jpg"'));
      // And is stable, like every other tag in the vocabulary.
      expect(documentToArticleHtml(articleHtmlToDocument(once)), once);
    });

    test('an image with no src is dropped rather than stored empty', () {
      final doc = articleHtmlToDocument('<p>Roobab.</p><img src="">');
      expect(documentToArticleHtml(doc), isNot(contains('<img')));
    });
  });
}

/// A 1x1 PNG as a `data:` URL — what a fixture upload hands back.
const _dataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAf'
    'FcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
