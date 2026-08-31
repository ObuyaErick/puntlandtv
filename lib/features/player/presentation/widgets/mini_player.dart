import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/responsive/window_size.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/remote_image.dart';
import '../controllers/playback_controller.dart';

/// The docked player.
///
/// Two shapes, per artboard 7A: a 58dp bar docked above the navigation at
/// compact and medium, and a 360-wide rounded card floating bottom-right from
/// expanded up, where docking it to a window edge would strand it far from the
/// content it belongs to.
///
/// Tapping it expands back to the full player. Because the underlying
/// controller is app-scoped, expanding and collapsing move the video *surface*
/// only — the stream is never re-established, and audio does not cut.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, this.floating = false});

  /// Renders the floating card variant instead of the docked bar.
  final bool floating;

  static const height = Layout.miniPlayerHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final source = state.source;
    if (source == null) return const SizedBox.shrink();

    final video = controller.videoController;

    return Semantics(
      container: true,
      label: '${source.title}. ${l10n.a11yExpandPlayer}',
      child: Material(
        color: context.colors.playerSurface,
        borderRadius: floating ? Radii.cardBorder : null,
        clipBehavior: floating ? Clip.antiAlias : Clip.none,
        elevation: floating ? 1 : 0,
        child: InkWell(
          onTap: controller.expand,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                // Thumbnail: the live video frame when there is one, artwork
                // otherwise. Sized 4:3-ish to match the canvas dock.
                SizedBox(
                  width: 96,
                  height: height,
                  child: video != null && video.value.isInitialized
                      ? FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: video.value.size.width,
                            height: video.value.size.height,
                            child: VideoPlayer(video),
                          ),
                        )
                      : ColoredBox(
                          color: DarkTokens.surfaceRaised,
                          child: source.artworkUrl != null
                              ? RemoteImage(url: source.artworkUrl)
                              : Icon(
                                  source.isAudioOnly
                                      ? Icons.radio_rounded
                                      : Icons.live_tv_rounded,
                                  color: context.colors.onPlayerSurfaceVariant,
                                  size: 22,
                                ),
                        ),
                ),
                const SizedBox(width: Spacing.cardInternal),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (source.isLive)
                        Text(
                          l10n.live,
                          style: context.text.overline.copyWith(
                            color: DarkTokens.accent,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        source.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.label.copyWith(
                          color: context.colors.onPlayerSurface,
                        ),
                      ),
                      if (source.subtitle != null)
                        Text(
                          source.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.meta.copyWith(
                            color: context.colors.onPlayerSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                _MiniControl(
                  icon: state.isBuffering
                      ? null
                      : state.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: state.isPlaying ? l10n.a11yPause : l10n.a11yPlay,
                  onPressed: controller.togglePlayPause,
                ),
                _MiniControl(
                  icon: Icons.close_rounded,
                  label: l10n.a11yClosePlayer,
                  onPressed: controller.stop,
                ),
                const SizedBox(width: Spacing.chip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniControl extends StatelessWidget {
  const _MiniControl({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  /// Null renders a progress spinner in the control's place, so the row does
  /// not jump while buffering.
  final IconData? icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onPressed,
        // 48dp minimum target, per the design system.
        constraints: const BoxConstraints.tightFor(
          width: kMinTapTarget,
          height: kMinTapTarget,
        ),
        icon: icon == null
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.onPlayerSurfaceVariant,
                ),
              )
            : Icon(icon, color: context.colors.onPlayerSurface, size: 24),
      ),
    );
  }
}
