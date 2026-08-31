import 'package:material_ui/material_ui.dart';

/// Material 3 window size classes, shared by the app and the console.
///
/// Breakpoints are transcribed from artboard 7A of the responsive canvas.
enum WindowSizeClass {
  /// < 600 — phones in portrait. Bottom nav, single column.
  compact,

  /// 600–839 — tablets in portrait, phones in landscape.
  medium,

  /// 840–1199 — tablets in landscape, small desktop windows.
  expanded,

  /// 1200–1599 — desktop.
  large,

  /// ≥ 1600 — wide desktop. Margins grow; columns do not.
  extraLarge;

  static const mediumMin = 600.0;
  static const expandedMin = 840.0;
  static const largeMin = 1200.0;
  static const extraLargeMin = 1600.0;

  static WindowSizeClass fromWidth(double width) {
    if (width >= extraLargeMin) return WindowSizeClass.extraLarge;
    if (width >= largeMin) return WindowSizeClass.large;
    if (width >= expandedMin) return WindowSizeClass.expanded;
    if (width >= mediumMin) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  bool get isCompact => this == WindowSizeClass.compact;

  /// True from [medium] up — where sheets become dialogs and the bottom bar
  /// becomes a rail.
  bool get isAtLeastMedium => index >= WindowSizeClass.medium.index;

  /// True from [expanded] up — where list-detail appears and the mini-player
  /// un-docks to float.
  bool get isAtLeastExpanded => index >= WindowSizeClass.expanded.index;

  bool get isAtLeastLarge => index >= WindowSizeClass.large.index;
}

/// Layout constants that hold across both products.
abstract final class Layout {
  /// Body text caps here (≈68 characters) and centres. A hero image may bleed
  /// wider; text never does.
  static const readingMeasure = 680.0;

  /// Tighter cap for landscape phones, where 728dp of available width would
  /// otherwise produce an unreadable line.
  static const readingMeasureLandscape = 600.0;

  /// Content stops growing here; beyond it the margins take the extra width.
  static const contentCap = 1160.0;

  /// Collapsed navigation rail.
  static const railWidth = 80.0;

  /// Expanded rail, the only place badge counts appear.
  static const railExpandedWidth = 236.0;

  /// The docked mini-player bar at compact width.
  static const miniPlayerHeight = 58.0;

  /// The floating mini-player at expanded and above.
  static const miniPlayerFloatingWidth = 360.0;

  /// Vertical space the player chrome needs. Controls are measured against
  /// this reserved band, never against whatever the 16:9 box has left over —
  /// that mistake is what made the controls overflow by 12px at 360dp.
  static const playerControlBand = 132.0;

  /// Below this width the transport row drops its skip buttons to icon-only
  /// and folds quality/fullscreen into one overflow button.
  static const transportCollapseWidth = 360.0;

  /// Console: the article editor opens as a panel this wide at expanded+.
  static const sidePanelWidth = 560.0;

  /// Sheets promoted to dialogs are this wide.
  static const dialogWidth = 400.0;
}

/// Resolves the size class from the *surface being laid out*, not the window.
///
/// This distinction is load-bearing. The player shell is used both full-width
/// and inside the expanded detail pane, where the window is wide but the player
/// is not. Reading `MediaQuery.sizeOf(context).width` there gives the wrong
/// answer and lays out chrome that does not fit.
class WindowSizeScope extends StatelessWidget {
  const WindowSizeScope({super.key, required this.builder});

  final Widget Function(BuildContext context, WindowSizeClass size) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return _InheritedWindowSize(
          size: WindowSizeClass.fromWidth(width),
          child: Builder(
            builder: (context) =>
                builder(context, WindowSizeClass.fromWidth(width)),
          ),
        );
      },
    );
  }
}

class _InheritedWindowSize extends InheritedWidget {
  const _InheritedWindowSize({required this.size, required super.child});

  final WindowSizeClass size;

  @override
  bool updateShouldNotify(_InheritedWindowSize old) => old.size != size;
}

extension WindowSizeX on BuildContext {
  /// The size class of the nearest enclosing [WindowSizeScope], falling back to
  /// the window itself.
  ///
  /// Prefer [WindowSizeScope] with an explicit builder inside anything that can
  /// be embedded in a pane; this accessor is for whole screens.
  WindowSizeClass get windowSize {
    final scope = dependOnInheritedWidgetOfExactType<_InheritedWindowSize>();
    return scope?.size ??
        WindowSizeClass.fromWidth(MediaQuery.sizeOf(this).width);
  }

  /// True when the window is wider than it is tall. Drives the immersive
  /// player and the landscape reading measure.
  bool get isLandscape {
    final size = MediaQuery.sizeOf(this);
    return size.width > size.height;
  }

  /// The reading measure to use here.
  double get readingMeasure => isLandscape && !windowSize.isAtLeastExpanded
      ? Layout.readingMeasureLandscape
      : Layout.readingMeasure;
}
