import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/articles/presentation/pages/article_editor_page.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_body_editor.dart';
import 'package:puntland/console/features/articles/presentation/widgets/editor_locale_tabs.dart';
import 'package:puntland/console/features/articles/presentation/widgets/hero_image_panel.dart';
import 'package:puntland/console/features/articles/presentation/widgets/publishing_panel.dart';
import 'package:puntland/console/features/articles/presentation/widgets/translation_panel.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedInAs extends AuthController {
  _SignedInAs(this.role);

  final ConsoleRole role;

  @override
  AuthState build() => SignedIn(
    ConsoleUser(
      id: 'u-editor',
      name: 'A. Yuusuf',
      email: 'a@pltv.so',
      role: role,
    ),
  );
}

/// The editor screen, against the canvas it was drawn from
/// (`ARTICLE EDITOR · BILINGUAL MODEL · 1440×1240`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester, {
    String id = 'a-rains',
    ConsoleRole role = ConsoleRole.editor,
    Size size = const Size(1440, 1240),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => _SignedInAs(role)),
          adminApiProvider.overrideWithValue(
            FixtureAdminApi(latency: Duration.zero),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          supportedLocales: const [Locale('en', 'US'), Locale('so')],
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppL10n.delegate,
            SoMaterialLocalizations.delegate,
            SoCupertinoLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: ArticleEditorPage(articleId: id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the canvas layout', () {
    testWidgets('shows the composer and all three metadata cards', (t) async {
      await pump(t);

      expect(find.byType(EditorLocaleTabs), findsOneWidget);
      expect(find.byType(ArticleBodyEditor), findsOneWidget);
      expect(find.byType(TranslationPanel), findsOneWidget);
      expect(find.byType(HeroImagePanel), findsOneWidget);
      expect(find.byType(PublishingPanel), findsOneWidget);
    });

    testWidgets('the toolbar carries the article vocabulary and no more', (
      t,
    ) async {
      await pump(t);
      final l10n = await AppL10n.delegate.load(const Locale('en', 'US'));

      for (final control in [
        l10n.formatBold,
        l10n.formatItalic,
        l10n.formatHeading2,
        l10n.formatHeading3,
      ]) {
        expect(find.byTooltip(control), findsOneWidget, reason: control);
      }

      // No H1: the headline is the story's only first-level heading.
      expect(find.text('H1'), findsNothing);
    });

    testWidgets('lays out at 1440 with no overflow', (t) async {
      await pump(t);
      expect(takeOverflows(), isEmpty);
    });

    testWidgets('lays out at compact with no overflow', (t) async {
      await pump(t, size: const Size(390, 844));
      expect(takeOverflows(), isEmpty);
    });
  });

  group('locale tabs', () {
    testWidgets('mark the source language and the one that is behind', (
      t,
    ) async {
      await pump(t);
      final l10n = await AppL10n.delegate.load(const Locale('en', 'US'));

      expect(find.text(l10n.badgeSource), findsOneWidget);
      expect(find.text(l10n.badgeBehind), findsOneWidget);
    });

    testWidgets('switching language re-hydrates the fields', (t) async {
      await pump(t);

      const somali = 'Saadaasha hawada: roobab culus gobolada bariga';
      const english = 'Heavy rains forecast for the eastern regions';
      expect(find.text(somali), findsWidgets);

      await t.tap(find.text('English'));
      await t.pumpAndSettle();

      expect(find.text(english), findsWidgets);
      // And the language just left is gone from the fields. Reusing the
      // composer's State across a tab switch would leave the Somali headline
      // sitting under an `EN` label — and save it as the English one.
      expect(find.text(somali), findsNothing);
    });
  });

  group('side by side', () {
    testWidgets('opens two composers and closes back to one', (t) async {
      await pump(t);
      final l10n = await AppL10n.delegate.load(const Locale('en', 'US'));
      expect(find.byType(ArticleBodyEditor), findsOneWidget);

      await t.tap(find.text(l10n.sideBySide));
      await t.pumpAndSettle();
      expect(find.byType(ArticleBodyEditor), findsNWidgets(2));

      await t.tap(find.text(l10n.exitSideBySide));
      await t.pumpAndSettle();
      expect(find.byType(ArticleBodyEditor), findsOneWidget);
    });
  });

  group('publishing gates', () {
    testWidgets('a journalist is offered review, never publish', (t) async {
      await pump(t, role: ConsoleRole.journalist);
      final l10n = await AppL10n.delegate.load(const Locale('en', 'US'));

      expect(find.text(l10n.submitForReview), findsOneWidget);
      expect(find.text(l10n.publishNow), findsNothing);
    });

    testWidgets('a journalist cannot act on their own published story', (
      t,
    ) async {
      // Every move out of `published` is an unpublish, and the backend needs
      // the publish right for all of them. An enabled button here would be a
      // 403 the journalist could not have predicted.
      await pump(t, id: 'a-schools', role: ConsoleRole.journalist);
      final l10n = await AppL10n.delegate.load(const Locale('en', 'US'));

      final submit = t.widget<FilledButton>(
        find.ancestor(
          of: find.text(l10n.submitForReview),
          matching: find.byType(FilledButton),
        ),
      );
      expect(submit.onPressed, isNull);
      expect(find.byTooltip(l10n.unpublishNeedsEditor), findsOneWidget);
    });

    testWidgets('publish is refused while the body is empty, and says why', (
      t,
    ) async {
      // `a-road` has a one-line seeded body; empty it to reach the gate.
      await pump(t, id: 'a-road');
      final l10n = await AppL10n.delegate.load(const Locale('en', 'US'));

      // Through the controller, not the document: typing goes via
      // `replaceText`, and that is the path that notifies the screen.
      final editor = t.widget<ArticleBodyEditor>(
        find.byType(ArticleBodyEditor),
      );
      editor.controller.replaceText(
        0,
        editor.controller.document.length - 1,
        '',
        const TextSelection.collapsed(offset: 0),
      );
      await t.pumpAndSettle();

      final publish = t.widget<FilledButton>(
        find.ancestor(
          of: find.text(l10n.publishNow),
          matching: find.byType(FilledButton),
        ),
      );
      expect(publish.onPressed, isNull);
      expect(find.byTooltip(l10n.bodyRequired), findsOneWidget);
    });
  });

  group('editing', () {
    testWidgets('typing in the body updates the running word count', (t) async {
      await pump(t, id: 'a-football');

      final editor = t.widget<ArticleBodyEditor>(
        find.byType(ArticleBodyEditor),
      );
      final before = editor.controller.document.toPlainText().trim().isEmpty
          ? 0
          : editor.controller.document
                .toPlainText()
                .trim()
                .split(RegExp(r'\s+'))
                .length;

      editor.controller.replaceText(
        0,
        0,
        'mid labo saddex afar shan ',
        const TextSelection.collapsed(offset: 26),
      );
      await t.pumpAndSettle();

      expect(find.textContaining('${before + 5} words'), findsOneWidget);
    });
  });

  group('the autosave switch', () {
    /// Opens the header's overflow menu, which is where the switch lives.
    Future<void> openMenu(WidgetTester t) async {
      await t.tap(find.byIcon(Icons.more_vert_rounded).first);
      await t.pumpAndSettle();
    }

    testWidgets('is on when the editor opens, and reachable at any width', (
      t,
    ) async {
      // The menu used to appear only on a narrow header, where it carried
      // Preview and Save draft. A switch you can reach only by shrinking the
      // window is not a switch, so it is always there now.
      await pump(t, id: 'a-football');
      await openMenu(t);

      final checkbox = t.widget<CheckboxMenuButton>(
        find.byType(CheckboxMenuButton),
      );
      expect(checkbox.value, isTrue);
    });

    testWidgets('turning it off says so where the save state is read', (
      t,
    ) async {
      await pump(t, id: 'a-football');
      expect(find.textContaining('Autosave off'), findsNothing);

      await openMenu(t);
      await t.tap(find.byType(CheckboxMenuButton));
      await t.pumpAndSettle();

      // The line that otherwise reads "Saved 21:12" — the one someone glances
      // at to decide whether their work is safe.
      expect(find.textContaining('Autosave off'), findsOneWidget);
    });

    testWidgets('turning it off stops the debounce from writing', (t) async {
      await pump(t, id: 'a-football');
      await openMenu(t);
      await t.tap(find.byType(CheckboxMenuButton));
      await t.pumpAndSettle();

      final body = t.widget<ArticleBodyEditor>(find.byType(ArticleBodyEditor));
      body.controller.replaceText(
        0,
        0,
        'Waa qoraal cusub ',
        const TextSelection.collapsed(offset: 17),
      );
      // Comfortably past the two-second debounce.
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();

      expect(find.textContaining('Autosave off'), findsOneWidget);
      expect(
        find.text('Saving…'),
        findsNothing,
        reason: 'nothing should have gone out on its own',
      );
    });
  });
}

/// Layout errors raised while the frame was built, drained so one failure does
/// not cascade into the next test.
///
/// An overflow is reported through the same channel as any other framework
/// error, so an empty list here means every Row and Column on screen fitted
/// the space it was given.
List<Object> takeOverflows() {
  final errors = <Object>[];
  while (true) {
    final error = TestWidgetsFlutterBinding.instance.takeException();
    if (error == null) break;
    errors.add(error);
  }
  return errors;
}
