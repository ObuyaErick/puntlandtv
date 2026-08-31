@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/providers/connectivity_provider.dart';
import 'package:puntland/core/providers/repository_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:puntland/features/news/presentation/pages/news_feed_page.dart';

import '../features/news/presentation/feed_controller_test.dart'
    show FakeNewsRepository;
import '../helpers/golden.dart';

/// The feed's three arrangements: single column, two columns at medium, and
/// list-detail at expanded and above.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Future<void> pumpFeed(
    WidgetTester tester, {
    required double width,
    required double height,
    Locale locale = const Locale('en', 'US'),
    ThemeData? theme,
    double textScale = 1,
  }) => pumpGolden(
    tester,
    const NewsFeedPage(),
    width: width,
    height: height,
    locale: locale,
    theme: theme,
    textScale: textScale,
    overrides: [
      newsRepositoryProvider.overrideWithValue(FakeNewsRepository()),
      connectivityProvider.overrideWith((ref) => Stream.value(true)),
    ],
  );

  const cases = <(String, double, double)>[
    ('compact_390', 390, 844),
    ('medium_768', 768, 1024),
    ('expanded_1024', 1024, 768),
    ('large_1440', 1440, 900),
  ];

  for (final (name, width, height) in cases) {
    testWidgets('feed · $name', (tester) async {
      await pumpFeed(tester, width: width, height: height);
      await expectLater(
        find.byType(NewsFeedPage),
        matchesGoldenFile('../goldens/feed_$name.png'),
      );
    });
  }

  testWidgets('feed · dark · so', (tester) async {
    await pumpFeed(
      tester,
      width: 390,
      height: 844,
      locale: const Locale('so'),
      theme: AppTheme.dark(),
    );
    await expectLater(
      find.byType(NewsFeedPage),
      matchesGoldenFile('../goldens/feed_dark_so.png'),
    );
  });

  // At 130% the card thumbnail moves above the headline: a 104dp side thumb
  // would leave only ~150dp for a three-line Somali title.
  testWidgets('feed · 320dp · so · 130% text stacks the card', (tester) async {
    await pumpFeed(
      tester,
      width: 320,
      height: 700,
      locale: const Locale('so'),
      textScale: 1.3,
    );
    await expectLater(
      find.byType(NewsFeedPage),
      matchesGoldenFile('../goldens/feed_so_130_stacked.png'),
    );
  });
}
