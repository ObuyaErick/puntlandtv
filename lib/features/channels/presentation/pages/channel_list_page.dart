import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/responsive/window_size.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/live_badge.dart';
import '../../../../core/widgets/pltv_logo.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/channel.dart';
import '../controllers/channel_controllers.dart';

/// Where the Live TV and Radio tabs open: every published channel carrying
/// [medium], in the newsroom's order. Tapping one opens its player.
///
/// One list, two filters. A channel with both television and radio appears on
/// both tabs, and a radio-only station only on Radio.
class ChannelListPage extends ConsumerWidget {
  const ChannelListPage({super.key, required this.medium});

  final ChannelMedium medium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // The watching variant: while the list is up, its LIVE badges are
    // re-checked, and the timer dies with the route.
    final channels = ref.watch(channelListWatchProvider);

    final (title, subtitle) = switch (medium) {
      ChannelMedium.tv => (l10n.channelsLiveTitle, l10n.channelsLiveSubtitle),
      ChannelMedium.radio => (
        l10n.channelsRadioTitle,
        l10n.channelsRadioSubtitle,
      ),
    };

    // Both: the watch only re-reads the cached list, so retrying it alone
    // would hand back the same failure.
    void retry() {
      ref.invalidate(channelListProvider);
      ref.invalidate(channelListWatchProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              subtitle,
              style: context.text.meta.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        toolbarHeight: 72,
      ),
      body: channels.when(
        // A re-check that fails keeps the list that was fine a moment ago.
        // Only a first load with nothing to show is an error screen.
        skipError: true,
        loading: () => const _ChannelListSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: retry,
        ),
        data: (all) {
          final shown = [
            for (final channel in all)
              if (channel.carries(medium)) channel,
          ];
          if (shown.isEmpty) {
            return EmptyView(
              icon: _mediumIcon(medium),
              title: l10n.channelListEmptyTitle,
              body: l10n.channelListEmptyBody,
              actionLabel: l10n.retry,
              onAction: retry,
            );
          }
          return _ChannelGrid(channels: shown, medium: medium);
        },
      ),
    );
  }
}

IconData _mediumIcon(ChannelMedium medium) => switch (medium) {
  ChannelMedium.tv => Icons.live_tv_rounded,
  ChannelMedium.radio => Icons.radio_rounded,
};

/// Columns from the width actually available, not the window class: the list
/// sits beside a rail from medium up, and it is what is left that decides.
///
/// One column is a list of rows rather than a column of full-width tiles — a
/// 16:9 tile at 350dp is mostly navy with a logo in it, and a phone should
/// see several channels without scrolling.
class _ChannelGrid extends StatelessWidget {
  const _ChannelGrid({required this.channels, required this.medium});

  final List<Channel> channels;
  final ChannelMedium medium;

  /// Narrower than this and a tile's name and programme stop fitting.
  static const _minTileWidth = 240.0;
  static const _maxColumns = 4;
  static const _spacing = Spacing.listRhythm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content =
            math.min(constraints.maxWidth, Layout.contentCap) -
            2 * Spacing.gutter;
        final columns = ((content + _spacing) / (_minTileWidth + _spacing))
            .floor()
            .clamp(1, _maxColumns);

        if (columns == 1) {
          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.gutter),
            itemCount: channels.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: Spacing.cardInternal),
            itemBuilder: (_, index) =>
                _ChannelCard(channel: channels[index], medium: medium),
          );
        }

        // Floored so rounding can never push the last tile of a row onto the
        // next one.
        final tileWidth = ((content - (columns - 1) * _spacing) / columns)
            .floorToDouble();

        // A Wrap rather than a grid: each tile is as tall as its own text,
        // which a fixed grid extent cannot promise at 130% in Somali.
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.gutter),
          child: Center(
            child: SizedBox(
              width: content,
              child: Wrap(
                spacing: _spacing,
                runSpacing: _spacing,
                children: [
                  for (final channel in channels)
                    SizedBox(
                      width: tileWidth,
                      child: _ChannelCard(
                        channel: channel,
                        medium: medium,
                        tile: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One channel: a row in a single column, a tile in a grid.
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.medium,
    this.tile = false,
  });

  final Channel channel;
  final ChannelMedium medium;
  final bool tile;

  static const _thumbWidth = 112.0;
  static const _chevronSize = 24.0;

  /// The widest badge at 100% text — Somali's MA BAAHINAYO. A row keeps its
  /// thumbnail only while the text column still has this much room.
  static const _minTextColumn = 172.0;

  /// The schedule the list reports is television's. On a channel that also
  /// has television, that is not what its radio is playing — so the Radio tab
  /// shows it only for a radio-only station, whose schedule is its own.
  String? get _nowPlaying => switch (medium) {
    ChannelMedium.tv => channel.nowPlayingTitle,
    ChannelMedium.radio => channel.hasTv ? null : channel.nowPlayingTitle,
  };

  void _open(BuildContext context) => context.go(switch (medium) {
    ChannelMedium.tv => Routes.liveChannel(channel.key),
    ChannelMedium.radio => Routes.radioChannel(channel.key),
  });

  @override
  Widget build(BuildContext context) {
    final onAir = channel.isOnAir(medium);
    final nowPlaying = _nowPlaying;

    final badge = onAir
        ? const LiveBadge(compact: true)
        : const OffAirBadge(compact: true);

    final name = Text(
      channel.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.cardTitle.copyWith(color: context.scheme.primary),
    );

    final programme = nowPlaying == null
        ? null
        : Text(
            nowPlaying,
            maxLines: tile ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          );

    return MergeSemantics(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: tile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _ChannelArt(markHeight: 40),
                          Positioned(
                            left: Spacing.chip,
                            top: Spacing.chip,
                            child: onAir
                                ? const LiveBadge(compact: true, onDark: true)
                                : const OffAirBadge(
                                    compact: true,
                                    onDark: true,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(Spacing.cardInternal),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          name,
                          if (programme != null) ...[
                            const SizedBox(height: 2),
                            programme,
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(Spacing.cardInternal),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // The thumbnail is the brand, the same on every card, so
                      // it is what gives way when the text column would be too
                      // narrow for the badge — at 320dp, or at 130% text.
                      final textColumn =
                          constraints.maxWidth -
                          _thumbWidth -
                          Spacing.cardInternal -
                          _chevronSize;
                      final showThumb =
                          textColumn >=
                          MediaQuery.textScalerOf(context)
                              .scale(_minTextColumn);

                      return Row(
                        children: [
                          if (showThumb) ...[
                            SizedBox(
                              width: _thumbWidth,
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: ClipRRect(
                                  borderRadius: Radii.thumbBorder,
                                  child: _ChannelArt(markHeight: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: Spacing.cardInternal),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                badge,
                                const SizedBox(height: 6),
                                name,
                                if (programme != null) ...[
                                  const SizedBox(height: 2),
                                  programme,
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: _chevronSize,
                            color: context.scheme.onSurfaceVariant,
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

/// The channel's picture. There is no per-channel artwork yet, so it is the
/// brand on the player's navy — which is also what the live slate and the
/// radio dial show, so the card and the screen it opens match.
class _ChannelArt extends StatelessWidget {
  const _ChannelArt({required this.markHeight});

  final double markHeight;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.playerSurface,
      child: Center(child: PltvMark(height: markHeight, onDark: true)),
    );
  }
}

class _ChannelListSkeleton extends StatelessWidget {
  const _ChannelListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.gutter),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.cardInternal),
      itemBuilder: (_, _) => const Row(
        children: [
          SkeletonBox(width: 112, height: 63, radius: Radii.thumbnail),
          SizedBox(width: Spacing.cardInternal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 44, height: 18),
                SizedBox(height: Spacing.chip),
                SkeletonBox(height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 140, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
