import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/features/live/presentation/previews/preview_live_channel.dart';

import '../../../../core/l10n/app_date_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/preview/app_preview.dart';
import '../../../../core/preview/preview_size.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../player/presentation/controllers/playback_controller.dart';
import '../../domain/entities/live_channel.dart';

/// Which channel this is, what is on now, the actions for it, and the rest of
/// today's schedule.
///
/// Scrolls independently of the player, so it works both beneath a stacked
/// player and beside a capped one at Large.
class NowPlayingPanel extends ConsumerWidget {
  const NowPlayingPanel({super.key, required this.channel});
  @AppPreview(size: PreviewSize.phone, name: 'NowPlayingPanel')
  final LiveChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final nowPlaying = channel.nowPlaying;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.gutter,
        Spacing.gutter,
        Spacing.gutter,
        Spacing.emptyState,
      ),
      children: [
        _ChannelHeader(name: channel.name),
        const SizedBox(height: Spacing.cardInternal),
        if (nowPlaying != null) ...[
          Row(
            children: [
              Text(
                l10n.live,
                style: context.text.overline.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.21,
                  color: DarkTokens.accent,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF3E5C8C),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  '${AppDateFormat.time(nowPlaying.startsAt, context.languageCode)}'
                  ' – '
                  '${AppDateFormat.time(nowPlaying.endsAt, context.languageCode)}',
                  style: context.text.meta.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: context.colors.onPlayerSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nowPlaying.title,
            style: context.text.headline.copyWith(
              fontSize: 25,
              height: 31 / 25,
              color: context.colors.onPlayerSurface,
            ),
          ),
          if (nowPlaying.subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              nowPlaying.subtitle!,
              style: context.text.body.copyWith(
                fontSize: 15,
                color: context.colors.onPlayerSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.listRhythm),
          // Wrap, not Row: at 130% these two labels stop fitting side by side
          // in Somali, and wrapping is better than truncating an action.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PanelAction(
                icon: Icons.headphones_rounded,
                label: l10n.audioOnly,
                selected: state.audioOnly,
                onTap: controller.toggleAudioOnly,
              ),
              _PanelAction(
                icon: Icons.calendar_today_rounded,
                label: l10n.schedule,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: Spacing.sectionBreak),
        ],
        if (channel.upNext.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.cardInternal),
            child: Text(
              l10n.upNextToday,
              style: context.text.overline.copyWith(
                fontSize: 11.5,
                letterSpacing: 1.27,
                color: context.colors.onPlayerSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1, color: DarkTokens.outline),
          for (final entry in channel.upNext) _ScheduleRow(entry: entry),
        ],
      ],
    );
  }
}

/// The channel's name, with the way back to the channel list.
///
/// With several channels the player alone no longer says which one this is:
/// the PLTV chip on the video is the brand, the same on every channel.
class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    // Only when there is a list to go back to. A deep link still has one —
    // the router builds `/live` under `/live/<key>` — so this is false only
    // for a page mounted on its own.
    final canPop = Navigator.of(context).canPop();

    return Row(
      children: [
        if (canPop) ...[
          BackButton(color: context.colors.onPlayerSurface),
          const SizedBox(width: Spacing.iconToLabel),
        ],
        Expanded(
          child: Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.overline.copyWith(
              color: context.colors.onPlayerSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelAction extends StatelessWidget {
  const _PanelAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.button),
        child: Container(
          height: kMinTapTarget,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? DarkTokens.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.button),
            border: Border.all(color: DarkTokens.outlineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? DarkTokens.accent
                    : context.colors.onPlayerSurface,
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: context.text.label.copyWith(
                  color: selected
                      ? DarkTokens.accent
                      : context.colors.onPlayerSurface,
                ),
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DarkTokens.surfaceRaised)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              AppDateFormat.time(entry.startsAt, context.languageCode),
              style: context.text.label.copyWith(
                color: context.colors.onPlayerSurface,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: context.text.body.copyWith(
                    fontSize: 15,
                    color: context.colors.onPlayerSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    context.l10n.durationMinutes(entry.duration.inMinutes),
                    ?entry.genre,
                  ].join(' · '),
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

@AppPreview(size: PreviewSize.phone, name: 'NowPlayingPanel')
@AppPreview.somali(size: PreviewSize.phone, name: 'NowPlayingPanel (so)')
Widget previewNowPlayingPanel() => ColoredBox(
  color: DarkTokens.background,
  child: NowPlayingPanel(channel: previewChannel),
);

@AppPreview(size: PreviewSize.phone, name: 'ScheduleRow')
Widget previewScheduleRow() => ColoredBox(
  color: DarkTokens.background,
  child: _ScheduleRow(entry: previewChannel.upNext.last),
);
