import 'package:material_ui/material_ui.dart';

import '../../../core/responsive/window_size.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/tokens.dart';

/// Opens [builder] as a right-hand side panel from expanded up, and as a
/// full-screen route at compact widths.
///
/// The panel exists so an editor keeps the list in view while working on one
/// row — losing that context is what makes a full-screen editor feel like
/// leaving the app. Below 840dp there is no room for both, so the full screen
/// is the honest answer rather than a 300dp panel nothing fits in.
Future<T?> showSidePanel<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? barrierLabel,
}) {
  if (!context.windowSize.isAtLeastExpanded) {
    return Navigator.of(context)
        .push<T>(MaterialPageRoute(builder: builder, fullscreenDialog: true));
  }

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel:
        barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: Layout.sidePanelWidth,
          height: double.infinity,
          child: Material(
            color: context.scheme.surface,
            child: builder(context),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      );
    },
  );
}

/// Standard panel chrome: title, close button, scrollable body, footer actions.
class SidePanelScaffold extends StatelessWidget {
  const SidePanelScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Footer actions, pinned so they stay reachable however long the form is.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            Spacing.gutter,
            Spacing.listRhythm,
            Spacing.chip,
            Spacing.listRhythm,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.colors.outline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.title.copyWith(
                        color: context.scheme.primary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.text.meta.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                constraints: const BoxConstraints.tightFor(
                  width: kMinTapTarget,
                  height: kMinTapTarget,
                ),
                icon: const Icon(Icons.close_rounded, size: 22),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.gutter),
            child: child,
          ),
        ),
        if (actions.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(Spacing.listRhythm),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.colors.outline)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in actions) ...[
                  action,
                  const SizedBox(width: Spacing.chip),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
