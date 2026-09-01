import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/providers/preferences_providers.dart';
import '../../core/responsive/window_size.dart';
import '../../features/settings/domain/entities/app_preferences.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pltv_logo.dart';
import '../core/localised.dart';
import '../core/providers/console_providers.dart';
import '../features/auth/domain/entities/console_user.dart';

/// A console destination, gated on a capability.
class ConsoleDestination {
  const ConsoleDestination({
    required this.route,
    required this.icon,
    required this.label,
    this.requires,
    this.badgeCount,
  });

  final String route;
  final IconData icon;
  final String Function(AppL10n) label;

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

List<ConsoleDestination> consoleDestinations({int articleBadge = 0}) => [
  ConsoleDestination(
    route: '/overview',
    icon: Icons.dashboard_outlined,
    label: (l) => l.navOverview,
    requires: null,
  ),
  ConsoleDestination(
    route: '/articles',
    icon: Icons.article_outlined,
    label: (l) => l.navArticles,
    requires: Capability.writeOwnArticles,
    badgeCount: articleBadge,
  ),
  ConsoleDestination(
    route: '/programs',
    icon: Icons.video_library_outlined,
    label: (l) => l.navProgramsConsole,
    requires: Capability.manageLibrary,
  ),
  ConsoleDestination(
    route: '/live',
    icon: Icons.podcasts_outlined,
    label: (l) => l.navLiveControl,
    requires: Capability.manageBroadcast,
  ),
  ConsoleDestination(
    route: '/schedule',
    icon: Icons.calendar_month_outlined,
    label: (l) => l.navSchedule,
    requires: Capability.manageBroadcast,
  ),
  ConsoleDestination(
    route: '/push',
    icon: Icons.campaign_outlined,
    label: (l) => l.navPush,
    requires: Capability.sendPush,
  ),
  ConsoleDestination(
    route: '/media',
    icon: Icons.perm_media_outlined,
    label: (l) => l.navMedia,
    requires: Capability.manageLibrary,
  ),
  ConsoleDestination(
    route: '/categories',
    icon: Icons.sell_outlined,
    label: (l) => l.navCategories,
    requires: Capability.manageTaxonomy,
  ),
  ConsoleDestination(
    route: '/users',
    icon: Icons.group_outlined,
    label: (l) => l.navUsers,
    requires: Capability.manageUsers,
  ),
  ConsoleDestination(
    route: '/config',
    icon: Icons.tune_outlined,
    label: (l) => l.navAppConfig,
    requires: Capability.manageConfig,
  ),
];

/// The console frame: a persistent expanded rail from expanded up, a drawer at
/// compact and medium.
///
/// The console's rail is the 236dp expanded variant rather than the app's 80dp
/// collapsed one — ten destinations with names like "Live control" are not
/// legible as 9px labels under an icon, and this product has the width for it.
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
        final rail = _ConsoleRail(
          destinations: destinations,
          currentRoute: currentRoute,
          onNavigate: onNavigate,
          user: user,
          // The drawer always shows labels: there is no width pressure there,
          // and an icon-only drawer is just a worse rail.
          collapsed: collapsed && size.isAtLeastExpanded,
        );

        if (size.isAtLeastExpanded) {
          return Scaffold(
            body: Row(
              children: [
                rail,
                VerticalDivider(width: 1, color: context.colors.outline),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const PltvLockup(),
            backgroundColor: context.scheme.surface,
          ),
          drawer: Drawer(width: Layout.railExpandedWidth, child: rail),
          body: child,
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
  });

  final List<ConsoleDestination> destinations;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final ConsoleUser user;
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: collapsed ? _collapsedWidth : Layout.railExpandedWidth,
      // Navy, per artboard 11A — the console rail is a dark ground, which is
      // what separates the tool chrome from the white content it frames.
      color: BrandPalette.navy,
      padding: const EdgeInsets.symmetric(vertical: 18),
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
                  horizontal: collapsed ? 0 : Spacing.chip,
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
            const Divider(height: 1, color: DarkTokens.outline),
            // The single point of language switching for the whole console.
            // Without it the only switch was on the sign-in page, which left a
            // signed-in editor with no way to change language at all.
            _ConsoleLocaleSwitch(collapsed: collapsed),
            const Divider(height: 1, color: DarkTokens.outline),
            _UserChip(user: user, collapsed: collapsed),
          ],
        ),
      ),
    );
  }

  /// 80dp, per artboard 11B.
  static const _collapsedWidth = 80.0;
}

/// Brand lockup plus the collapse control.
class _RailHeader extends ConsumerWidget {
  const _RailHeader({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final toggle = IconButton(
      onPressed: ref.read(railCollapsedProvider.notifier).toggle,
      tooltip: collapsed ? l10n.expandSidebar : l10n.collapseSidebar,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: Icon(
        collapsed
            ? Icons.keyboard_double_arrow_right_rounded
            : Icons.keyboard_double_arrow_left_rounded,
        size: 18,
        color: DarkTokens.onSurfaceVariant,
      ),
    );

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Spacing.listRhythm),
        child: Column(
          children: [
            const PltvMark(height: 26, onDark: true),
            const SizedBox(height: Spacing.chip),
            toggle,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.listRhythm,
        0,
        Spacing.chip,
        Spacing.gutter,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PltvLockup(onDark: true),
                const SizedBox(height: 6),
                Text(
                  l10n.consoleTitle.toUpperCase(),
                  style: context.text.overline.copyWith(
                    fontSize: 10,
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          toggle,
        ],
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
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                // 56×52 with a 10dp radius, per artboard 11B.
                width: 56,
                height: 52,
                decoration: BoxDecoration(
                  color: selected
                      ? DarkTokens.surfaceRaised
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      destination.icon,
                      size: 19,
                      color: selected
                          ? Colors.white
                          : DarkTokens.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: context.text.overline.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.2,
                          color: selected
                              ? Colors.white
                              : DarkTokens.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
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
        padding: const EdgeInsets.only(bottom: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.button),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.chip),
            decoration: BoxDecoration(
              // Surface+1 rather than an accent fill: the rail is already
              // dark, so the selected row reads by lift, not by colour.
              color: selected ? DarkTokens.surfaceRaised : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.button),
            ),
            child: Row(
              children: [
                Icon(
                  destination.icon,
                  size: 19,
                  color: selected ? Colors.white : DarkTokens.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.cardInternal),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label.copyWith(
                      color: selected ? Colors.white : DarkTokens.onSurface,
                    ),
                  ),
                ),
                // Badge counts appear only in the expanded rail, where there
                // is room for them beside the label rather than crowding an
                // icon.
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DarkTokens.surfaceRaised,
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child: Text(
                      '$badge',
                      style: context.text.overline.copyWith(
                        fontSize: 10,
                        color: DarkTokens.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EN / SO toggle in the rail.
class _ConsoleLocaleSwitch extends ConsumerWidget {
  const _ConsoleLocaleSwitch({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(preferencesProvider).locale;
    final controller = ref.read(preferencesProvider.notifier);

    Widget option(String label, LocalePreference value) {
      final selected = current == value;
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => controller.setLocale(value),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? DarkTokens.surfaceRaised : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: context.text.overline.copyWith(
                fontSize: 10,
                color: selected ? Colors.white : DarkTokens.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: context.l10n.consoleLanguage,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : Spacing.cardInternal,
          vertical: Spacing.chip,
        ),
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            option('EN', LocalePreference.english),
            const SizedBox(width: 4),
            option('SO', LocalePreference.somali),
          ],
        ),
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
      decoration: const BoxDecoration(
        color: DarkTokens.surfaceRaised,
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
        padding: const EdgeInsets.only(top: Spacing.cardInternal),
        child: Tooltip(message: '${user.name} · $roleLabel', child: avatar),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(Spacing.cardInternal),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: DarkTokens.surfaceRaised,
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
          ),
          const SizedBox(width: Spacing.cardInternal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.label.copyWith(color: Colors.white),
                ),
                Text(
                  roleLabel.toUpperCase(),
                  style: context.text.overline.copyWith(
                    fontSize: 9.5,
                    color: DarkTokens.onSurfaceVariant,
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
            icon: const Icon(
              Icons.logout_rounded,
              size: 18,
              color: DarkTokens.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
