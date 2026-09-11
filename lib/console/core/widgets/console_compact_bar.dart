import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/tokens.dart';

/// How a page inside the console shell opens the navigation, when there is
/// no rail to show it.
///
/// Provided by the shell at compact width only. The page draws the bar with
/// the menu button in it — so the bar can carry the page's own title and
/// primary action, as the design's phone artboard does — and this is the
/// one thing about the shell it needs to know.
class ConsoleShellScope extends InheritedWidget {
  const ConsoleShellScope({
    super.key,
    required this.openNavigation,
    required super.child,
  });

  final VoidCallback openNavigation;

  /// The navigation opener, or null where the rail is already on screen — or
  /// where there is no shell at all, as in a test pumping one page.
  static VoidCallback? openNavigationOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ConsoleShellScope>()
      ?.openNavigation;

  @override
  bool updateShouldNotify(ConsoleShellScope oldWidget) =>
      openNavigation != oldWidget.openNavigation;
}

/// The console's phone header: navy, full-bleed under the status bar, with
/// the menu button, the page's title in the serif, and at most one action.
///
/// One action rather than a row: at 320dp the title needs the width, and the
/// primary action is the one worth a thumb-reach — the rest of a page's
/// actions stay on the page.
class ConsoleCompactBar extends StatelessWidget {
  const ConsoleCompactBar({super.key, required this.title, this.action});

  final String title;

  /// Typically an [IconButton]; drawn in white.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final openNavigation = ConsoleShellScope.openNavigationOf(context);

    return Material(
      color: BrandPalette.navy,
      child: SafeArea(
        bottom: false,
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                if (openNavigation != null)
                  IconButton(
                    key: const Key('open-navigation'),
                    tooltip: context.l10n.openNavigation,
                    onPressed: openNavigation,
                    icon: const Icon(Icons.menu_rounded),
                  )
                else
                  const SizedBox(width: Spacing.listRhythm - 4),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.headline.copyWith(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                ?action,
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
