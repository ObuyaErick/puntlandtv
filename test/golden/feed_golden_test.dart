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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Future<void> pumpFeed(
    WidgetTester tester, {
    required Locale locale,
    ThemeData? theme,
    double textScale = 1,
  }) => pumpGolden(
    tester,
    const NewsFeedPage(),
    locale: locale,
    theme: theme,
    textScale: textScale,
    overrides: [
      newsRepositoryProvider.overrideWithValue(FakeNewsRepository()),
      connectivityProvider.overrideWith((ref) => Stream.value(true)),
    ],
  );

  testWidgets('feed · light · en', (tester) async {
    await pumpFeed(tester, locale: const Locale('en', 'US'));
    await expectLater(
      find.byType(NewsFeedPage),
      matchesGoldenFile('../goldens/feed_light_en.png'),
    );
  });

  testWidgets('feed · dark · so', (tester) async {
    await pumpFeed(tester, locale: const Locale('so'), theme: AppTheme.dark());
    await expectLater(
      find.byType(NewsFeedPage),
      matchesGoldenFile('../goldens/feed_dark_so.png'),
    );
  });
}
