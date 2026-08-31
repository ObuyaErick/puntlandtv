@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/responsive/adaptive_scaffold.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:puntland/core/theme/theme_context.dart';
import 'package:puntland/core/theme/tokens.dart';

import '../helpers/golden.dart';

/// The navigation transformation from artboard 7A, pinned at one width per
/// size class. These are the frames a reviewer looks at to answer "did the
/// rail appear where it should".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  const destinations = [
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
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Programs',
    ),
    AdaptiveDestination(
      icon: Icons.radio_outlined,
      selectedIcon: Icons.radio_rounded,
      label: 'Radio',
    ),
    AdaptiveDestination(
      icon: Icons.bookmark_outline_rounded,
      selectedIcon: Icons.bookmark_rounded,
      label: 'Saved',
    ),
  ];

  Widget stubMiniPlayer(BuildContext context, {bool floating = false}) {
    return Material(
      color: context.colors.playerSurface,
      borderRadius: floating ? Radii.cardBorder : null,
      elevation: floating ? 1 : 0,
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            const SizedBox(width: Spacing.cardInternal),
            Icon(
              Icons.live_tv_rounded,
              size: 20,
              color: context.colors.onPlayerSurfaceVariant,
            ),
            const SizedBox(width: Spacing.cardInternal),
            Text(
              'Warbaahinta Fiidka',
              style: context.text.label.copyWith(
                color: context.colors.onPlayerSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // One width per size class, plus the landscape phone flip.
  const cases = <(String, double, double)>[
    ('compact_390', 390, 844),
    ('medium_768', 768, 1024),
    ('expanded_1024', 1024, 768),
    ('large_1440', 1440, 900),
    ('landscape_800x360', 800, 360),
  ];

  for (final (name, width, height) in cases) {
    testWidgets('shell · $name', (tester) async {
      await pumpGolden(
        tester,
        Builder(
          builder: (context) => AdaptiveNavigationScaffold(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            body: ColoredBox(
              color: context.scheme.surfaceContainerLow,
              child: Center(
                child: Text('Content', style: context.text.headline),
              ),
            ),
            footer: stubMiniPlayer(context),
            floatingFooter: stubMiniPlayer(context, floating: true),
          ),
        ),
        width: width,
        height: height,
        theme: AppTheme.light(),
      );
      await expectLater(
        find.byType(AdaptiveNavigationScaffold),
        matchesGoldenFile('../goldens/shell_$name.png'),
      );
    });
  }
}
