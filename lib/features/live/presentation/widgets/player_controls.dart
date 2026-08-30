import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/live_badge.dart';
import '../../../player/presentation/controllers/playback_controller.dart';

/// The control cluster from the canvas: LIVE badge and track, transport row,
/// volume, quality and fullscreen.
///
/// Always renders on navy regardless of theme — video chrome does not flip
/// with the app's brightness.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.state,
    required this.onPlayPause,
    required this.onMute,
    required this.onFullscreen,
    this.onCollapse,
  });

  final PlaybackState state;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final VoidCallback onFullscreen;
  final VoidCallback? onCollapse;

  /// Intrinsic heights of the three rows. The controls live inside a 16:9
  /// box, so the space available to them is a function of device *width*:
  /// 219px at 390dp but only 202px at 360dp and 180px at 320dp. Hard-coded
  /// spacing that fits the widest phone overflows the common one.
  static const _badgeRow = 22.0;
  static const _primaryButton = 60.0;
  static const _secondaryRow = kMinTapTarget;

  /// Design values, used whenever there is room for them.
  static const _maxPadding = 22.0;
  static const _maxGap = 20.0;

  /// Below this the secondary row is dropped rather than squeezed — mute and
  /// fullscreen are reachable elsewhere, and shrinking a 48dp target to make
  /// room is the one trade this must never make.
  static const _minGap = 8.0;
  static const _minPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // The decoration lives outside the LayoutBuilder on purpose. `Container`
    // insets its child by the border, so by the time constraints reach the
    // builder they are already net of it — meaning a change to the decoration
    // cannot silently eat the space the rows were measured against.
    return Container(
      decoration: BoxDecoration(
        // A bottom-weighted scrim keeps the controls legible over any frame
        // without the cost of a blur layer.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colors.playerSurface.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: _buildAdaptive(context),
    );
  }

  Widget _buildAdaptive(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight;

        final minWithSecondary =
            2 * _minPadding +
            _badgeRow +
            _minGap +
            _primaryButton +
            _minGap +
            _secondaryRow;
        final showSecondary =
            !available.isFinite || available >= minWithSecondary;

        final content =
            _badgeRow + _primaryButton + (showSecondary ? _secondaryRow : 0);
        final gapCount = showSecondary ? 2 : 1;
        final spacingBudget = 2 * _maxPadding + gapCount * _maxGap;

        double padding;
        double gap;
        if (!available.isFinite || available - content >= spacingBudget) {
          padding = _maxPadding;
          gap = _maxGap;
        } else {
          // Scale gaps and padding together, then give padding exactly the
          // remainder so the column consumes the available height and no more.
          final slack = math.max(0.0, available - content);
          final scale = (slack / spacingBudget).clamp(0.0, 1.0);
          gap = _maxGap * scale;
          padding = math.max(0, (slack - gapCount * gap) / 2);
        }

        return _buildControls(
          context,
          padding: padding,
          gap: gap,
          showSecondary: showSecondary,
        );
      },
    );
  }

  Widget _buildControls(
    BuildContext context, {
    required double padding,
    required double gap,
    required bool showSecondary,
  }) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order matters and matches the canvas: status, then transport,
          // then the secondary controls.
          SizedBox(
            height: _badgeRow,
            child: Row(
              children: [
                const LiveBadge(compact: true, onDark: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.playerControlTrack,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GhostButton(
                icon: Icons.replay_10_rounded,
                label: l10n.a11yPlay,
                onPressed: null,
              ),
              const SizedBox(width: 30),
              _PrimaryButton(
                isPlaying: state.isPlaying,
                isBuffering: state.isBuffering,
                onPressed: onPlayPause,
              ),
              const SizedBox(width: 30),
              _GhostButton(
                icon: Icons.forward_10_rounded,
                label: l10n.a11yPause,
                onPressed: null,
              ),
            ],
          ),
          if (showSecondary) ...[
            SizedBox(height: gap),
            SizedBox(
              height: _secondaryRow,
              child: Row(
                children: [
                  _GhostButton(
                    icon: state.isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    label: l10n.a11yMute,
                    onPressed: onMute,
                  ),
                  const Spacer(),
                  if (onCollapse != null)
                    _GhostButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      label: l10n.a11yCollapsePlayer,
                      onPressed: onCollapse,
                    ),
                  _GhostButton(
                    icon: Icons.fullscreen_rounded,
                    label: l10n.a11yFullscreen,
                    onPressed: onFullscreen,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: isPlaying ? l10n.a11yPause : l10n.a11yPlay,
      child: InkResponse(
        onTap: onPressed,
        radius: 36,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: isBuffering
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: BrandPalette.navy,
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 30,
                  color: BrandPalette.navy,
                ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      constraints: const BoxConstraints.tightFor(
        width: kMinTapTarget,
        height: kMinTapTarget,
      ),
      icon: Icon(
        icon,
        size: 24,
        color: onPressed == null
            ? context.colors.onPlayerSurfaceVariant.withValues(alpha: 0.4)
            : context.colors.onPlayerSurfaceVariant,
      ),
    );
  }
}
