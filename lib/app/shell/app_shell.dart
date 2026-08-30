import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/theme_context.dart';
import '../../features/player/presentation/controllers/playback_controller.dart';
import '../../features/player/presentation/widgets/mini_player.dart';

/// The persistent frame: tab content, the docked mini-player, the nav bar.
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

    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 260ms matches the collapse/expand transition specified in the
          // canvas, so the dock animates at the same rate the player shrinks.
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: showMiniPlayer
                ? const MiniPlayer()
                : const SizedBox(width: double.infinity),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.colors.outlineSubtle),
              ),
            ),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _onTap,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.live_tv_outlined),
                  selectedIcon: const Icon(Icons.live_tv_rounded),
                  label: l10n.navLive,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.grid_view_outlined),
                  selectedIcon: const Icon(Icons.grid_view_rounded),
                  label: l10n.navPrograms,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.radio_outlined),
                  selectedIcon: const Icon(Icons.radio_rounded),
                  label: l10n.navRadio,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bookmark_outline_rounded),
                  selectedIcon: const Icon(Icons.bookmark_rounded),
                  label: l10n.navSaved,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    // Tapping the active tab pops it to its root — standard behaviour, and the
    // fastest way back out of an article.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }
}
