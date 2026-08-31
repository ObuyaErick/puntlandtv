import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/responsive/window_size.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../player/presentation/controllers/playback_controller.dart';

/// Chrome overlaid on the video surface.
///
/// The surface owns video only; these controls float on top of it. That is the
/// rule from artboard 7A, and it is what fixes the original bug — the previous
/// version laid the controls *inside* the 16:9 box and measured them against
/// whatever height was left over, so a column that fitted at 390dp overflowed
/// by 12px at 360dp.
///
/// Three clusters: a brand chip top-left, a live badge top-right, and the
/// transport strip along the bottom.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.state,
    required this.onPlayPause,
    required this.onMute,
    required this.onFullscreen,
    this.onCollapse,
    this.clockLabel,
    this.quality = 'HD',
  });

  final PlaybackState state;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final VoidCallback onFullscreen;
  final VoidCallback? onCollapse;

  /// Wall-clock time shown beside the LIVE label, e.g. `21:04`.
  final String? clockLabel;

  final String quality;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measured against the surface, not the window: this same widget is
        // used inside the expanded layout's detail pane, where the window is
        // wide and the player is not.
        final compact = constraints.maxWidth < Layout.transportCollapseWidth;

        return Stack(
          children: [
            Positioned(top: 12, left: 14, child: const _BrandChip()),
            Positioned(
              top: 12,
              right: 14,
              child: _LiveChip(clockLabel: clockLabel),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: _TransportStrip(
                state: state,
                compact: compact,
                quality: quality,
                clockLabel: clockLabel,
                onPlayPause: onPlayPause,
                onMute: onMute,
                onFullscreen: onFullscreen,
                onCollapse: onCollapse,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: BrandPalette.navy,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'PLTV',
        style: context.text.overline.copyWith(
          fontSize: 10.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({this.clockLabel});

  final String? clockLabel;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.live;

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: LightTokens.accent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            clockLabel == null ? label : '$label · $clockLabel',
            style: context.text.overline.copyWith(
              fontSize: 10.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress track plus the transport row.
///
/// Below 360dp the quality chip folds into an overflow button rather than
/// being squeezed — the canvas is explicit that controls are dropped, never
/// shrunk, because shrinking would take them under the 48dp target.
class _TransportStrip extends StatelessWidget {
  const _TransportStrip({
    required this.state,
    required this.compact,
    required this.quality,
    required this.clockLabel,
    required this.onPlayPause,
    required this.onMute,
    required this.onFullscreen,
    required this.onCollapse,
  });

  final PlaybackState state;
  final bool compact;
  final String quality;
  final String? clockLabel;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final VoidCallback onFullscreen;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLive = state.source?.isLive ?? true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressTrack(state: state, isLive: isLive),
        const SizedBox(height: 10),
        SizedBox(
          // The row is sized by its 48dp targets. The canvas draws a slimmer
          // strip, but a 24dp icon with a 24dp hit box fails the minimum
          // target the same design system sets — the target wins.
          height: kMinTapTarget,
          child: Row(
            children: [
              _OverlayIconButton(
                icon: state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: state.isPlaying ? l10n.a11yPause : l10n.a11yPlay,
                onPressed: onPlayPause,
                busy: state.isBuffering,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  isLive
                      ? [l10n.live, clockLabel].nonNulls.join(' · ')
                      : _elapsed(state),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.overline.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.99,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (!compact) ...[
                _QualityChip(label: quality),
                const SizedBox(width: 16),
                _OverlayIconButton(
                  icon: state.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  label: l10n.a11yMute,
                  onPressed: onMute,
                ),
              ] else
                _OverlayIconButton(
                  icon: Icons.more_vert_rounded,
                  label: MaterialLocalizations.of(context).moreButtonTooltip,
                  onPressed: () => _showOverflow(context),
                ),
              if (onCollapse != null)
                _OverlayIconButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  label: l10n.a11yCollapsePlayer,
                  onPressed: onCollapse!,
                ),
              _OverlayIconButton(
                icon: Icons.fullscreen_rounded,
                label: l10n.a11yFullscreen,
                onPressed: onFullscreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _elapsed(PlaybackState state) {
    String two(int n) => n.toString().padLeft(2, '0');
    final position = state.position;
    return '${two(position.inMinutes)}:${two(position.inSeconds % 60)}';
  }

  void _showOverflow(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                state.isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
              ),
              title: Text(l10n.a11yMute),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onMute();
              },
            ),
            ListTile(
              leading: const Icon(Icons.hd_rounded),
              title: Text(quality),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.state, required this.isLive});

  final PlaybackState state;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final duration = state.duration;
    final progress =
        (!isLive && duration != null && duration.inMilliseconds > 0)
        ? (state.position.inMilliseconds / duration.inMilliseconds)
              .clamp(0, 1)
              .toDouble()
        : 1.0;

    return SizedBox(
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: Colors.white.withValues(alpha: 0.25)),
            ),
            // A live stream has no meaningful position, so the track reads as
            // fully "played" rather than pretending to a progress it cannot
            // know.
            FractionallySizedBox(
              widthFactor: progress,
              child: const ColoredBox(color: DarkTokens.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: context.text.overline.copyWith(
          fontSize: 10.5,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: kMinTapTarget,
        height: kMinTapTarget,
      ),
      icon: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 24, color: Colors.white),
    );
  }
}

/// The large centre play button, shown before playback starts and while paused.
class PlayerCentreButton extends StatelessWidget {
  const PlayerCentreButton({
    super.key,
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
