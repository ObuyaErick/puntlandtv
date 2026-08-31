import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/responsive/adaptive_scaffold.dart';
import 'package:puntland/core/responsive/window_size.dart';

import '../../helpers/pump_app.dart';

const _destinations = [
  AdaptiveDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
  ),
  AdaptiveDestination(
    icon: Icons.live_tv_outlined,
    selectedIcon: Icons.live_tv_rounded,
    label: 'Live TV',
  ),
  AdaptiveDestination(
    icon: Icons.bookmark_outline_rounded,
    selectedIcon: Icons.bookmark_rounded,
    label: 'Saved',
  ),
];

void main() {
  Future<void> pumpScaffold(
    WidgetTester tester, {
    required double width,
    double height = 900,
    Widget? footer,
    Widget? floatingFooter,
    ValueChanged<int>? onSelected,
  }) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      AdaptiveNavigationScaffold(
        destinations: _destinations,
        selectedIndex: 0,
        onDestinationSelected: onSelected ?? (_) {},
        body: const Center(child: Text('content')),
        footer: footer,
        floatingFooter: floatingFooter,
      ),
    );
    await tester.pump();
  }

  group('navigation transformation', () {
    testWidgets('compact uses a bottom bar', (tester) async {
      await pumpScaffold(tester, width: 390, height: 844);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('medium replaces the bar with an 80dp rail', (tester) async {
      await pumpScaffold(tester, width: 768, height: 1024);

      expect(find.byType(NavigationBar), findsNothing);
      // The rail is the widget sitting left of the divider.
      expect(find.byType(VerticalDivider), findsOneWidget);
      final railWidth = tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Home'),
                  matching: find.byType(SizedBox),
                )
                .last,
          )
          .width;
      expect(railWidth, Layout.railWidth);
    });

    testWidgets('every destination label survives the transformation', (
      tester,
    ) async {
      for (final width in <double>[390, 768, 1024, 1440]) {
        await pumpScaffold(tester, width: width);
        for (final destination in _destinations) {
          expect(
            find.text(destination.label),
            findsOneWidget,
            reason: '${destination.label} missing at ${width}dp',
          );
        }
      }
    });

    testWidgets('destinations stay tappable in both shapes', (tester) async {
      for (final width in <double>[390, 1024]) {
        var tapped = -1;
        await pumpScaffold(
          tester,
          width: width,
          onSelected: (index) => tapped = index,
        );
        await tester.tap(find.text('Saved'));
        expect(tapped, 2, reason: 'tap did not register at ${width}dp');
      }
    });
  });

  group('mini-player docking', () {
    const footer = SizedBox(key: Key('footer'), height: 58);
    const floating = SizedBox(key: Key('floating'), height: 58);

    testWidgets('docks above the bar at compact', (tester) async {
      await pumpScaffold(
        tester,
        width: 390,
        height: 844,
        footer: footer,
        floatingFooter: floating,
      );

      expect(find.byKey(const Key('footer')), findsOneWidget);
      expect(find.byKey(const Key('floating')), findsNothing);
    });

    testWidgets('still docks at medium, spanning the content pane only', (
      tester,
    ) async {
      await pumpScaffold(
        tester,
        width: 768,
        footer: footer,
        floatingFooter: floating,
      );

      expect(find.byKey(const Key('footer')), findsOneWidget);
      expect(find.byKey(const Key('floating')), findsNothing);

      // It must not run under the rail — that would make the rail look like
      // part of the player.
      final left = tester.getTopLeft(find.byKey(const Key('footer'))).dx;
      expect(left, greaterThanOrEqualTo(Layout.railWidth));
    });

    testWidgets('floats bottom-right at expanded and up', (tester) async {
      for (final width in <double>[1024, 1440, 1920]) {
        await pumpScaffold(
          tester,
          width: width,
          footer: footer,
          floatingFooter: floating,
        );

        expect(
          find.byKey(const Key('floating')),
          findsOneWidget,
          reason: 'should float at ${width}dp',
        );
        expect(find.byKey(const Key('footer')), findsNothing);

        final box = tester.getRect(find.byKey(const Key('floating')));
        expect(box.width, Layout.miniPlayerFloatingWidth);
        expect(
          box.right,
          lessThan(width),
          reason: 'must sit inside the right edge, not against it',
        );
      }
    });
  });
}
