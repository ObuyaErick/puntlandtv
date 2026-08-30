import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.dart';

/// The green LIVE pill.
///
/// Uses the contrast-corrected accent, never the raw logo green — the badge
/// carries text, and `#1EA83C` on white is below 4.5:1.
class LiveBadge extends StatelessWidget {
  const LiveBadge({
    super.key,
    this.compact = false,
    this.onDark = false,
    this.trailing,
  });

  /// Small variant used inside the player chrome.
  final bool compact;
  final bool onDark;

  /// Optional text after the word LIVE, e.g. the current clock time.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = compact ? l10n.live : l10n.liveNow;
    final background = onDark ? LightTokens.accent : context.colors.accent;

    return Container(
      height: compact ? 22 : 32,
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 6,
            height: compact ? 6 : 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            trailing == null ? label : '$label · $trailing',
            style: context.text.overline.copyWith(
              color: Colors.white,
              fontSize: compact ? 10.5 : 11,
              letterSpacing: compact ? 1.05 : 0.99,
            ),
          ),
        ],
      ),
    );
  }
}
