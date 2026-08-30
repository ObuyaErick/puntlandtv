import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/features/live/presentation/widgets/player_controls.dart';
import 'package:puntland/features/player/presentation/controllers/playback_controller.dart';

import '../../../helpers/pump_app.dart';

/// The controls sit in a 16:9 box, so their available height is a function of
/// device *width*. At 390dp there are 5px to spare and at 360dp — the most
/// common Android width — there are not. Every size the app supports gets a
/// case here.
void main() {
  const widths = <double>[320, 360, 375, 390, 412, 428];

  Future<void> pumpControls(
    WidgetTester tester, {
    required double width,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      Scaffold(
        body: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: PlayerControls(
                      state: const PlaybackState(isPlaying: true),
                      onPlayPause: () {},
                      onMute: () {},
                      onFullscreen: () {},
                      onCollapse: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      textScale: textScale,
    );
    await tester.pump();
  }

  for (final width in widths) {
    testWidgets('no overflow at ${width.toInt()}dp', (tester) async {
      await pumpControls(tester, width: width);
      expect(
        tester.takeException(),
        isNull,
        reason:
            'controls must fit the 16:9 box at ${width.toInt()}dp '
            '(${(width * 9 / 16).toStringAsFixed(1)}px tall)',
      );
    });

    testWidgets('no overflow at ${width.toInt()}dp · 130% text', (
      tester,
    ) async {
      await pumpControls(tester, width: width, textScale: 1.3);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the play control keeps a 48dp target at the smallest width', (
    tester,
  ) async {
    await pumpControls(tester, width: 320);

    final playButton = find.byIcon(Icons.pause_rounded);
    expect(playButton, findsOneWidget);
    final size = tester.getSize(
      find.ancestor(of: playButton, matching: find.byType(InkResponse)).first,
    );
    expect(
      size.height,
      greaterThanOrEqualTo(48),
      reason: 'shrinking to fit must not shrink below the minimum tap target',
    );
  });
}
