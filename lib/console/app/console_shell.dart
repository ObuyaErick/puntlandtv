import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/responsive/window_size.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pltv_logo.dart';
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
        final rail = _ConsoleRail(
          destinations: destinations,
          currentRoute: currentRoute,
          onNavigate: onNavigate,
          user: user,
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
  });

  final List<ConsoleDestination> destinations;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final ConsoleUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Container(
      width: Layout.railExpandedWidth,
      color: context.scheme.surface,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.listRhythm,
                Spacing.gutter,
                Spacing.listRhythm,
                Spacing.gutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PltvLockup(),
                  const SizedBox(height: 6),
                  Text(
                    l10n.consoleTitle.toUpperCase(),
                    style: context.text.overline.copyWith(
                      fontSize: 10,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.chip),
                children: [
                  for (final destination in destinations)
                    _RailItem(
                      destination: destination,
                      selected: currentRoute == destination.route,
                      onTap: () => onNavigate(destination.route),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            _UserChip(user: user),
          ],
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
  });

  final ConsoleDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = destination.badgeCount ?? 0;

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
              color: selected
                  ? context.colors.accentContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.button),
            ),
            child: Row(
              children: [
                Icon(
                  destination.icon,
                  size: 19,
                  color: selected
                      ? context.colors.onAccentContainer
                      : context.scheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.cardInternal),
                Expanded(
                  child: Text(
                    destination.label(context.l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label.copyWith(
                      color: selected
                          ? context.scheme.primary
                          : context.scheme.onSurface,
                    ),
                  ),
                ),
                // Badge counts appear only in the expanded rail, where there is
                // room for them beside the label rather than crowding an icon.
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.skeleton,
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child: Text(
                      '$badge',
                      style: context.text.overline.copyWith(
                        fontSize: 10,
                        color: context.scheme.onSurfaceVariant,
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

class _UserChip extends ConsumerWidget {
  const _UserChip({required this.user});

  final ConsoleUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final roleLabel = switch (user.role) {
      ConsoleRole.journalist => l10n.roleJournalist,
      ConsoleRole.editor => l10n.roleEditor,
      ConsoleRole.operations => l10n.roleOperations,
      ConsoleRole.admin => l10n.roleAdmin,
    };

    return Padding(
      padding: const EdgeInsets.all(Spacing.cardInternal),
      child: Row(
        children: [
          Container(
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
                  style: context.text.label.copyWith(
                    color: context.scheme.primary,
                  ),
                ),
                Text(
                  roleLabel,
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
