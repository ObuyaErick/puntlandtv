import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_date_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/pltv_logo.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../player/domain/entities/playback_source.dart';
import '../../../player/presentation/controllers/playback_controller.dart';
import '../../domain/entities/live_channel.dart';
import '../controllers/live_controllers.dart';
import '../widgets/player_controls.dart';

/// Live television: the player, what is on now, and the rest of today.
///
/// Owns the "expanded" state of the app-wide player. Entering the page expands
/// it, leaving docks it — which is how playback follows the user out to the
/// news feed instead of stopping.
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
    final playback = ref.read(playbackControllerProvider);
    if (playback.hasSource) {
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
    final l10n = context.l10n;
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            // child: _OfflineSlate(channel: channel),
            child: channel.isPlayable
                ? _PlayerSurface(channel: channel)
                : _OfflineSlate(channel: channel),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.gutter),
              children: [
                if (channel.nowPlaying != null) ...[
                  Text(
                    l10n.nowPlaying,
                    style: context.text.overline.copyWith(
                      color: context.colors.onPlayerSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.chip),
                  Text(
                    channel.nowPlaying!.title,
                    style: context.text.title.copyWith(
                      color: context.colors.onPlayerSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppDateFormat.time(channel.nowPlaying!.startsAt, context.languageCode)}'
                    ' – '
                    '${AppDateFormat.time(channel.nowPlaying!.endsAt, context.languageCode)}',
                    style: context.text.meta.copyWith(
                      color: context.colors.onPlayerSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.gutter),
                  Row(
                    children: [
                      _AudioOnlyToggle(
                        enabled: state.audioOnly,
                        onChanged: controller.toggleAudioOnly,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sectionBreak),
                ],
                Text(
                  l10n.upNextToday,
                  style: context.text.overline.copyWith(
                    color: context.colors.onPlayerSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.cardInternal),
                for (final entry in channel.upNext) _ScheduleRow(entry: entry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSurface extends ConsumerStatefulWidget {
  const _PlayerSurface({required this.channel});

  final LiveChannel channel;

  @override
  ConsumerState<_PlayerSurface> createState() => _PlayerSurfaceState();
}

class _PlayerSurfaceState extends ConsumerState<_PlayerSurface> {
  bool _chromeVisible = true;

  PlaybackSource get _source => PlaybackSource(
    id: 'live',
    url: widget.channel.streamUrl!,
    kind: PlaybackKind.liveTv,
    title: widget.channel.nowPlaying?.title ?? 'Puntland TV',
    subtitle: widget.channel.nowPlaying?.subtitle,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final isThisSource = state.source?.id == 'live';
    final video = controller.videoController;

    return GestureDetector(
      onTap: () => setState(() => _chromeVisible = !_chromeVisible),
      child: ColoredBox(
        color: context.colors.playerSurface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isThisSource && video != null && video.value.isInitialized)
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: video.value.size.width,
                  height: video.value.size.height,
                  child: VideoPlayer(video),
                ),
              )
            else
              Center(
                child: isThisSource && state.isBuffering
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _StartButton(onPressed: () => controller.play(_source)),
              ),
            if (isThisSource && _chromeVisible)
              Align(
                alignment: Alignment.bottomCenter,
                child: PlayerControls(
                  state: state,
                  onPlayPause: controller.togglePlayPause,
                  onMute: controller.toggleMute,
                  onFullscreen: () {},
                  onCollapse: controller.collapse,
                ),
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
/// Never a failed player: the canvas is explicit that "off air" is a designed
/// state, and the backend supplies the message so it can be localised and
/// changed without an app release.
class _OfflineSlate extends StatelessWidget {
  const _OfflineSlate({required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ColoredBox(
      color: context.colors.playerSurface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PltvMark(height: 34, onDark: true),
            const SizedBox(height: Spacing.listRhythm),
            Text(
              l10n.streamOfflineTitle,
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
    );
  }
}

class _AudioOnlyToggle extends StatelessWidget {
  const _AudioOnlyToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(Radii.chip),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: enabled ? context.colors.accentContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(color: context.colors.playerControlTrack),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headphones_rounded,
              size: 16,
              color: enabled
                  ? context.colors.accent
                  : context.colors.onPlayerSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text(
              context.l10n.audioOnly,
              style: context.text.label.copyWith(
                color: enabled
                    ? context.colors.accent
                    : context.colors.onPlayerSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.entry});

  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.listRhythm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              AppDateFormat.time(entry.startsAt, context.languageCode),
              style: context.text.label.copyWith(
                color: context.colors.onPlayerSurface,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: context.text.body.copyWith(
                    color: context.colors.onPlayerSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.l10n.durationMinutes(entry.duration.inMinutes)}'
                  '${entry.genre != null ? ' · ${entry.genre}' : ''}',
                  style: context.text.meta.copyWith(
                    color: context.colors.onPlayerSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveSkeleton extends StatelessWidget {
  const _LiveSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(color: context.colors.playerSurface),
        ),
        const Padding(
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
      ],
    );
  }
}
