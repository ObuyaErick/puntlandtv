import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/route_paths.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.dart';
import 'live_badge.dart';
import 'pltv_logo.dart';

/// The branded app bar: logo lockup left, LIVE badge and settings right.
class PltvAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PltvAppBar({super.key, this.onLiveTap});

  final VoidCallback? onLiveTap;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.only(left: Spacing.gutter, right: 6),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(bottom: BorderSide(color: context.colors.outlineSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const PltvLockup(),
            const Spacer(),
            if (onLiveTap != null)
              InkWell(
                onTap: onLiveTap,
                borderRadius: BorderRadius.circular(6),
                child: const LiveBadge(),
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
        ),
      ),
    );
  }
}
