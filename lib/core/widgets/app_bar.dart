import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/route_paths.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.dart';
import 'live_badge.dart';
import 'pltv_logo.dart';

/// The branded app bar: logo lockup left, LIVE badge and settings right.
///
/// The lockup reserves 188×36dp and must never be scaled below it. When the
/// bar cannot give it that — a 320dp phone, or any width at a large text
/// scale — the wordmark is dropped and the mark stands alone, which is the
/// canvas's stated rule and the reason this needs a `LayoutBuilder` rather
/// than a fixed row.
class PltvAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PltvAppBar({super.key, this.onLiveTap});

  final VoidCallback? onLiveTap;

  /// Lockup (188) + live badge (~90) + settings target (48) + gutters (26).
  static const _widthForWordmark = 352.0;

  /// Below this the badge loses its word and keeps only the dot.
  static const _widthForFullBadge = 320.0;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.only(left: Spacing.gutter, right: 6),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(bottom: BorderSide(color: context.colors.outlineSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Chrome is mostly type, so the space it needs grows with the
            // user's text setting.
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final available = constraints.maxWidth;
            final showWordmark = available >= _widthForWordmark * scale;
            final compactBadge = available < _widthForFullBadge * scale;

            return Row(
              // No `Spacer` beside the `Flexible`: both would carry flex 1 and
              // split the leftover space evenly, starving the lockup of half
              // the width it needs. `spaceBetween` pushes the trailing controls
              // right without competing for flex.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: PltvLockup(showWordmark: showWordmark)),
                if (onLiveTap != null)
                  InkWell(
                    onTap: onLiveTap,
                    borderRadius: BorderRadius.circular(6),
                    child: LiveBadge(compact: compactBadge),
                  ),
                IconButton(
                  onPressed: () => context.push(Routes.settings),
                  constraints: const BoxConstraints.tightFor(
                    width: kMinTapTarget,
                    height: kMinTapTarget,
                  ),
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 22,
                    color: context.scheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
