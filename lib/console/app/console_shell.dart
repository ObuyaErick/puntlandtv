import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/providers/preferences_providers.dart';
import '../../core/responsive/window_size.dart';
import '../../features/settings/domain/entities/app_preferences.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens.dart';
import '../core/localised.dart';
import '../core/providers/console_providers.dart';
import '../core/widgets/console_compact_bar.dart';
import '../features/auth/domain/entities/console_user.dart';
import 'console_routes.dart';

/// A console destination, gated on a capability.
class ConsoleDestination {
  const ConsoleDestination({
    required this.route,
    required this.icon,
    required this.label,
    required this.shortLabel,
    this.requires,
    this.badgeCount,
  });

  final String route;
  final IconData icon;
  final String Function(AppL10n) label;

  /// One short word for the collapsed rail, where the label sits under the
  /// icon in a 56dp tile: "Live" rather than "Live control".
  final String Function(AppL10n) shortLabel;

  /// Destinations a role cannot use are not rendered. That is not security —
  /// the admin API enforces the same rules — but a Journalist should not be
  /// looking at a Live control tab they cannot open.
  ///
  /// Null means every signed-in user sees it. Overview is the landing page and
  /// is deliberately ungated: gating it on `writeOwnArticles` hid it from
  /// Operations, whose whole job is the on-air status it leads with.
  final Capability? requires;

  final int? badgeCount;
}

/// The rail, in branch order. See [ConsoleRoutes.branches] — the router matches
/// this list by index, so the order here is not cosmetic.
List<ConsoleDestination> consoleDestinations({int articleBadge = 0}) => [
  ConsoleDestination(
    route: ConsoleRoutes.overview,
    icon: Icons.home_outlined,
    label: (l) => l.navOverview,
    shortLabel: (l) => l.navShortOverview,
    requires: null,
  ),
  ConsoleDestination(
    route: ConsoleRoutes.articles,
    icon: Icons.notes_rounded,
    label: (l) => l.navArticles,
    shortLabel: (l) => l.navShortArticles,
    requires: Capability.writeOwnArticles,
    badgeCount: articleBadge,
  ),
  ConsoleDestination(
    route: ConsoleRoutes.programs,
    icon: Icons.video_library_outlined,
    label: (l) => l.navProgramsConsole,
    shortLabel: (l) => l.navShortPrograms,
    requires: Capability.manageLibrary,
  ),
  ConsoleDestination(
    route: ConsoleRoutes.live,
    icon: Icons.videocam_outlined,
    label: (l) => l.navLiveControl,
    shortLabel: (l) => l.navShortLiveControl,
    requires: Capability.manageBroadcast,
  ),
  ConsoleDestination(
    route: ConsoleRoutes.schedule,
    icon: Icons.calendar_today_outlined,
    label: (l) => l.navSchedule,
    shortLabel: (l) => l.navShortSchedule,
    requires: Capability.manageBroadcast,
  ),
  ConsoleDestination(
    route: ConsoleRoutes.push,
    icon: Icons.campaign_outlined,
    label: (l) => l.navPush,
    shortLabel: (l) => l.navShortPush,
    requires: Capability.sendPush,
  ),
  ConsoleDestination(
    route: ConsoleRoutes.media,
    icon: Icons.perm_media_outlined,
    label: (l) => l.navMedia,
    shortLabel: (l) => l.navShortMedia,
    requires: Capability.manageLibrary,
  ),
  // No Categories entry: the taxonomy exists to file articles, so it is a
  // screen inside Articles (`/articles/categories`) rather than a destination
  // three rows away from the stories it organises.
  ConsoleDestination(
    route: ConsoleRoutes.users,
    icon: Icons.person_outline_rounded,
    label: (l) => l.navUsers,
    shortLabel: (l) => l.navShortUsers,
    requires: Capability.manageUsers,
  ),
  ConsoleDestination(
    route: ConsoleRoutes.config,
    icon: Icons.tune_outlined,
    label: (l) => l.navAppConfig,
    shortLabel: (l) => l.navShortAppConfig,
    requires: Capability.manageConfig,
  ),
];

/// The console frame, at three widths:
///
/// * **Expanded and up** — the full rail, named destinations. An operator can
///   collapse it to icons from its footer.
/// * **Medium** — the collapsed rail: icons over one short word each, per the
///   channel-list design review's tablet artboard.
/// * **Compact** — no rail. Each page leads with the navy [ConsoleCompactBar],
///   whose menu button opens the full rail as a drawer.
///
/// The rail is white — the page's own ground, divided from the content by a
/// hairline — so the one dark surface in the chrome is the selected item, the
/// same navy the control rooms are made of.
class ConsoleShell extends ConsumerWidget {
  const ConsoleShell({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.child,
    this.articleBadge = 0,
  });

  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final Widget child;
  final int articleBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return child;

    final destinations = consoleDestinations(articleBadge: articleBadge)
        .where((d) => d.requires == null || user.can(d.requires!))
        .toList(growable: false);

    return WindowSizeScope(
      builder: (context, size) {
        final collapsed = ref.watch(railCollapsedProvider);

        if (size.isAtLeastMedium) {
          return Scaffold(
            body: Row(
              children: [
                _ConsoleRail(
                  destinations: destinations,
                  currentRoute: currentRoute,
                  onNavigate: onNavigate,
                  user: user,
                  // Medium has no room for names, so it is always icons; the
                  // collapse control is only offered where there is a choice.
                  collapsed: !size.isAtLeastExpanded || collapsed,
                  canCollapse: size.isAtLeastExpanded,
                ),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          drawer: Drawer(
            width: Layout.railExpandedWidth,
            backgroundColor: context.scheme.surface,
            shape: const RoundedRectangleBorder(),
            // The drawer has to be dismissed by whoever navigates from it —
            // nothing else pops it, and picking a destination and then still
            // looking at the rail reads as a tap that did not register.
            child: Builder(
              builder: (context) => _ConsoleRail(
                destinations: destinations,
                currentRoute: currentRoute,
                onNavigate: (route) {
                  Scaffold.of(context).closeDrawer();
                  onNavigate(route);
                },
                user: user,
                collapsed: false,
                canCollapse: false,
              ),
            ),
          ),
          // The page draws the bar with the menu button in it, so the bar can
          // carry the page's title and action; this is how it opens the rail.
          body: Builder(
            builder: (context) => ConsoleShellScope(
              openNavigation: Scaffold.of(context).openDrawer,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _ConsoleRail extends ConsumerWidget {
  const _ConsoleRail({
    required this.destinations,
    required this.currentRoute,
    required this.onNavigate,
    required this.user,
    required this.collapsed,
    required this.canCollapse,
  });

  final List<ConsoleDestination> destinations;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final ConsoleUser user;
  final bool collapsed;

  /// Whether to offer the collapse control. Not at medium, where the rail is
  /// collapsed because there is no room, and not in the phone drawer.
  final bool canCollapse;

  /// 72dp, per the design review's tablet artboard.
  static const collapsedWidth = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: collapsed ? collapsedWidth : Layout.railExpandedWidth,
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(right: BorderSide(color: context.colors.outline)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: collapsed
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.stretch,
          children: [
            _RailHeader(collapsed: collapsed),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 0 : Spacing.cardInternal,
                ),
                children: [
                  for (final destination in destinations)
                    _RailItem(
                      destination: destination,
                      selected: currentRoute == destination.route,
                      collapsed: collapsed,
                      onTap: () => onNavigate(destination.route),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: context.colors.outline),
            // The single point of language switching for the whole console.
            // Without it the only switch was on the sign-in page, which left a
            // signed-in editor with no way to change language at all.
            _RailFooterControls(collapsed: collapsed, canCollapse: canCollapse),
            Divider(height: 1, color: context.colors.outline),
            _UserChip(user: user, collapsed: collapsed),
          ],
        ),
      ),
    );
  }
}

/// The brand tile and the product name.
///
/// A 28dp navy tile with the logo's green dot, then "Puntland TV" in the serif
/// over "STAFF CONSOLE" — per the design review, where the lockup is the
/// console's rather than the app's full logo.
class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    const tile = _BrandTile();

    if (collapsed) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 22, 0, Spacing.gutter),
        child: tile,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, Spacing.cardInternal, 28),
      child: Row(
        children: [
          tile,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  BrandLockup.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.cardTitle.copyWith(
                    fontSize: 17,
                    height: 20 / 17,
                    color: context.scheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.consoleTitle.toUpperCase(),
                  style: context.text.overline.copyWith(
                    fontSize: 10.5,
                    letterSpacing: 1.4,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The brand mark reduced to a tile: navy, with the logo's green dot.
class _BrandTile extends StatelessWidget {
  const _BrandTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BrandPalette.navy,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: BrandPalette.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.collapsed,
  });

  final ConsoleDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;

  /// The selected item is the one dark surface in the rail: navy fill, white
  /// label, and the icon in the brand green.
  Color _iconColor(BuildContext context) =>
      selected ? DarkTokens.accent : context.scheme.onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    final badge = destination.badgeCount ?? 0;
    final label = destination.label(context.l10n);

    if (collapsed) {
      return Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Center(
            child: Tooltip(
              message: label,
              child: Material(
                color: selected ? context.scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  hoverColor: selected
                      ? null
                      : context.scheme.surfaceContainerLow,
                  child: SizedBox(
                    // 56×52 with a 10dp radius, per the tablet artboard.
                    width: 56,
                    height: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          destination.icon,
                          size: 20,
                          color: _iconColor(context),
                        ),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            destination.shortLabel(context.l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: context.text.meta.copyWith(
                              fontSize: 10.5,
                              height: 1.2,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? Colors.white
                                  : context.scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: selected ? context.scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.button),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.button),
            hoverColor: selected ? null : context.scheme.surfaceContainerLow,
            child: ConstrainedBox(
              // A minimum rather than a height: a Somali label that needs two
              // lines grows the item instead of being cut off.
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.cardInternal,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      destination.icon,
                      size: 20,
                      color: _iconColor(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: context.text.body.copyWith(
                          fontSize: 15,
                          height: 20 / 15,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? Colors.white
                              : context.scheme.onSurface,
                        ),
                      ),
                    ),
                    // Badge counts appear only in the expanded rail, where
                    // there is room for them beside the label rather than
                    // crowding an icon.
                    if (badge > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? DarkTokens.surfaceRaised
                              : context.scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(Radii.chip),
                        ),
                        child: Text(
                          '$badge',
                          style: context.text.overline.copyWith(
                            fontSize: 10,
                            color: selected
                                ? Colors.white
                                : context.scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The language switch and, where the rail can collapse, the control that
/// does it.
///
/// The collapse control lives down here rather than beside the brand, so the
/// rail's head is the lockup and nothing else, as the design draws it.
class _RailFooterControls extends ConsumerWidget {
  const _RailFooterControls({
    required this.collapsed,
    required this.canCollapse,
  });

  final bool collapsed;
  final bool canCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final toggle = canCollapse
        ? IconButton(
            onPressed: ref.read(railCollapsedProvider.notifier).toggle,
            tooltip: collapsed ? l10n.expandSidebar : l10n.collapseSidebar,
            constraints: const BoxConstraints.tightFor(
              width: kMinTapTarget,
              height: kMinTapTarget,
            ),
            icon: Icon(
              collapsed
                  ? Icons.keyboard_double_arrow_right_rounded
                  : Icons.keyboard_double_arrow_left_rounded,
              size: 18,
              color: context.scheme.onSurfaceVariant,
            ),
          )
        : null;

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.chip),
        child: Column(children: [const _ConsoleLocaleSwitch(), ?toggle]),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.cardInternal,
        Spacing.chip,
        4,
        Spacing.chip,
      ),
      child: Row(
        children: [const _ConsoleLocaleSwitch(), const Spacer(), ?toggle],
      ),
    );
  }
}

/// EN / SO toggle in the rail.
class _ConsoleLocaleSwitch extends ConsumerWidget {
  const _ConsoleLocaleSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(preferencesProvider).locale;
    final controller = ref.read(preferencesProvider.notifier);

    Widget option(String label, LocalePreference value) {
      final selected = current == value;
      return Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? context.scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => controller.setLocale(value),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 32,
              height: 26,
              alignment: Alignment.center,
              child: Text(
                label,
                style: context.text.overline.copyWith(
                  fontSize: 10,
                  color: selected
                      ? Colors.white
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: context.l10n.consoleLanguage,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option('EN', LocalePreference.english),
          const SizedBox(width: 4),
          option('SO', LocalePreference.somali),
        ],
      ),
    );
  }
}

class _UserChip extends ConsumerWidget {
  const _UserChip({required this.user, required this.collapsed});

  final ConsoleUser user;
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // One switch over `ConsoleRole` for the whole console, in `ConsoleLabels`.
    // The stored strings are prose, because the users screen reads them as
    // prose; the rail uppercases at render, exactly as its header already does
    // with the console title.
    final roleLabel = ConsoleLabels.role(l10n, user.role);

    final avatar = Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.scheme.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        user.initials,
        style: context.text.overline.copyWith(
          fontSize: 11,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
      ),
    );

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.cardInternal),
        child: Tooltip(message: '${user.name} · $roleLabel', child: avatar),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(Spacing.cardInternal),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: Spacing.cardInternal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.label.copyWith(
                    color: context.scheme.onSurface,
                  ),
                ),
                Text(
                  roleLabel.toUpperCase(),
                  style: context.text.overline.copyWith(
                    fontSize: 9.5,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            tooltip: l10n.signOut,
            constraints: const BoxConstraints.tightFor(
              width: kMinTapTarget,
              height: kMinTapTarget,
            ),
            icon: Icon(
              Icons.logout_rounded,
              size: 18,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
