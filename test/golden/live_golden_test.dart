@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/providers/repository_providers.dart';
import 'package:puntland/features/live/presentation/pages/live_page.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/golden.dart';

/// The three live layouts, and the widths where the player chrome changes.
///
/// 360dp is where the old controls overflowed by 12px; 320dp is where the
/// transport collapses. Both get a frame, because "no exception thrown" is a
/// weaker claim than "this is what it looks like".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Future<void> pumpLive(
    WidgetTester tester, {
    required double width,
    required double height,
    bool isLive = true,
    Locale locale = const Locale('en', 'US'),
    double textScale = 1,
  }) async {
    await pumpGolden(
      tester,
      const LivePage(),
      width: width,
      height: height,
      locale: locale,
      textScale: textScale,
      overrides: [
        liveRepositoryProvider.overrideWithValue(
          FakeLiveRepository(isLive: isLive),
        ),
      ],
    );
  }

  const cases = <(String, double, double)>[
    ('stacked_320', 320, 568),
    ('stacked_360', 360, 800),
    ('stacked_390', 390, 844),
    ('immersive_landscape_800x360', 800, 360),
    ('medium_768', 768, 1024),
    ('side_by_side_1440', 1440, 900),
  ];

  for (final (name, width, height) in cases) {
    testWidgets('live · $name', (tester) async {
      await pumpLive(tester, width: width, height: height);
      await expectLater(
        find.byType(LivePage),
        matchesGoldenFile('../goldens/live_$name.png'),
      );
    });
  }

  testWidgets('live · off air slate · so', (tester) async {
    await pumpLive(
      tester,
      width: 390,
      height: 844,
      isLive: false,
      locale: const Locale('so'),
    );
    await expectLater(
      find.byType(LivePage),
      matchesGoldenFile('../goldens/live_offline_so.png'),
    );
  });

  testWidgets('live · 360dp · soomaali · 130% text', (tester) async {
    await pumpLive(
      tester,
      width: 360,
      height: 800,
      locale: const Locale('so'),
      textScale: 1.3,
    );
    await expectLater(
      find.byType(LivePage),
      matchesGoldenFile('../goldens/live_so_130.png'),
    );
  });
}
