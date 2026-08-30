import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntland/app/app.dart';
import 'package:puntland/core/api/api_providers.dart';
import 'package:puntland/core/api/fixture_puntland_api.dart';
import 'package:puntland/core/providers/connectivity_provider.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end smoke test over the real composition root.
///
/// Nothing is faked except `SharedPreferences` (which needs a platform
/// channel) — the app runs against [FixturePuntlandApi] exactly as it does on
/// a device with no backend configured. That means this exercises the router,
/// the shell, the theme, the localisation delegates, every repository and the
/// full mapping path.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launch(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Same implementation the app uses when no backend is configured, minus
    // the simulated latency — that delay is a fake-clock timer while the asset
    // read behind it is real I/O, and interleaving two clocks makes the test
    // flaky rather than meaningful.
    final api = FixturePuntlandApi(
      languageCode: () => 'en',
      latency: Duration.zero,
    );

    // Warm the bundle in a real-async zone. `rootBundle.loadString` does not
    // complete under `pump()`'s fake clock, so without this the first read
    // inside the widget tree never resolves and the feed renders empty.
    await tester.runAsync(api.fetchCategories);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // `connectivity_plus` has no implementation on the test platform and
          // its event channel throws the moment real async runs.
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          puntlandApiProvider.overrideWith((ref) => api),
        ],
        child: const PuntlandTvApp(),
      ),
    );

    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('boots to the news feed with all five tabs', (tester) async {
    await launch(tester);

    expect(find.text('PUNTLAND TV'), findsOneWidget);
    for (final tab in ['Home', 'Live TV', 'Programs', 'Radio', 'Saved']) {
      expect(find.text(tab), findsOneWidget, reason: '$tab tab missing');
    }
  });

  testWidgets('loads real fixture content into the feed', (tester) async {
    await launch(tester);

    expect(
      find.textContaining('Heavy rains forecast'),
      findsOneWidget,
      reason:
          'the lead story should come through the full '
          'API → mapper → repository → controller → widget path',
    );
    expect(find.text('LEAD STORY'), findsOneWidget);
  });

  testWidgets('navigates between tabs', (tester) async {
    await launch(tester);

    await tester.tap(find.text('Programs'));
    await settle(tester);

    expect(find.text('Watch anytime'), findsOneWidget);
  });

  testWidgets('opens an article from the feed', (tester) async {
    await launch(tester);

    await tester.tap(find.textContaining('Heavy rains forecast'));
    await settle(tester);

    expect(find.textContaining('PLTV Newsroom'), findsOneWidget);
  });
}
