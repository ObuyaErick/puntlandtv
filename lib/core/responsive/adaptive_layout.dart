import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import 'window_size.dart';

/// Centres and caps content so it stops growing past a readable width.
///
/// Beyond the cap the extra width goes to the margins, not to the columns —
/// the canvas is explicit about this at Large and XL.
class ContentCap extends StatelessWidget {
  const ContentCap({
    super.key,
    required this.child,
    this.maxWidth = Layout.contentCap,
    this.padding = EdgeInsets.zero,
  });

  /// Caps at the reading measure rather than the content width. Use for
  /// article bodies; a hero image should sit outside this.
  const ContentCap.reading({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  }) : maxWidth = Layout.readingMeasure;

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Article body width, which is tighter on a landscape phone than on a desktop.
class ReadingColumn extends StatelessWidget {
  const ReadingColumn({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.readingMeasure),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

/// Presents [builder] as a bottom sheet on compact windows and a centred
/// dialog from medium up.
///
/// The canvas calls for this on the language picker and the share sheet: a
/// sheet anchored to the bottom of a 1440px window is a long way from the
/// control that opened it.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  if (context.windowSize.isAtLeastMedium) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Layout.dialogWidth),
          child: builder(context),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: builder,
  );
}

/// Whether a pointer is driving this session.
///
/// Hover fills and focus rings render only when true. On a touch device they
/// are noise — and a hover state that never resolves reads as a stuck
/// selection.
bool hasPointer(BuildContext context) {
  final navigationMode = MediaQuery.maybeNavigationModeOf(context);
  if (navigationMode == NavigationMode.directional) return true;

  return switch (Theme.of(context).platform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    _ => false,
  };
}

/// A row or tile that lights up under a pointer and shows a focus ring, and
/// does neither on touch.
class PointerAffordance extends StatefulWidget {
  const PointerAffordance({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final BorderRadius? borderRadius;

  @override
  State<PointerAffordance> createState() => _PointerAffordanceState();
}

class _PointerAffordanceState extends State<PointerAffordance> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final pointer = hasPointer(context);
    final radius = widget.borderRadius ?? BorderRadius.zero;

    // Selection tints; it never inverts. Inverting a selected row in a long
    // table turns a scan into a search for the one dark stripe.
    final background = widget.selected
        ? context.colors.accentContainer
        : (_hovered && pointer)
        ? context.scheme.surfaceContainerLow
        : Colors.transparent;

    return FocusableActionDetector(
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      mouseCursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: _focused && pointer
                ? Border.all(color: context.colors.link, width: 2)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
