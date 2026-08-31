import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_date_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/responsive/window_size.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/pltv_logo.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../player/domain/entities/playback_source.dart';
import '../../../player/presentation/controllers/playback_controller.dart';
import '../../domain/entities/live_channel.dart';
import '../controllers/live_controllers.dart';
import '../widgets/now_playing_panel.dart';
import '../widgets/player_controls.dart';

/// Live television.
///
/// Three layouts, chosen from the space actually available:
///
/// * **Immersive** — landscape, or any window that cannot reserve 132dp below
///   a 16:9 video. The video fills the surface, chrome hides, and the controls
///   overlay it with a 3s auto-dismiss.
/// * **Stacked** — the default. 16:9 player on top, now-playing and schedule
///   beneath.
/// * **Side-by-side** — from Large up. The player caps at 740dp wide and the
///   schedule sits beside it; the video never stretches to fill 1360dp.
class LivePage extends ConsumerStatefulWidget {
  const LivePage({super.key});

  @override
  ConsumerState<LivePage> createState() => _LivePageState();
}

class _LivePageState extends ConsumerState<LivePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final playback = ref.read(playbackControllerProvider);
      if (playback.source?.kind == PlaybackKind.liveTv) {
        ref.read(playbackControllerProvider.notifier).expand();
      }
    });
  }

  @override
  void deactivate() {
    // Dock rather than stop. The stream keeps running and the mini-player
    // picks it up in the shell.
    if (ref.read(playbackControllerProvider).hasSource) {
      ref.read(playbackControllerProvider.notifier).collapse();
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(liveChannelProvider);

    return Scaffold(
      backgroundColor: context.colors.playerSurface,
      body: channel.when(
        loading: () => const _LiveSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(liveChannelProvider),
        ),
        data: (data) => _LiveBody(channel: data),
      ),
    );
  }
}

class _LiveBody extends ConsumerWidget {
  const _LiveBody({required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = WindowSizeClass.fromWidth(constraints.maxWidth);
        final landscape = constraints.maxWidth > constraints.maxHeight;

        // Large and up always pairs the player with the schedule; the
        // immersive checks below only apply to smaller windows.
        if (size.isAtLeastLarge) {
          return _SideBySideLayout(channel: channel);
        }

        final playerHeight = constraints.maxWidth * 9 / 16;
        final bandBelow = constraints.maxHeight - playerHeight;

        // The band scales with text: the now-playing block is mostly type, so
        // at 130% it needs proportionally more room before it is worth showing
        // at all.
        final requiredBand =
            Layout.playerControlBand *
            MediaQuery.textScalerOf(context).scale(1);

        if (landscape || bandBelow < requiredBand) {
          return _ImmersiveLayout(channel: channel);
        }

        return _StackedLayout(channel: channel);
      },
    );
  }
}

/// Player on top, content beneath.
class _StackedLayout extends StatelessWidget {
  const _StackedLayout({required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PlayerSurface(channel: channel),
          ),
          Expanded(child: NowPlayingPanel(channel: channel)),
        ],
      ),
    );
  }
}

/// The video fills the surface; chrome auto-dismisses.
class _ImmersiveLayout extends StatelessWidget {
  const _ImmersiveLayout({required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context) {
    return PlayerSurface(channel: channel, immersive: true);
  }
}

/// Large and up: a capped player with the schedule beside it.
class _SideBySideLayout extends StatelessWidget {
  const _SideBySideLayout({required this.channel});

  final LiveChannel channel;

  /// The video stops growing here. Stretching a broadcast feed across 1360dp
  /// makes it soft, not impressive.
  static const playerMaxWidth = 740.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Layout.contentCap),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.sectionBreak),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: playerMaxWidth),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: Radii.cardBorder,
                      child: PlayerSurface(channel: channel),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sectionBreak),
                Expanded(child: NowPlayingPanel(channel: channel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The video surface and its overlaid chrome.
class PlayerSurface extends ConsumerStatefulWidget {
  const PlayerSurface({
    super.key,
    required this.channel,
    this.immersive = false,
  });

  final LiveChannel channel;

  /// Hides chrome after [_autoDismiss] and lets the video fill the surface.
  final bool immersive;

  static const _autoDismiss = Duration(seconds: 3);

  @override
  ConsumerState<PlayerSurface> createState() => _PlayerSurfaceState();
}

class _PlayerSurfaceState extends ConsumerState<PlayerSurface> {
  bool _chromeVisible = true;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    if (widget.immersive) _scheduleDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(PlayerSurface._autoDismiss, () {
      if (mounted) setState(() => _chromeVisible = false);
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible && widget.immersive) _scheduleDismiss();
  }

  PlaybackSource get _source => PlaybackSource(
    id: 'live',
    url: widget.channel.streamUrl!,
    kind: PlaybackKind.liveTv,
    title: widget.channel.nowPlaying?.title ?? 'Puntland TV',
    subtitle: widget.channel.nowPlaying?.subtitle,
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.channel.isPlayable) {
      return _OfflineSlate(channel: widget.channel);
    }

    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final isThisSource = state.source?.id == 'live';
    final video = controller.videoController;
    final showVideo =
        isThisSource && video != null && video.value.isInitialized;

    return GestureDetector(
      onTap: _toggleChrome,
      child: ColoredBox(
        color: const Color(0xFF04101F),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showVideo)
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: video.value.size.width,
                  height: video.value.size.height,
                  child: VideoPlayer(video),
                ),
              ),
            if (!showVideo)
              Center(
                child: isThisSource && state.isBuffering
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _StartButton(onPressed: () => controller.play(_source)),
              ),
            if (isThisSource && _chromeVisible)
              PlayerControls(
                state: state,
                clockLabel: AppDateFormat.time(
                  DateTime.now(),
                  context.languageCode,
                ),
                onPlayPause: controller.togglePlayPause,
                onMute: controller.toggleMute,
                onFullscreen: _toggleChrome,
                onCollapse: widget.immersive ? null : controller.collapse,
              ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: BrandPalette.navy,
      ),
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(context.l10n.watchLive),
    );
  }
}

/// Branded slate shown when the broadcaster is off air.
///
/// Never a failed player: "off air" is a designed state, and the backend
/// supplies the message so it can be localised and changed without a release.
class _OfflineSlate extends StatelessWidget {
  const _OfflineSlate({required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ColoredBox(
      color: context.colors.playerSurface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PltvMark(height: 34, onDark: true),
              const SizedBox(height: Spacing.listRhythm),
              Text(
                l10n.streamOfflineTitle,
                textAlign: TextAlign.center,
                style: context.text.title.copyWith(
                  color: context.colors.onPlayerSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                channel.offlineMessage ??
                    (channel.resumesAt != null
                        ? l10n.streamOfflineBody(
                            AppDateFormat.time(
                              channel.resumesAt!,
                              context.languageCode,
                            ),
                          )
                        : ''),
                textAlign: TextAlign.center,
                style: context.text.meta.copyWith(
                  color: context.colors.onPlayerSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveSkeleton extends StatelessWidget {
  const _LiveSkeleton();

  @override
  Widget build(BuildContext context) {
    // The skeleton has to obey the same constraints the real layouts do. A
    // hard 16:9 box plus a fixed content block overflows by 206px on a
    // landscape phone and 26px on a desktop window — and because it is the
    // *loading* state, that is what every cold load renders first.
    return LayoutBuilder(
      builder: (context, constraints) {
        final playerHeight = math.min(
          constraints.maxWidth * 9 / 16,
          constraints.maxHeight * 0.6,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: playerHeight,
              width: double.infinity,
              child: ColoredBox(color: context.colors.playerSurface),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(Spacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 110, height: 10),
                    SizedBox(height: Spacing.cardInternal),
                    SkeletonBox(height: 20),
                    SizedBox(height: Spacing.gutter),
                    SkeletonBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
