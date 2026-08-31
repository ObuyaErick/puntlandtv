import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/responsive/adaptive_scaffold.dart';
import '../../features/player/presentation/controllers/playback_controller.dart';
import '../../features/player/presentation/widgets/mini_player.dart';

/// The persistent frame: tab content, the mini-player, and navigation that
/// changes shape with the window.
///
/// The mini-player lives here rather than inside any page, which is the whole
/// reason playback survives navigation — the widget that owns the video
/// surface never leaves the tree when a route changes.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playback = ref.watch(playbackControllerProvider);
    final showMiniPlayer = playback.hasSource && !playback.isExpanded;

    return AdaptiveNavigationScaffold(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: _onTap,
      body: shell,
      footer: showMiniPlayer ? const MiniPlayer() : null,
      floatingFooter: showMiniPlayer ? const MiniPlayer(floating: true) : null,
      destinations: [
        AdaptiveDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: l10n.navHome,
        ),
        AdaptiveDestination(
          icon: Icons.live_tv_outlined,
          selectedIcon: Icons.live_tv_rounded,
          label: l10n.navLive,
        ),
        AdaptiveDestination(
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
          label: l10n.navPrograms,
        ),
        AdaptiveDestination(
          icon: Icons.radio_outlined,
          selectedIcon: Icons.radio_rounded,
          label: l10n.navRadio,
        ),
        AdaptiveDestination(
          icon: Icons.bookmark_outline_rounded,
          selectedIcon: Icons.bookmark_rounded,
          label: l10n.navSaved,
        ),
      ],
    );
  }

  void _onTap(int index) {
    // Tapping the active tab pops it to its root — standard behaviour, and the
    // fastest way back out of an article.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }
}
