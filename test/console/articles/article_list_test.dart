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
import 'package:puntland/core/widgets/feedback_views.dart';
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

    /// Opens one of the three narrowing selects and picks an option by name.
    ///
    /// Scrolls the filter row to the control first. The row is a horizontal
    /// scroller, and under the test font — which renders every glyph square,
    /// so a label measures about twice its real width — the last select sits
    /// past the right edge at 1440.
    Future<void> choose(
      WidgetTester tester,
      String selectKey,
      String option,
    ) async {
      await tester.dragUntilVisible(
        find.byKey(Key(selectKey)),
        find.byKey(const Key('article-filters')),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(selectKey)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      await tester.pump();
    }

    List<AdminArticleDto> rowsOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(ArticleListPage)))
            .read(articleListProvider)
            .value!;

    testWidgets('picking a category narrows to it', (tester) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      final before = rowsOf(tester);
      expect(
        before.map((a) => a.categorySlug).toSet().length,
        greaterThan(1),
        reason: 'the fixture must span categories for this to mean anything',
      );

      await choose(tester, 'filter-category', 'Sport');

      final after = rowsOf(tester);
      expect(after, isNotEmpty);
      expect(after.every((a) => a.categorySlug == 'sport'), isTrue);
    });

    testWidgets('picking a language keeps only articles written in it', (
      tester,
    ) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      expect(
        rowsOf(tester).any((a) => !a.translations.containsKey('en')),
        isTrue,
        reason: 'a Somali-only article is what this filter has to remove',
      );

      await choose(tester, 'filter-locale', 'English');

      final after = rowsOf(tester);
      expect(after, isNotEmpty);
      expect(after.every((a) => a.translations.containsKey('en')), isTrue);
    });

    testWidgets('picking an author narrows to their byline', (tester) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      expect(
        rowsOf(tester).map((a) => a.authorId).toSet().length,
        greaterThan(1),
      );

      await choose(tester, 'filter-author', 'F. Xasan');

      final after = rowsOf(tester);
      expect(after, isNotEmpty);
      expect(after.every((a) => a.authorId == 'u-journalist'), isTrue);
    });

    testWidgets('the filters compose rather than replace each other', (
      tester,
    ) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      await choose(tester, 'filter-author', 'A. Yuusuf');
      await choose(tester, 'filter-locale', 'English');

      final query = ProviderScope.containerOf(
        tester.element(find.byType(ArticleListPage)),
      ).read(articleFilterProvider);
      expect(query.authorId, 'u-editor');
      expect(query.locale, 'en');

      expect(
        rowsOf(tester).every(
          (a) => a.authorId == 'u-editor' && a.translations.containsKey('en'),
        ),
        isTrue,
      );
    });

    testWidgets('the chip counts follow the narrowing filters', (tester) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ArticleListPage)),
      );
      final before = container.read(articleCountsProvider).value!.all;

      await choose(tester, 'filter-category', 'Sport');

      final after = container.read(articleCountsProvider).value!.all;
      expect(after, lessThan(before));
      expect(after, rowsOf(tester).length);
    });

    testWidgets('clear filters is dead until something is filtered', (
      tester,
    ) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      TextButton clearButton() => tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Clear filters'),
          matching: find.byType(TextButton),
        ),
      );
      expect(clearButton().onPressed, isNull);

      await choose(tester, 'filter-category', 'Sport');
      expect(clearButton().onPressed, isNotNull);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ArticleListPage)),
      );
      expect(container.read(articleFilterProvider).isNarrowed, isFalse);
      expect(clearButton().onPressed, isNull);
    });

    testWidgets('a journalist is offered no author filter', (tester) async {
      await pumpList(
        tester,
        role: ConsoleRole.journalist,
        userId: 'u-journalist',
      );

      expect(find.byKey(const Key('filter-author')), findsNothing);
      expect(find.byKey(const Key('filter-category')), findsOneWidget);
    });

    testWidgets('a filter that matches nothing says so, and offers a way out', (
      tester,
    ) async {
      await pumpList(tester, role: ConsoleRole.editor, userId: 'u-editor');

      // Sport has no article in review; the pair is empty by construction.
      await choose(tester, 'filter-category', 'Sport');

      // `choose` left the row scrolled right; the status chips are back the
      // other way.
      final chip = find.descendant(
        of: find.byType(ConsoleFilterChip),
        matching: find.text('IN REVIEW'),
      );
      await tester.dragUntilVisible(
        chip,
        find.byKey(const Key('article-filters')),
        const Offset(120, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(rowsOf(tester), isEmpty);
      expect(find.text('No articles match these filters'), findsOneWidget);
      expect(find.text('No articles here yet'), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(EmptyView),
          matching: find.text('Clear filters'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(rowsOf(tester), isNotEmpty);
    });
  });
}
