import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/responsive/window_size.dart';
import 'package:puntland/core/theme/tokens.dart';
import 'package:puntland/features/live/presentation/widgets/player_controls.dart';
import 'package:puntland/features/player/domain/entities/playback_source.dart';
import 'package:puntland/features/player/presentation/controllers/playback_controller.dart';

import '../../../helpers/pump_app.dart';

/// The controls overlay the video rather than sitting inside a column below
/// it, which is what the original 12px overflow at 360dp came from. Every
/// width the app supports gets a case, because the 16:9 surface makes the
/// available height a function of device width.
void main() {
  const widths = <double>[320, 360, 375, 390, 412, 428];

  const source = PlaybackSource(
    id: 'live',
    url: 'https://example.invalid/live.m3u8',
    kind: PlaybackKind.liveTv,
    title: 'Warbaahinta Fiidka',
  );

  Future<void> pumpControls(
    WidgetTester tester, {
    required double width,
    double textScale = 1,
    PlaybackState state = const PlaybackState(source: source, isPlaying: true),
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
              child: ColoredBox(
                color: const Color(0xFF04101F),
                child: PlayerControls(
                  state: state,
                  clockLabel: '21:04',
                  onPlayPause: () {},
                  onMute: () {},
                  onFullscreen: () {},
                  onCollapse: () {},
                ),
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
            'chrome must fit the 16:9 surface at ${width.toInt()}dp '
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

  group('transport collapse', () {
    testWidgets('keeps the quality chip at and above 360dp', (tester) async {
      await pumpControls(tester, width: Layout.transportCollapseWidth);

      expect(find.text('HD'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    });

    testWidgets('folds it into an overflow button below 360dp', (tester) async {
      await pumpControls(tester, width: 320);

      expect(
        find.text('HD'),
        findsNothing,
        reason: 'controls are dropped below 360dp, never squeezed',
      );
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('the overflow button reaches the dropped controls', (
      tester,
    ) async {
      await pumpControls(tester, width: 320);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Whatever the strip drops has to remain reachable, or "collapsed"
      // just means "removed".
      expect(find.text('HD'), findsOneWidget);
    });
  });

  group('tap targets', () {
    testWidgets('every overlay control meets 48dp at the smallest width', (
      tester,
    ) async {
      await pumpControls(tester, width: 320);

      final buttons = find.byType(IconButton);
      expect(buttons, findsWidgets);

      for (var i = 0; i < tester.widgetList(buttons).length; i++) {
        final size = tester.getSize(buttons.at(i));
        expect(
          size.width,
          greaterThanOrEqualTo(kMinTapTarget),
          reason: 'control $i is only ${size.width}dp wide',
        );
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      }
    });
  });

  group('live versus on-demand', () {
    testWidgets('a live stream shows the clock, not a position', (
      tester,
    ) async {
      await pumpControls(tester, width: 390);
      expect(find.textContaining('21:04'), findsWidgets);
    });

    testWidgets('an episode shows elapsed position instead', (tester) async {
      await pumpControls(
        tester,
        width: 390,
        state: const PlaybackState(
          source: PlaybackSource(
            id: 'ep-1',
            url: 'https://example.invalid/ep.m3u8',
            kind: PlaybackKind.vod,
            title: 'Evening bulletin',
          ),
          isPlaying: true,
          position: Duration(minutes: 12, seconds: 5),
          duration: Duration(minutes: 58),
        ),
      );

      expect(find.text('12:05'), findsOneWidget);
    });
  });
}
