import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/articles/presentation/controllers/category_controller.dart';
import 'package:puntland/console/features/articles/presentation/pages/categories_page.dart';
import 'package:puntland/console/features/articles/presentation/pages/category_panel.dart';
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
      id: 'u-${role.name}',
      name: 'A. Yuusuf',
      email: 'a@pltv.so',
      role: role,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    ConsoleRole role = ConsoleRole.editor,
    Size size = const Size(1440, 900),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => _SignedInAs(role)),
          adminApiProvider.overrideWithValue(
            FixtureAdminApi(
              latency: Duration.zero,
              now: DateTime(2026, 8, 30, 21, 12),
            ),
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
          home: Scaffold(body: screen),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pump();

    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  group('categories', () {
    testWidgets('an untranslated category is marked and shown hidden', (
      tester,
    ) async {
      await pumpScreen(tester, const CategoriesPage(), role: ConsoleRole.admin);

      // The name falls back to the other language and the gap is stated in
      // words, rather than a "Not translated" placeholder where a name should
      // be.
      expect(find.text('Waxbarasho'), findsOneWidget);
      expect(find.textContaining('No English translation'), findsOneWidget);
      expect(find.textContaining('slug is permanent'), findsOneWidget);
    });

    Finder panelFields() => find.descendant(
      of: find.byType(CategoryPanel),
      matching: find.byType(TextField),
    );

    testWidgets('a new category is checked as typed and lands at the end', (
      tester,
    ) async {
      await pumpScreen(tester, const CategoriesPage(), role: ConsoleRole.admin);

      await tester.tap(find.widgetWithText(FilledButton, 'New category'));
      await tester.pumpAndSettle();

      FilledButton create() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create category'),
      );
      // Fields: slug, then one name per locale in `CategoryConfigDto.locales`.
      final slug = panelFields().at(0);
      final english = panelFields().at(2);

      await tester.enterText(english, 'Health');
      await tester.enterText(slug, 'sport');
      await tester.pump();
      expect(
        find.text('Another category already uses this slug.'),
        findsOneWidget,
        reason: 'a save would silently rename the existing category',
      );
      expect(create().onPressed, isNull);

      await tester.enterText(slug, 'Health News');
      await tester.pump();
      expect(find.textContaining('Use lower-case letters'), findsOneWidget);
      expect(create().onPressed, isNull);

      await tester.enterText(slug, 'health');
      await tester.pump();
      expect(find.textContaining('Hidden from the Somali tab'), findsOneWidget);
      expect(create().onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Create category'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryPanel), findsNothing);
      expect(find.text('health'), findsOneWidget);

      final saved = await container.read(adminApiProvider).fetchCategories();
      expect(saved.last.slug, 'health');
      expect(saved.last.names, {'en': 'Health'});
      // The seed has two rows claiming position 1; a save renumbers the lot.
      expect(saved.map((c) => c.order), [0, 1, 2, 3, 4, 5, 6]);
    });

    testWidgets('renaming a category fills in its missing translation', (
      tester,
    ) async {
      await pumpScreen(tester, const CategoriesPage(), role: ConsoleRole.admin);

      await tester.tap(find.text('Waxbarasho'));
      await tester.pumpAndSettle();

      final slugField = tester.widget<TextField>(panelFields().at(0));
      expect(slugField.enabled, isFalse, reason: 'the slug is permanent');

      await tester.enterText(panelFields().at(2), 'Education');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryPanel), findsNothing);
      expect(find.text('Education'), findsOneWidget);
      expect(find.textContaining('No English translation'), findsNothing);
    });

    testWidgets('only an empty category can be deleted', (tester) async {
      await pumpScreen(tester, const CategoriesPage(), role: ConsoleRole.admin);

      await tester.tap(find.text('sport'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Delete'),
            )
            .onPressed,
        isNull,
        reason: '44 published stories would lose their category',
      );
      expect(find.textContaining('44 articles are filed here'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await container
          .read(categoryActionsProvider.notifier)
          .create(slug: 'helth', names: const {'en': 'Health'});
      await tester.pumpAndSettle();

      await tester.tap(find.text('helth'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryPanel), findsNothing);
      expect(find.text('helth'), findsNothing);
    });
  });
}
