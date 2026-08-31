@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/app/console_shell.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/articles/presentation/pages/article_list_page.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/features/overview/presentation/pages/overview_page.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/golden.dart';

class _SignedInAs extends AuthController {
  _SignedInAs(this.role, this.id);

  final ConsoleRole role;
  final String id;

  @override
  AuthState build() => SignedIn(
    ConsoleUser(
      id: id,
      name: role == ConsoleRole.journalist ? 'F. Xasan' : 'A. Yuusuf',
      email: 'x@pltv.so',
      role: role,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Future<List<Override>> overridesFor(ConsoleRole role, String id) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authControllerProvider.overrideWith(() => _SignedInAs(role, id)),
      // Collapsed, as the article-list artboard shows it.
      railCollapsedProvider.overrideWith(_Collapsed.new),
      // The same instant as the fixture below: with the two clocks pinned
      // apart, "sent 2 minutes ago" rendered as a negative age.
      consoleClockProvider.overrideWithValue(
        () => DateTime(2026, 8, 31, 21, 12),
      ),
      adminApiProvider.overrideWithValue(
        // Pinned clock: the list shows absolute times, so a live clock would
        // shift these goldens by a minute on every run.
        FixtureAdminApi(
          latency: Duration.zero,
          now: DateTime(2026, 8, 31, 21, 12),
        ),
      ),
    ];
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pump();
  }

  testWidgets('console · overview · editor', (tester) async {
    await pumpGolden(
      tester,
      const Scaffold(body: OverviewPage()),
      width: 1440,
      height: 900,
      overrides: await overridesFor(ConsoleRole.editor, 'u-editor'),
    );
    await settle(tester);
    await expectLater(
      find.byType(OverviewPage),
      matchesGoldenFile('../goldens/console_overview.png'),
    );
  });

  testWidgets('console · overview · compact', (tester) async {
    await pumpGolden(
      tester,
      const Scaffold(body: OverviewPage()),
      width: 390,
      height: 900,
      overrides: await overridesFor(ConsoleRole.editor, 'u-editor'),
    );
    await settle(tester);
    await expectLater(
      find.byType(OverviewPage),
      matchesGoldenFile('../goldens/console_overview_compact.png'),
    );
  });

  testWidgets('console · articles · table · editor', (tester) async {
    await pumpGolden(
      tester,
      const Scaffold(body: ArticleListPage()),
      width: 1440,
      height: 900,
      overrides: await overridesFor(ConsoleRole.editor, 'u-editor'),
    );
    await settle(tester);
    await expectLater(
      find.byType(ArticleListPage),
      matchesGoldenFile('../goldens/console_articles_table.png'),
    );
  });

  testWidgets('console · articles · full screen · collapsed rail', (
    tester,
  ) async {
    await pumpGolden(
      tester,
      ConsoleShell(
        currentRoute: '/articles',
        onNavigate: (_) {},
        articleBadge: 12,
        child: const ArticleListPage(),
      ),
      width: 1440,
      height: 900,
      overrides: await overridesFor(ConsoleRole.editor, 'u-editor'),
    );
    await settle(tester);
    await expectLater(
      find.byType(ConsoleShell),
      matchesGoldenFile('../goldens/console_articles_full.png'),
    );
  });

  testWidgets('console · articles · journalist', (tester) async {
    await pumpGolden(
      tester,
      const Scaffold(body: ArticleListPage()),
      width: 1440,
      height: 900,
      overrides: await overridesFor(ConsoleRole.journalist, 'u-journalist'),
    );
    await settle(tester);
    await expectLater(
      find.byType(ArticleListPage),
      matchesGoldenFile('../goldens/console_articles_journalist.png'),
    );
  });

  testWidgets('console · articles · cards · compact · so', (tester) async {
    await pumpGolden(
      tester,
      const Scaffold(body: ArticleListPage()),
      width: 390,
      height: 900,
      locale: const Locale('so'),
      overrides: await overridesFor(ConsoleRole.editor, 'u-editor'),
    );
    await settle(tester);
    await expectLater(
      find.byType(ArticleListPage),
      matchesGoldenFile('../goldens/console_articles_cards_so.png'),
    );
  });
}

/// Rail collapsed, matching artboard 11B.
class _Collapsed extends RailCollapsed {
  @override
  bool build() => true;
}
