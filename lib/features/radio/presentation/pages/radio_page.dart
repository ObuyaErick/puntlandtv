import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/live_badge.dart';
import '../../../../core/widgets/pltv_logo.dart';
import '../../../player/domain/entities/playback_source.dart';
import '../../../player/presentation/controllers/playback_controller.dart';
import '../../domain/entities/radio_station.dart';
import '../controllers/radio_controllers.dart';

/// The playback source id for one channel's radio. Per channel for the same
/// reason as the live page's: the id is how a surface knows the stream playing
/// is its own.
String radioSourceId(String channelKey) => 'radio:$channelKey';

/// One station's now-playing. Always dark, per the canvas — audio surfaces
/// stay navy in both themes.
class RadioPage extends ConsumerWidget {
  const RadioPage({super.key, required this.channelKey});

  final String channelKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(radioStationWatchProvider(channelKey));

    return Scaffold(
      backgroundColor: context.colors.playerSurface,
      // The way back to the station list. Only when there is one: a page
      // mounted on its own has nowhere to pop to, and an empty bar would just
      // push the dial down.
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: context.colors.onPlayerSurface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            )
          : null,
      body: station.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(radioStationWatchProvider(channelKey)),
        ),
        data: (data) => _RadioBody(station: data),
      ),
    );
  }
}

class _RadioBody extends ConsumerWidget {
  const _RadioBody({required this.station});

  final RadioStation station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final isThisSource = state.source?.id == radioSourceId(station.key);
    final isPlaying = isThisSource && state.isPlaying;

    // Off air, there is nothing to start — but a listener already tuned in
    // keeps the control, so they can stop what is playing.
    final canPlay = station.isOnAir || isThisSource;

    // Centred while it fits, scrollable once it does not: a 568dp phone
    // under a back bar and the navigation is shorter than the dial is tall.
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.emptyState),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: DarkTokens.surfaceRaised,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: PltvMark(height: 64, onDark: true),
                    ),
                  ),
                  const SizedBox(height: Spacing.sectionBreak),
                  if (station.isOnAir)
                    const LiveBadge(compact: true, onDark: true)
                  else
                    const OffAirBadge(compact: true, onDark: true),
                  const SizedBox(height: Spacing.listRhythm),
                  Text(
                    station.name.toUpperCase(),
                    style: context.text.overline.copyWith(
                      color: context.colors.onPlayerSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.chip),
                  Text(
                    station.isOnAir
                        ? station.nowPlaying ?? station.name
                        : l10n.radioOffAirTitle,
                    textAlign: TextAlign.center,
                    style: context.text.headline.copyWith(
                      color: context.colors.onPlayerSurface,
                    ),
                  ),
                  if (station.frequencyLabel != null) ...[
                    const SizedBox(height: Spacing.chip),
                    Text(
                      station.frequencyLabel!,
                      textAlign: TextAlign.center,
                      style: context.text.body.copyWith(
                        color: context.colors.onPlayerSurfaceVariant,
                      ),
                    ),
                  ],
                  if (canPlay) ...[
                    const SizedBox(height: Spacing.emptyState),
                    Semantics(
                      button: true,
                      label: isPlaying ? l10n.a11yPause : l10n.a11yPlay,
                      child: InkResponse(
                        onTap: () {
                          if (isThisSource) {
                            controller.togglePlayPause();
                          } else {
                            controller.play(
                              PlaybackSource(
                                id: radioSourceId(station.key),
                                url: station.streamUrl,
                                kind: PlaybackKind.radio,
                                title: station.nowPlaying ?? station.name,
                                subtitle: station.name,
                              ),
                            );
                          }
                        },
                        radius: 46,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: isThisSource && state.isBuffering
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: BrandPalette.navy,
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 38,
                                  color: BrandPalette.navy,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.sectionBreak),
                    Text(
                      l10n.radioBackgroundNote,
                      textAlign: TextAlign.center,
                      style: context.text.meta.copyWith(
                        color: context.colors.onPlayerSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
