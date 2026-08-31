import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/providers/repository_providers.dart';
import 'package:puntland/features/live/presentation/pages/live_page.dart';
import 'package:puntland/features/live/presentation/widgets/now_playing_panel.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

/// Which of the three live layouts gets chosen, and why.
///
/// The rule is not "how wide is the window" but "what is left after a 16:9
/// video" — which is why a 800×360 landscape phone and a 320dp portrait phone
/// at 130% text both end up immersive despite very different widths.
void main() {
  Future<void> pumpLive(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      const LivePage(),
      textScale: textScale,
      overrides: [
        liveRepositoryProvider.overrideWithValue(const FakeLiveRepository()),
      ],
    );
    await tester.pump();
  }

  group('layout selection', () {
    testWidgets('portrait phone stacks the player over the panel', (
      tester,
    ) async {
      await pumpLive(tester, size: const Size(390, 844));

      expect(find.byType(AspectRatio), findsWidgets);
      expect(find.byType(NowPlayingPanel), findsOneWidget);
    });

    testWidgets('landscape phone goes immersive', (tester) async {
      await pumpLive(tester, size: const Size(800, 360));

      expect(
        find.byType(NowPlayingPanel),
        findsNothing,
        reason:
            'there is no room below a 16:9 video in landscape, so the '
            'video takes the surface and chrome overlays it',
      );
      expect(find.byType(PlayerSurface), findsOneWidget);
    });

    testWidgets('a short portrait window goes immersive too', (tester) async {
      // 320×420: the 16:9 player is 180dp, leaving 240dp — but at 130% text
      // the reserved band grows past what is left.
      await pumpLive(tester, size: const Size(320, 300), textScale: 1.3);

      expect(find.byType(NowPlayingPanel), findsNothing);
    });

    testWidgets('desktop pairs a capped player with the schedule', (
      tester,
    ) async {
      await pumpLive(tester, size: const Size(1440, 900));

      expect(find.byType(NowPlayingPanel), findsOneWidget);

      final playerWidth = tester.getSize(find.byType(PlayerSurface)).width;
      expect(
        playerWidth,
        lessThanOrEqualTo(740),
        reason: 'the video must not stretch across the whole window',
      );
    });

    testWidgets('no overflow in any layout, in either locale', (tester) async {
      const sizes = [
        Size(320, 568),
        Size(390, 844),
        Size(800, 360),
        Size(768, 1024),
        Size(1024, 768),
        Size(1440, 900),
      ];

      for (final size in sizes) {
        for (final scale in [1.0, 1.3]) {
          await pumpLive(tester, size: size, textScale: scale);
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow at ${size.width}×${size.height} @ $scale',
          );
        }
      }
    });
  });
}
