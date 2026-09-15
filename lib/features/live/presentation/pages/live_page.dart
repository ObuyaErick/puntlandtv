import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/preview/app_preview.dart';
import 'package:puntland/core/preview/preview_size.dart';
import 'package:puntland/features/live/data/fixtures/live_channel.dart';

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

/// The playback source id for one channel's television.
///
/// Per channel, not a bare `live`: the id is how every surface decides whether
/// the stream playing is *its* stream, and with several channels "some live
/// TV is playing" is no longer the same question as "this channel is".
String liveSourceId(String channelKey) => 'live:$channelKey';

/// One channel's live television.
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
  const LivePage({super.key, required this.channelKey});

  final String channelKey;

  @override
  ConsumerState<LivePage> createState() => _LivePageState();
}

class _LivePageState extends ConsumerState<LivePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only this channel's stream takes the page over. Another channel left
      // playing stays docked in the mini-player until this one is started.
      final playback = ref.read(playbackControllerProvider);
      if (playback.source?.id == liveSourceId(widget.channelKey)) {
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
    // The watching variant, not the bare provider: while this screen is up,
    // the channel is re-checked so a signal that drops unattended becomes the
    // slate rather than a frozen frame. The timer dies with the route.
    final key = widget.channelKey;
    final channel = ref.watch(liveChannelWatchProvider(key));

    return Scaffold(
      backgroundColor: context.colors.playerSurface,
      body: channel.when(
        loading: () => const _LiveSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          // Both: the watch only re-reads the cached channel, so retrying it
          // alone would hand back the same failure.
          onRetry: () {
            ref.invalidate(liveChannelProvider(key));
            ref.invalidate(liveChannelWatchProvider(key));
          },
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

  /// Re-asks the API whether the channel is still up, the moment playback
  /// fails.
  ///
  /// This is the fast half of the recovery loop; `liveChannelWatch`'s timer is
  /// the slow half. When the studio's encoder drops, the manifest's segments
  /// stop existing and the engine reports `PLAYBACK_FAILED` within a second or
  /// two — long before the next scheduled re-check. Asking immediately turns a
  /// dead player into the localised slate at roughly the speed the viewer
  /// noticed something was wrong.
  ///
  /// Guarded on the source being ours: a VOD episode failing is not a reason
  /// to re-fetch the live channel, and neither is another channel failing.
  void _refreshOnPlaybackFailure() {
    ref.listen(playbackControllerProvider, (previous, next) {
      final justFailed =
          next.errorCode == 'PLAYBACK_FAILED' &&
          previous?.errorCode != 'PLAYBACK_FAILED';
      if (!justFailed) return;
      if (next.source?.id != _sourceId) return;
      ref.invalidate(liveChannelProvider(widget.channel.key));
    });
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

  String get _sourceId => liveSourceId(widget.channel.key);

  /// The mini-player shows [PlaybackSource.title] over
  /// [PlaybackSource.subtitle], so the channel name goes underneath the
  /// programme — with several channels, "what is this" is the channel as much
  /// as the programme. With nothing scheduled the name is the title, alone.
  PlaybackSource get _source {
    final channel = widget.channel;
    final programme = channel.nowPlaying?.title;
    return PlaybackSource(
      id: _sourceId,
      url: channel.streamUrl!,
      kind: PlaybackKind.liveTv,
      title: programme ?? channel.name,
      subtitle: programme == null ? null : channel.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.channel.isPlayable) {
      return _OfflineSlate(channel: widget.channel);
    }

    _refreshOnPlaybackFailure();

    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final isThisSource = state.source?.id == _sourceId;
    final surface = isThisSource ? controller.buildVideoSurface() : null;

    return GestureDetector(
      onTap: _toggleChrome,
      child: ColoredBox(
        color: const Color(0xFF04101F),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ?surface,
            if (surface == null)
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

@AppPreview(size: PreviewSize.tablet, name: 'Player Surface')
Widget previewPlayerSurface() => PlayerSurface(channel: previewChannel);
