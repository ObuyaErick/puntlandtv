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

/// The LIVE pill's counterpart: this channel exists but is not on air.
///
/// Deliberately quiet — an outline and a hollow dot, no fill — so a row of
/// channels reads as "these are live" at a glance rather than as two equally
/// loud states. Same heights as [LiveBadge], so the two swap without the
/// layout moving.
class OffAirBadge extends StatelessWidget {
  const OffAirBadge({super.key, this.compact = false, this.onDark = false});

  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark
        ? DarkTokens.onSurfaceVariant
        : context.scheme.onSurfaceVariant;
    final outline = onDark ? DarkTokens.outlineStrong : context.colors.outline;

    return Container(
      height: compact ? 22 : 32,
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11),
      decoration: BoxDecoration(
        color: onDark ? BrandPalette.navy.withValues(alpha: 0.88) : null,
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(color: outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: foreground, width: 1.2),
            ),
          ),
          const SizedBox(width: 6),
          // Flexible so a pill squeezed narrower than its word truncates
          // rather than overflowing. Somali's label is nearly twice English's.
          Flexible(
            child: Text(
              context.l10n.channelOffAir,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.overline.copyWith(
                color: foreground,
                fontSize: compact ? 10.5 : 11,
                letterSpacing: compact ? 1.05 : 0.99,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
