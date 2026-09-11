import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/channel_dto.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_compact_bar.dart';
import '../controllers/channel_controller.dart';
import '../widgets/channel_card.dart';
import '../widgets/channel_status_band.dart';
import 'channel_panel.dart';

/// Live control's landing: every channel as a status card, under the navy
/// "on air now" band — per the channel-list design review.
///
/// Built for a control room at night. The page answers "is everything up"
/// before the list starts, calls out the one state that is failing readers
/// in five ways at once, and keeps the list's column rhythm — order, preview,
/// channel, status, actions — so the actions always land in the same place.
///
/// The order of the cards is the order readers see the channels in the app,
/// and it is set here, where the order is visible.
class ChannelsPage extends ConsumerWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelListProvider);
    // Through the console's clock, like every other timestamp: uptimes and
    // "8 minutes ago" are read against it, and a test pins it.
    final now = ref.watch(consoleClockProvider)();

    return ColoredBox(
      color: context.scheme.surfaceContainerLow,
      child: WindowSizeScope(
        builder: (context, size) {
          final layout = size.isAtLeastExpanded
              ? ChannelCardLayout.row
              : size.isAtLeastMedium
              ? ChannelCardLayout.twoRows
              : ChannelCardLayout.stacked;

          final body = channels.when(
            loading: () => _Skeleton(layout: layout),
            error: (error, _) => ErrorView(
              failure: error is Failure
                  ? error
                  : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
              onRetry: () => ref.invalidate(channelListProvider),
            ),
            data: (rows) => rows.isEmpty
                ? _Empty(layout: layout)
                : _ChannelList(rows: rows, layout: layout, now: now),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (layout == ChannelCardLayout.stacked)
                ConsoleCompactBar(
                  title: context.l10n.liveControlTitle,
                  action: channels.hasValue
                      ? IconButton(
                          key: const Key('new-channel'),
                          tooltip: context.l10n.newChannel,
                          onPressed: () => showChannelPanel(context),
                          icon: const Icon(Icons.add_rounded),
                        )
                      : null,
                )
              else if (!channels.isLoading)
                _Header(channels: channels.value, layout: layout),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}

/// The page's own horizontal inset, by layout.
double _inset(ChannelCardLayout layout) => switch (layout) {
  ChannelCardLayout.row => 40,
  ChannelCardLayout.twoRows => 24,
  ChannelCardLayout.stacked => Spacing.listRhythm,
};

/// "Live control", the count and what the order means, and New channel.
///
/// On the page's own ground rather than in a white bar: the design gives this
/// page a heading, not a toolbar, so the navy band beneath is the first
/// surface the eye lands on.
class _Header extends StatelessWidget {
  const _Header({required this.channels, required this.layout});

  /// Null while the list has not loaded; the empty list says so itself.
  final List<ChannelDto>? channels;
  final ChannelCardLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = channels?.length ?? 0;

    final subtitle = count == 0
        ? l10n.noChannels
        : count == 1
        ? l10n.channelCount(1)
        : '${l10n.channelCount(count)} · '
              '${layout == ChannelCardLayout.row ? l10n.channelOrderNote : l10n.channelOrderNoteShort}';

    final inset = _inset(layout);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        inset,
        layout == ChannelCardLayout.row ? 36 : 28,
        inset,
        Spacing.gutter + 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.liveControlTitle,
                  style: context.text.headline.copyWith(
                    fontSize: layout == ChannelCardLayout.row ? 32 : 28,
                    height: 1.2,
                    color: context.scheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: context.text.body.copyWith(
                    fontSize: 15.5,
                    height: 22 / 15.5,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // The empty page carries its button in the middle, where the
          // explanation of what a channel is sits beside it.
          if (count > 0) ...[
            const SizedBox(width: Spacing.listRhythm),
            const _NewChannelButton(key: Key('new-channel')),
          ],
        ],
      ),
    );
  }
}

class _NewChannelButton extends StatelessWidget {
  const _NewChannelButton({super.key, this.outlined = false});

  /// The quieter form, for the one-channel prompt under the card.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final label = Text(context.l10n.newChannel);
    final textStyle = context.text.label.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.button),
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: () => showChannelPanel(context),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: context.scheme.primary,
          side: BorderSide(color: context.scheme.primary, width: 1.5),
          textStyle: textStyle,
          shape: shape,
        ),
        child: label,
      );
    }

    return FilledButton.icon(
      onPressed: () => showChannelPanel(context),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: label,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        backgroundColor: context.scheme.primary,
        foregroundColor: Colors.white,
        textStyle: textStyle,
        shape: shape,
      ),
    );
  }
}

class _ChannelList extends StatelessWidget {
  const _ChannelList({
    required this.rows,
    required this.layout,
    required this.now,
  });

  final List<ChannelDto> rows;
  final ChannelCardLayout layout;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inset = _inset(layout);
    final single = rows.length == 1;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        inset,
        layout == ChannelCardLayout.stacked ? Spacing.listRhythm : 0,
        inset,
        Spacing.emptyState,
      ),
      children: [
        // With one channel there is nothing to summarise and nothing to
        // order: the card widens instead, and the page asks for a second.
        if (single) ...[
          if (layout == ChannelCardLayout.row)
            ChannelSpotlightCard(channels: rows, now: now)
          else
            ChannelCard(channels: rows, index: 0, layout: layout, now: now),
          const SizedBox(height: Spacing.listRhythm),
          ChannelDashedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Spacing.listRhythm,
                runSpacing: Spacing.cardInternal,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      l10n.addSecondChannel,
                      style: context.text.body.copyWith(
                        fontSize: 15,
                        height: 22 / 15,
                        color: context.scheme.onSurface,
                      ),
                    ),
                  ),
                  const _NewChannelButton(outlined: true),
                ],
              ),
            ),
          ),
        ] else ...[
          ChannelStatusBand(channels: rows, layout: layout, now: now),
          const SizedBox(height: Spacing.gutter),
          _KeyNotice(short: layout != ChannelCardLayout.row),
          if (layout == ChannelCardLayout.row) ...[
            const SizedBox(height: 26),
            const _ColumnHeaders(),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: Spacing.listRhythm),
          for (final (index, _) in rows.indexed) ...[
            if (index > 0) const SizedBox(height: Spacing.cardInternal),
            ChannelCard(channels: rows, index: index, layout: layout, now: now),
          ],
        ],
      ],
    );
  }
}

/// "The key is permanent … the name is safe to change", with both words set
/// apart — the one lesson of this page, said once above the list.
class _KeyNotice extends StatelessWidget {
  const _KeyNotice({required this.short});

  final bool short;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = context.text.body.copyWith(
      fontSize: 15,
      height: 22 / 15,
      color: context.scheme.onSurface,
    );
    final strong = style.copyWith(
      fontWeight: FontWeight.w600,
      color: context.scheme.primary,
    );
    const keyMark = '\uE000';
    const nameMark = '\uE001';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Spacing.cardInternal),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: style,
                children: markedSpans(
                  short
                      ? l10n.keyNoticeShort(keyMark, nameMark)
                      : l10n.keyNotice(keyMark, nameMark),
                  {
                    keyMark: TextSpan(
                      text: l10n.keyNoticeKey,
                      style: strong.copyWith(fontFamily: FontFamily.mono),
                    ),
                    nameMark: TextSpan(text: l10n.keyNoticeName, style: strong),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ORD · PREVIEW · CHANNEL · STATUS · ORDER · EDIT · DELETE, over the same
/// column rhythm the cards use.
class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = context.text.overline.copyWith(
      fontSize: 11.5,
      letterSpacing: 1.3,
      color: context.scheme.onSurfaceVariant,
    );

    return Padding(
      // The cards' padding plus their 1px border, so each label sits over
      // its column exactly.
      padding: const EdgeInsets.symmetric(
        horizontal: ChannelColumns.padding + 1,
      ),
      child: Row(
        children: [
          // The number beneath is two digits at most, but the label is a
          // word — "LAMBAR" in Somali — so it takes the gap after it too.
          SizedBox(
            width: ChannelColumns.ord + ChannelColumns.gap,
            child: Text(l10n.colOrd, softWrap: false, style: style),
          ),
          SizedBox(
            width: ChannelColumns.previewWidth,
            child: Text(l10n.colPreview, style: style),
          ),
          const SizedBox(width: ChannelColumns.gap),
          Expanded(
            flex: ChannelColumns.channelFlex,
            child: Text(l10n.colChannel, style: style),
          ),
          const SizedBox(width: ChannelColumns.gap),
          Expanded(
            flex: ChannelColumns.statusFlex,
            child: Text(l10n.colStatus, style: style),
          ),
          const SizedBox(width: ChannelColumns.gap),
          SizedBox(
            width: ChannelColumns.actions,
            child: Text(
              l10n.colChannelActions,
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// No channels yet: what a channel is, and the way to make one.
class _Empty extends StatelessWidget {
  const _Empty({required this.layout});

  final ChannelCardLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inset = _inset(layout);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        inset,
        layout == ChannelCardLayout.stacked ? Spacing.listRhythm : 0,
        inset,
        Spacing.emptyState,
      ),
      children: [
        Container(
          key: const Key('channels-empty'),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          decoration: BoxDecoration(
            color: context.scheme.surface,
            borderRadius: BorderRadius.circular(Radii.sheet),
            border: Border.all(color: context.colors.outline),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.scheme.primary,
                  borderRadius: BorderRadius.circular(Radii.sheet),
                ),
                child: const Icon(
                  Icons.videocam_outlined,
                  size: 30,
                  color: DarkTokens.accent,
                ),
              ),
              const SizedBox(height: Spacing.gutter),
              Text(
                l10n.noChannels,
                textAlign: TextAlign.center,
                style: context.text.headline.copyWith(
                  fontSize: 24,
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: Spacing.cardInternal),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  l10n.noChannelsBody,
                  textAlign: TextAlign.center,
                  style: context.text.body.copyWith(
                    fontSize: 15,
                    height: 23 / 15,
                    color: context.scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.gutter),
              const _NewChannelButton(key: Key('new-channel')),
              const SizedBox(height: 14),
              Text(
                l10n.noChannelsFootnote,
                textAlign: TextAlign.center,
                style: context.text.meta.copyWith(
                  fontSize: 13.5,
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// No spinner: the header, the band and three card slots hold their final
/// height, so nothing jumps when the counts arrive.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.layout});

  final ChannelCardLayout layout;

  @override
  Widget build(BuildContext context) {
    final inset = _inset(layout);
    final block = context.colors.skeleton;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: block,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    Widget card(double opacity) => Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(ChannelColumns.padding),
        decoration: BoxDecoration(
          color: context.scheme.surface,
          borderRadius: BorderRadius.circular(Radii.sheet),
          border: Border.all(color: context.colors.outlineSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: layout == ChannelCardLayout.stacked ? 120 : 176,
              height: layout == ChannelCardLayout.stacked ? 68 : 99,
              decoration: BoxDecoration(
                color: block,
                borderRadius: BorderRadius.circular(Radii.button),
              ),
            ),
            const SizedBox(width: ChannelColumns.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(110, 20),
                  const SizedBox(height: 10),
                  bar(160, 14),
                  const SizedBox(height: 8),
                  bar(80, 14),
                ],
              ),
            ),
            if (layout == ChannelCardLayout.row) ...[
              const SizedBox(width: ChannelColumns.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(120, 30),
                    const SizedBox(height: 10),
                    bar(150, 14),
                  ],
                ),
              ),
              const SizedBox(width: ChannelColumns.gap),
              bar(kMinTapTarget, kMinTapTarget),
              const SizedBox(width: 8),
              bar(kMinTapTarget, kMinTapTarget),
            ],
          ],
        ),
      ),
    );

    return ExcludeSemantics(
      child: ListView(
        key: const Key('channels-skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          inset,
          layout == ChannelCardLayout.stacked ? Spacing.listRhythm : 36,
          inset,
          Spacing.emptyState,
        ),
        children: [
          if (layout != ChannelCardLayout.stacked) ...[
            Row(children: [bar(240, 36), const Spacer(), bar(170, 48)]),
            const SizedBox(height: Spacing.gutter + 4),
          ],
          Container(
            height: layout == ChannelCardLayout.row ? 186 : 150,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(Radii.sheet),
            ),
          ),
          const SizedBox(height: Spacing.gutter),
          bar(double.infinity, 50),
          const SizedBox(height: Spacing.gutter),
          card(1),
          const SizedBox(height: Spacing.cardInternal),
          card(0.7),
          const SizedBox(height: Spacing.cardInternal),
          card(0.45),
        ],
      ),
    );
  }
}
