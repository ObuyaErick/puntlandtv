import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/dto/admin_article_dto.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/articles/presentation/controllers/article_list_controller.dart';
import 'package:puntland/console/features/articles/presentation/pages/article_list_page.dart';
import 'package:puntland/console/features/articles/presentation/widgets/article_row_card.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:puntland/console/core/widgets/console_page.dart';
import 'package:puntland/console/core/widgets/console_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedInAs extends AuthController {
  _SignedInAs(this.role, this.id);

  final ConsoleRole role;
  final String id;

  @override
  AuthState build() => SignedIn(
    ConsoleUser(id: id, name: 'X. Y', email: 'x@pltv.so', role: role),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpList(
    WidgetTester tester, {
    required ConsoleRole role,
    required String userId,
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
          authControllerProvider.overrideWith(() => _SignedInAs(role, userId)),
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
          home: const Scaffold(body: ArticleListPage()),
        ),
      ),
    );
    // The fixture API resolves through zero-duration futures, and the screen
    // now awaits two of them — the article list and the category names. Each
    // needs its own frame to settle.
    for (var i = 0; i < 4; i++) {
      await tester.pump(Duration.zero);
    }
    await tester.pump();
  }

  group('role scoping', () {
    testWidgets('an editor sees every author\'s articles', (tester) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      expect(find.text('Articles'), findsOneWidget);
      expect(find.textContaining('F. Xasan'), findsWidgets);
      expect(find.textContaining('A. Yuusuf'), findsWidgets);
    });

    testWidgets('a journalist sees only their own, and is told why', (
      tester,
    ) async {
      await pumpList(
        tester,
        role: ConsoleRole.journalist,
        userId: 'u-journalist',
      );

      expect(find.text('My articles'), findsOneWidget);
      expect(
        find.textContaining('Publishing, scheduling and push are Editor'),
        findsOneWidget,
        reason:
            'a role limit the user cannot see just looks like missing '
            'buttons',
      );
      expect(
        find.textContaining('A. Yuusuf'),
        findsNothing,
        reason: 'scoping happens at the query, not in the widget',
      );
    });

    testWidgets('a journalist gets no bulk checkboxes', (tester) async {
      await pumpList(
        tester,
        role: ConsoleRole.journalist,
        userId: 'u-journalist',
      );

      expect(find.byType(Checkbox), findsNothing);
    });
  });

  group('presentation by width', () {
    testWidgets('renders a table at desktop width', (tester) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      expect(find.byType(ConsoleTableHeader), findsOneWidget);
      expect(find.byType(ArticleRowCard), findsNothing);
    });

    testWidgets('renders cards at compact width', (tester) async {
      await pumpList(
        tester,
        role: ConsoleRole.editor,
        userId: 'u-editor',
        size: const Size(390, 844),
      );

      expect(
        find.byType(ConsoleTableHeader),
        findsNothing,
        reason: 'six columns on a 390dp screen is a table nobody can read',
      );
      expect(find.byType(ArticleRowCard), findsWidgets);
    });
  });

  group('bulk selection', () {
    testWidgets('ticking a row reveals the bulk bar with a count', (
      tester,
    ) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);
    });
  });

  group('filters', () {
    testWidgets('selecting a status narrows the list', (tester) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      // Scoped to the chip: 'PUBLISHED' also appears as a status badge on
      // every published row, and `find.text(...).first` would tap one of those
      // and silently assert nothing.
      final chip = find.descendant(
        of: find.byType(ConsoleFilterChip),
        matching: find.text('PUBLISHED'),
      );
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ArticleListPage)),
      );
      final rows = container.read(articleListProvider).value ?? [];
      expect(rows, isNotEmpty);
      expect(rows.every((a) => a.status == ArticleStatus.published), isTrue);
    });
  });
}
