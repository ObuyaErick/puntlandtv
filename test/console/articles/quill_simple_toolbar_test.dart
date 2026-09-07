import 'package:flutter/material.dart' as sdk;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/quill_material_bridge.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/theme/app_theme.dart';

/// `QuillSimpleToolbar` under the console's own localisation setup.
///
/// This is the shape the browser actually runs in, and it differs from the
/// other editor tests in the one way that matters: the locale is Somali, which
/// `flutter_quill` does not ship translations for. Anything that resolves only
/// for English passes an `en` test and fails the moment an editor is working in
/// the language most of this newsroom writes in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host({required Locale locale, required Widget child}) => MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    supportedLocales: const [Locale('en', 'US'), Locale('so')],
    // The console's list, in the console's order — see `console_app.dart`.
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      AppL10n.delegate,
      SoMaterialLocalizations.delegate,
      SoCupertinoLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(body: child),
  );

  for (final locale in const [Locale('so'), Locale('en', 'US')]) {
    testWidgets('the simple toolbar builds in ${locale.languageCode}', (
      t,
    ) async {
      final controller = QuillController.basic();
      addTearDown(controller.dispose);

      t.view.physicalSize = const Size(2400, 1600);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);

      await t.pumpWidget(
        host(
          locale: locale,
          child: QuillMaterialBridge(
            child: Column(
              children: [
                QuillSimpleToolbar(
                  controller: controller,
                  config: const QuillSimpleToolbarConfig(),
                ),
                Expanded(child: QuillEditor.basic(controller: controller)),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      // `QuillToolbarLinkStyleButton` is the one that reported the original
      // failure, because it is the first button to ask for MaterialLocalizations.
      expect(t.takeException(), isNull);
      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
    });
  }

  /// The two lookups every `flutter_quill` widget makes, checked either side
  /// of the bridge — in Somali, which is where both of them used to fail.
  testWidgets('quill’s lookups resolve inside the bridge and not outside', (
    t,
  ) async {
    FlutterQuillLocalizations? insideQuill;
    Object? outsideQuill;
    sdk.MaterialLocalizations? insideMaterial;
    Object? outsideMaterial;

    await t.pumpWidget(
      host(
        locale: const Locale('so'),
        child: Column(
          children: [
            // Outside: the arrangement `ArticleBodyEditor` had while its
            // toolbar was ours and needed none of this. A `QuillSimpleToolbar`
            // here is a *sibling* of the bridge, so it never enters the scope
            // — and no amount of adding delegates to the bridge reaches it.
            Builder(
              builder: (context) {
                outsideQuill = FlutterQuillLocalizations.of(context);
                try {
                  sdk.MaterialLocalizations.of(context);
                } catch (error) {
                  outsideMaterial = error;
                }
                return const SizedBox();
              },
            ),
            QuillMaterialBridge(
              child: Builder(
                builder: (context) {
                  insideQuill = FlutterQuillLocalizations.of(context);
                  insideMaterial = sdk.MaterialLocalizations.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );

    // Inside: both resolve, in a locale flutter_quill does not ship. Without
    // the fallback delegate its own delegate declines `so`, is dropped from
    // the scope, and every toolbar button throws while asking for a tooltip.
    expect(insideQuill, isNotNull);
    expect(insideMaterial, isNotNull);

    // Outside: neither. This is the invariant `ArticleBodyEditor` encodes by
    // wrapping the whole Column rather than only the editing surface.
    expect(outsideQuill, isNull);
    expect(
      outsideMaterial,
      isNotNull,
      reason:
          'if this stops throwing, flutter_quill has moved to material_ui '
          'and the bridge can go',
    );
  });
}
