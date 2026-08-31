import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/articles/presentation/pages/article_list_page.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedInEditor extends AuthController {
  @override
  AuthState build() => const SignedIn(
    ConsoleUser(
      id: 'u-editor',
      name: 'A. Yuusuf',
      email: 'a@pltv.so',
      role: ConsoleRole.editor,
    ),
  );
}

/// One language switch has to re-hydrate everything: chrome *and* localised
/// data. A screen that keeps its labels in one language and its content in
/// another is the failure this suite exists to prevent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpList(WidgetTester tester, Locale locale) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1440 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_SignedInEditor.new),
          adminApiProvider.overrideWithValue(
            FixtureAdminApi(
              latency: Duration.zero,
              now: DateTime(2026, 8, 30, 21, 12),
            ),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          theme: AppTheme.light(),
          supportedLocales: const [Locale('en', 'US'), Locale('so')],
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppL10n.delegate,
            SoMaterialLocalizations.delegate,
            SoCupertinoLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const Scaffold(body: ArticleListPage()),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(Duration.zero);
    }
    await tester.pump();
  }

  group('the active locale drives everything', () {
    testWidgets('category names follow the UI language', (tester) async {
      await pumpList(tester, const Locale('en', 'US'));
      expect(find.text('Puntland'), findsWidgets);
      expect(
        find.text('Dalka'),
        findsNothing,
        reason:
            'an English console must not show Somali category names — '
            'the mockup rendering in Somali is illustrative content, not a '
            'rule about which language the console speaks',
      );

      await pumpList(tester, const Locale('so'));
      expect(find.text('Dalka'), findsWidgets);
      expect(find.text('Puntland'), findsNothing);
    });

    testWidgets('chrome and content switch together', (tester) async {
      await pumpList(tester, const Locale('en', 'US'));
      expect(find.text('Articles'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);

      await pumpList(tester, const Locale('so'));
      expect(find.text('Maqaallada'), findsOneWidget);
      expect(find.text('QAYBTA'), findsOneWidget);
    });

    testWidgets('a missing translation names the language in the UI language', (
      tester,
    ) async {
      await pumpList(tester, const Locale('en', 'US'));
      expect(find.textContaining('No English translation'), findsWidgets);

      await pumpList(tester, const Locale('so'));
      expect(
        find.textContaining('Turjumaad Ingiriisi ah ma jirto'),
        findsWidgets,
        reason:
            'the language being named is prose, so it is translated like '
            'any other word',
      );
    });
  });

  group('locale is not a column', () {
    testWidgets('the table has no LOCALE column', (tester) async {
      await pumpList(tester, const Locale('en', 'US'));

      expect(
        find.text('LOCALE'),
        findsNothing,
        reason:
            'which languages a row exists in is a technical field; the '
            'actionable part is said in words under the headline',
      );
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
    });
  });
}
