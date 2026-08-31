import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/responsive/adaptive_layout.dart';
import 'package:puntland/core/responsive/window_size.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('WindowSizeClass.fromWidth', () {
    // The boundaries are the whole point of a breakpoint table, so each one is
    // pinned on both sides rather than sampled somewhere in the middle.
    const cases = <(double, WindowSizeClass)>[
      (0, WindowSizeClass.compact),
      (320, WindowSizeClass.compact),
      (599.9, WindowSizeClass.compact),
      (600, WindowSizeClass.medium),
      (839.9, WindowSizeClass.medium),
      (840, WindowSizeClass.expanded),
      (1199.9, WindowSizeClass.expanded),
      (1200, WindowSizeClass.large),
      (1599.9, WindowSizeClass.large),
      (1600, WindowSizeClass.extraLarge),
      (2560, WindowSizeClass.extraLarge),
    ];

    for (final (width, expected) in cases) {
      test('$width → ${expected.name}', () {
        expect(WindowSizeClass.fromWidth(width), expected);
      });
    }
  });

  group('threshold helpers', () {
    test('isAtLeastMedium marks where sheets become dialogs', () {
      expect(WindowSizeClass.compact.isAtLeastMedium, isFalse);
      expect(WindowSizeClass.medium.isAtLeastMedium, isTrue);
      expect(WindowSizeClass.extraLarge.isAtLeastMedium, isTrue);
    });

    test('isAtLeastExpanded marks where the mini-player floats', () {
      expect(WindowSizeClass.medium.isAtLeastExpanded, isFalse);
      expect(WindowSizeClass.expanded.isAtLeastExpanded, isTrue);
    });
  });

  group('WindowSizeScope', () {
    // This is the rule that the player-height bug came from: a surface must be
    // measured by its own constraints, not the window's. A player inside a
    // 400dp detail pane of a 1440dp window is compact, not large.
    testWidgets('reports the constraints it is given, not the window', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      late WindowSizeClass outer;
      late WindowSizeClass inner;

      await pumpApp(
        tester,
        WindowSizeScope(
          builder: (context, size) {
            outer = size;
            // `Align` first: a bare `SizedBox` under tight parent constraints
            // is clamped back up to the parent's width and would measure 1440.
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: WindowSizeScope(
                  builder: (context, size) {
                    inner = size;
                    return const SizedBox.shrink();
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(outer, WindowSizeClass.large);
      expect(
        inner,
        WindowSizeClass.compact,
        reason: 'a 400dp pane inside a 1440dp window must lay out as compact',
      );
    });
  });

  group('reading measure', () {
    testWidgets('caps tighter on a landscape phone than on desktop', (
      tester,
    ) async {
      Future<double> measureAt(Size size) async {
        tester.view.physicalSize = Size(size.width * 3, size.height * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        late double measure;
        await pumpApp(
          tester,
          Builder(
            builder: (context) {
              measure = context.readingMeasure;
              return const SizedBox.shrink();
            },
          ),
        );
        return measure;
      }

      expect(
        await measureAt(const Size(800, 360)),
        Layout.readingMeasureLandscape,
      );
      expect(await measureAt(const Size(1440, 900)), Layout.readingMeasure);
    });

    testWidgets('ReadingColumn never exceeds the measure', (tester) async {
      tester.view.physicalSize = const Size(1440 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await pumpApp(
        tester,
        const Scaffold(
          body: ReadingColumn(
            child: SizedBox(height: 100, child: Placeholder()),
          ),
        ),
      );

      final width = tester.getSize(find.byType(Placeholder)).width;
      expect(width, lessThanOrEqualTo(Layout.readingMeasure));
    });
  });
}
