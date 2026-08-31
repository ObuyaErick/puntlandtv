import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.dart';
import 'window_size.dart';

/// One navigation destination, shared by the bar and the rail.
class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Rendered only in the expanded rail, where there is room for it to sit
  /// right-aligned against the label.
  final int? badgeCount;
}

/// Navigation that changes shape with the window, per artboard 7A:
///
/// * **Compact** — bottom bar with five destinations, [footer] docked directly
///   above it.
/// * **Medium** — 80dp rail with icons and labels; [footer] spans the content
///   pane only, not the rail.
/// * **Expanded and up** — the same rail, and [footer] is expected to float
///   over the content rather than dock (the caller positions it).
///
/// The scaffold owns the chrome and nothing else; what goes in the content
/// pane, and whether it is a list-detail split, is the caller's decision.
class AdaptiveNavigationScaffold extends StatelessWidget {
  const AdaptiveNavigationScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.footer,
    this.floatingFooter,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Docked above the bottom bar at compact, above the content pane at medium.
  final Widget? footer;

  /// Used instead of [footer] at expanded and above, positioned bottom-right
  /// over the content.
  final Widget? floatingFooter;

  @override
  Widget build(BuildContext context) {
    return WindowSizeScope(
      builder: (context, size) {
        if (size.isCompact) return _buildCompact(context);
        return _buildRail(context, size);
      },
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 260ms matches the player's collapse/expand curve, so the dock
          // animates at the same rate the player shrinks into it.
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: footer ?? const SizedBox(width: double.infinity),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.colors.outlineSubtle),
              ),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRail(BuildContext context, WindowSizeClass size) {
    final content = Stack(
      children: [
        Positioned.fill(child: body),
        if (size.isAtLeastExpanded && floatingFooter != null)
          Positioned(
            right: Spacing.gutter,
            bottom: Spacing.gutter,
            child: SizedBox(
              width: Layout.miniPlayerFloatingWidth,
              child: floatingFooter,
            ),
          ),
      ],
    );

    return Scaffold(
      body: Row(
        children: [
          _NavRail(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          VerticalDivider(width: 1, color: context.colors.outlineSubtle),
          Expanded(
            child: Column(
              children: [
                Expanded(child: content),
                // At medium the footer still docks, but only across the
                // content pane — running it under the rail would make the
                // rail look like it belongs to the player.
                if (!size.isAtLeastExpanded && footer != null)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: footer,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Layout.railWidth,
      color: context.scheme.surface,
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: Spacing.cardInternal),
            for (var i = 0; i < destinations.length; i++)
              _RailDestination(
                destination: destinations[i],
                selected: i == selectedIndex,
                onTap: () => onDestinationSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  const _RailDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AdaptiveDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          // 56dp target per the canvas, comfortably over the 48dp minimum.
          height: 56,
          width: Layout.railWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // An active pill, never a full-width fill — a fill turns the
                  // rail into a series of stripes.
                  color: selected
                      ? context.colors.accentContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 20,
                  color: selected
                      ? context.colors.onAccentContainer
                      : context.scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.text.overline.copyWith(
                    fontSize: 9,
                    letterSpacing: 0.2,
                    color: selected
                        ? context.scheme.primary
                        : context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
