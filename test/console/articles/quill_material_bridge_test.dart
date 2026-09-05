import 'package:flutter/material.dart' as sdk;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/quill_material_bridge.dart';
import 'package:puntland/core/l10n/generated/app_localizations.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/theme/app_theme.dart';

/// Why [QuillMaterialBridge] exists, pinned.
///
/// Flutter 3.47 moved Material out of the SDK. This app draws from
/// `package:material_ui`; `flutter_quill` still reads
/// `package:flutter/material.dart`. The two are separate copies of the same
/// library, so inherited widgets published by one are invisible to the other.
///
/// The dangerous half of that is silent: `Theme.of` falls back to defaults and
/// the editor merely renders in the wrong colours. The half that bites is
/// `MaterialLocalizations`, which throws — but only when the text-selection
/// toolbar is first shown, which no amount of typing in a test will reach.
/// These tests reach it directly.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('so'),
    supportedLocales: const [Locale('en', 'US'), Locale('so')],
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      // The same delegate list the console ships, in the same order: Somali is
      // not one of the locales Flutter bundles, so ours go first.
      AppL10n.delegate,
      SoMaterialLocalizations.delegate,
      SoCupertinoLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(body: child),
  );

  testWidgets('the app tree alone does not satisfy the SDK Material lookups', (
    tester,
  ) async {
    Object? withoutBridge;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            try {
              sdk.MaterialLocalizations.of(context);
            } catch (error) {
              withoutBridge = error;
            }
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      withoutBridge,
      isNotNull,
      reason: 'if this ever passes, material_ui and the SDK have converged '
          'and the bridge can go',
    );
  });

  testWidgets('the bridge adds to the app’s localizations, never replaces them', (
    tester,
  ) async {
    late AppL10n app;
    late MaterialLocalizations appMaterial;

    await tester.pumpWidget(
      host(
        QuillMaterialBridge(
          child: Builder(
            builder: (context) {
              // `material_ui`'s, and the app's own — both still in scope.
              app = AppL10n.of(context);
              appMaterial = MaterialLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    // A bare `Localizations` here replaces the delegates rather than merging
    // them, which took `AppL10n` away from everything inside the editor. The
    // first embed builder to ask for a string got a null-check failure where
    // an image should have been.
    expect(app.saveDraft, isNotEmpty);
    expect(appMaterial.copyButtonLabel, 'Koobi');
  });

  testWidgets('inside the bridge, the SDK lookups resolve', (tester) async {
    late sdk.MaterialLocalizations localizations;
    late sdk.ThemeData theme;

    await tester.pumpWidget(
      host(
        QuillMaterialBridge(
          child: Builder(
            builder: (context) {
              localizations = sdk.MaterialLocalizations.of(context);
              theme = sdk.Theme.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    // The selection toolbar's labels — the exact thing that used to throw.
    // And in Somali, not English: `sdk.DefaultMaterialLocalizations` declines
    // every locale but `en`, so a bridge built on it would leave a Somali
    // console with no SDK localisations at all.
    expect(localizations.copyButtonLabel, 'Koobi');
    expect(localizations.cutButtonLabel, 'Goo');
    expect(localizations.pasteButtonLabel, 'Dhaji');
    expect(localizations.selectAllButtonLabel, 'Dhammaan dooro');

    // And the console's own colours, not `ThemeData.fallback()`'s.
    expect(theme.colorScheme.primary, AppTheme.light().colorScheme.primary);
  });

  testWidgets('a Quill editor renders and accepts text in the app tree', (
    tester,
  ) async {
    final controller = QuillController.basic();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      host(QuillMaterialBridge(child: QuillEditor.basic(controller: controller))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QuillEditor), findsOneWidget);

    controller.document.insert(0, 'Saadaasha hawada');
    await tester.pumpAndSettle();

    expect(controller.document.toPlainText().trim(), 'Saadaasha hawada');
  });

  testWidgets('the bridge paints no surface of its own', (tester) async {
    // The console draws the field's border and fill; a second opaque Material
    // underneath them washes the ground out by a shade.
    await tester.pumpWidget(
      host(const QuillMaterialBridge(child: SizedBox())),
    );

    final material = tester.widget<sdk.Material>(
      find.descendant(
        of: find.byType(QuillMaterialBridge),
        matching: find.byType(sdk.Material),
      ),
    );
    expect(material.type, sdk.MaterialType.transparency);
  });
}
