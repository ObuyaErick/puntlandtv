import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_number_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../app/console_navigation.dart';
import '../../../../core/admin_api/dto/channel_dto.dart';
import '../../../../core/widgets/console_toast.dart';
import '../controllers/channel_controller.dart';
import '../pages/channel_panel.dart';
import 'channel_status_text.dart';
import 'stream_preview.dart';

/// How a channel card is laid out, by the width it has.
enum ChannelCardLayout {
  /// Desktop: one row in the list's column rhythm — order, preview, channel,
  /// status, actions — so the eye scans a straight edge.
  row,

  /// Tablet: the card in two rows, actions and the way in beneath. A quiet
  /// card — off air, hidden — keeps to one row so the loud ones keep the
  /// height.
  twoRows,

  /// Phone: everything stacked, the four actions spread across the width.
  stacked,
}

/// The desktop column rhythm, shared by the cards and the header above them.
abstract final class ChannelColumns {
  static const ord = 44.0;
  static const gap = 20.0;
  static const previewWidth = 176.0;
  static const previewHeight = 99.0;
  static const channelFlex = 13;
  static const statusFlex = 10;
  static const padding = 20.0;

  /// Four 48dp actions and the three 8dp gaps between them.
  static const actions = 4 * kMinTapTarget + 3 * 8.0;
}

/// One channel, as a status card.
///
/// A card rather than a table row because channels carry unequal amounts of
/// information: a live channel has a preview, uptime, two audiences, a
/// programme and a frequency, and an off-air one has almost nothing. Cards
/// let the live one be tall and loud and the off-air one quiet, and let the
/// one card that is failing readers change colour without wrecking a grid.
class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.channels,
    required this.index,
    required this.layout,
    required this.now,
  });

  /// The whole list, for the actions: order is a property of the list, and
  /// "the last channel cannot be deleted" is a fact about it.
  final List<ChannelDto> channels;
  final int index;
  final ChannelCardLayout layout;
  final DateTime now;

  ChannelDto get channel => channels[index];

  @override
  Widget build(BuildContext context) {
    final state = ChannelCardState.of(channel);
    final text = ChannelStatusText(context.l10n, context.languageCode, now);

    final content = switch (layout) {
      ChannelCardLayout.row => _RowCard(card: this, state: state, text: text),
      ChannelCardLayout.twoRows => _TwoRowCard(
        card: this,
        state: state,
        text: text,
      ),
      ChannelCardLayout.stacked => _StackedCard(
        card: this,
        state: state,
        text: text,
      ),
    };

    return _CardSurface(
      key: Key('channel-row-${channel.key}'),
      state: state,
      onTap: () => context.openChannelControl(channel.key),
      padding: switch (layout) {
        ChannelCardLayout.row => const EdgeInsets.all(ChannelColumns.padding),
        ChannelCardLayout.twoRows => const EdgeInsets.all(18),
        ChannelCardLayout.stacked => const EdgeInsets.all(Spacing.listRhythm),
      },
      child: content,
    );
  }
}

/// The card's ground, which is where the state is loudest.
///
/// The no-signal card is the only one with a filled error background and a
/// 2px border, so it reads as a different object at a glance across a dark
/// room. A hidden one has a dashed outline — visibly different, never
/// alarming. Everything else is a white card.
class _CardSurface extends StatelessWidget {
  const _CardSurface({
    super.key,
    required this.state,
    required this.onTap,
    required this.padding,
    required this.child,
  });

  final ChannelCardState state;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final Widget child;

  static final _radius = BorderRadius.circular(Radii.sheet);

  @override
  Widget build(BuildContext context) {
    final alarm = state == ChannelCardState.noSignal;
    final hidden = state == ChannelCardState.hidden;

    final material = Material(
      color: alarm ? context.scheme.errorContainer : context.scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: _radius,
        side: hidden
            ? BorderSide.none
            : BorderSide(
                color: alarm ? context.scheme.error : context.colors.outline,
                width: alarm ? 2 : 1,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      // The whole card opens the control room; the actions on it stop that
      // tap, being buttons of their own.
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (!hidden) return material;
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: context.colors.outline,
        radius: Radii.sheet,
      ),
      child: material,
    );
  }
}

/// A box with the hidden card's dashed outline, for the page's quiet prompts.
class ChannelDashedBox extends StatelessWidget {
  const ChannelDashedBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: context.colors.outline,
        radius: Radii.sheet,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}

// ---------------------------------------------------------------------------
// Layouts
// ---------------------------------------------------------------------------

class _RowCard extends StatelessWidget {
  const _RowCard({required this.card, required this.state, required this.text});

  final ChannelCard card;
  final ChannelCardState state;
  final ChannelStatusText text;

  @override
  Widget build(BuildContext context) {
    final channel = card.channel;

    final row = Row(
      children: [
        SizedBox(
          width: ChannelColumns.ord,
          child: _OrdNumber(position: card.index + 1),
        ),
        const SizedBox(width: ChannelColumns.gap),
        SizedBox(
          width: ChannelColumns.previewWidth,
          height: ChannelColumns.previewHeight,
          child: ChannelPreviewTile(channel: channel, state: state),
        ),
        const SizedBox(width: ChannelColumns.gap),
        Expanded(
          flex: ChannelColumns.channelFlex,
          child: _ChannelColumn(channel: channel, state: state, text: text),
        ),
        const SizedBox(width: ChannelColumns.gap),
        Expanded(
          flex: ChannelColumns.statusFlex,
          child: _StatusColumn(channel: channel, state: state, text: text),
        ),
        const SizedBox(width: ChannelColumns.gap),
        ChannelActions(channels: card.channels, index: card.index),
      ],
    );

    if (state != ChannelCardState.noSignal) return row;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        const SizedBox(height: Spacing.listRhythm),
        _NoSignalStrip(channel: channel),
      ],
    );
  }
}

class _TwoRowCard extends StatelessWidget {
  const _TwoRowCard({
    required this.card,
    required this.state,
    required this.text,
  });

  final ChannelCard card;
  final ChannelCardState state;
  final ChannelStatusText text;

  bool get _quiet =>
      state == ChannelCardState.offAir || state == ChannelCardState.hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final channel = card.channel;

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleLine(channel: channel, position: card.index + 1, chips: false),
        const SizedBox(height: Spacing.chip),
        _PillRow(channel: channel, state: state, text: text),
        const SizedBox(height: Spacing.chip),
        ..._compactLines(context, channel, state, text),
      ],
    );

    final preview = SizedBox(
      width: 164,
      height: 92,
      child: ChannelPreviewTile(channel: channel, state: state),
    );

    if (_quiet) {
      return Row(
        children: [
          preview,
          const SizedBox(width: Spacing.listRhythm),
          Expanded(child: summary),
          const SizedBox(width: Spacing.cardInternal),
          ChannelActions(channels: card.channels, index: card.index),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            preview,
            const SizedBox(width: Spacing.listRhythm),
            Expanded(child: summary),
          ],
        ),
        Divider(height: 32, color: context.colors.outlineSubtle),
        Row(
          children: [
            ChannelActions(channels: card.channels, index: card.index, gap: 10),
            const Spacer(),
            if (state == ChannelCardState.noSignal)
              _AlarmButton(
                label: l10n.openControlRoom,
                onPressed: () => context.openChannelControl(channel.key),
              )
            else
              _OpenControlRoomLink(channelKey: channel.key),
          ],
        ),
      ],
    );
  }
}

class _StackedCard extends StatelessWidget {
  const _StackedCard({
    required this.card,
    required this.state,
    required this.text,
  });

  final ChannelCard card;
  final ChannelCardState state;
  final ChannelStatusText text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final channel = card.channel;
    final loud =
        state == ChannelCardState.live || state == ChannelCardState.radioOnAir;

    final actions = ChannelActions(
      channels: card.channels,
      index: card.index,
      spread: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loud) ...[
          // The pill rides on the picture, where the eye already is.
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ChannelPreviewTile(channel: channel, state: state, bare: true),
                Positioned(
                  left: 10,
                  top: 10,
                  child: ChannelStatusPill.of(context, channel, state, text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (state == ChannelCardState.noSignal) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ChannelStatusPill.of(context, channel, state, text),
          ),
          const SizedBox(height: 10),
        ],
        _TitleLine(channel: channel, position: card.index + 1, chips: false),
        if (!loud && state != ChannelCardState.noSignal) ...[
          const SizedBox(height: Spacing.chip),
          _PillRow(channel: channel, state: state, text: text),
        ],
        const SizedBox(height: Spacing.chip),
        ..._compactLines(context, channel, state, text, phone: true),
        if (state == ChannelCardState.noSignal) ...[
          const SizedBox(height: Spacing.cardInternal),
          _AlarmButton(
            label: l10n.openControlRoom,
            onPressed: () => context.openChannelControl(channel.key),
            expand: true,
          ),
        ],
        Divider(height: 28, color: context.colors.outlineSubtle),
        actions,
      ],
    );
  }
}

/// The detail lines the tablet and phone cards share: one line of numbers,
/// one line of context.
List<Widget> _compactLines(
  BuildContext context,
  ChannelDto channel,
  ChannelCardState state,
  ChannelStatusText text, {
  bool phone = false,
}) {
  final l10n = context.l10n;
  final muted = _Styles.muted(context);
  final alarm = _Styles.alarm(context);

  switch (state) {
    case ChannelCardState.live:
      final context_ = [
        ?channel.nowPlayingTitle,
        if (channel.hasRadio) _stationLine(channel, compact: true),
      ];
      return [
        _StatLine(
          parts: [
            (channel.concurrentViewers, l10n.watchingWord),
            if (channel.hasRadio) (channel.radioListeners, l10n.listeningWord),
          ],
        ),
        if (context_.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(context_.join(' · '), style: muted),
        ],
      ];
    case ChannelCardState.noSignal:
      final silent = text.since(channel.lastFrameAt);
      return [
        Text(
          silent == null
              ? l10n.noSignalConsequenceShortNoDuration
              : l10n.noSignalConsequenceShort(text.duration(silent)),
          style: alarm,
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (channel.onAirSince case final since?)
              l10n.onAirSince(text.when(since)),
            '${AppNumberFormat.decimal(channel.concurrentViewers, context.languageCode)} '
                '${l10n.watchingWord}',
          ].join(' · '),
          style: muted.copyWith(color: context.scheme.onSurface),
        ),
      ];
    case ChannelCardState.radioOnAir:
      return [
        _StatLine(parts: [(channel.radioListeners, l10n.listeningWord)]),
        if (channel.radioFrequencyLabel case final frequency?) ...[
          const SizedBox(height: 2),
          Text(frequency, style: muted),
        ],
      ];
    case ChannelCardState.offAir:
      final line = _offAirLine(l10n, channel, text);
      return [if (line != null) Text(line, style: muted)];
    case ChannelCardState.hidden:
      final age = text.since(channel.createdAt);
      return [
        Text(
          age == null
              ? l10n.hiddenNotVisible
              : phone
              ? l10n.createdAgoShort(text.age(age))
              : l10n.createdAgoHidden(text.age(age)),
          style: muted,
        ),
      ];
  }
}

/// "Off air since yesterday 23:40 · nothing scheduled", from what is known.
String? _offAirLine(AppL10n l10n, ChannelDto channel, ChannelStatusText text) {
  final parts = [
    if (channel.offAirSince case final since?)
      l10n.offAirSince(text.when(since))
    else
      l10n.radioOffAirLine,
    if (channel.hasSchedule == false) l10n.nothingScheduled,
  ];
  return parts.join(' · ');
}

/// "Radio Puntland · 88.5 FM · Garoowe", or the compact form without the
/// first separator.
String _stationLine(ChannelDto channel, {bool compact = false}) {
  final station = channel.radioStationName.isEmpty
      ? channel.name
      : channel.radioStationName;
  final frequency = channel.radioFrequencyLabel;
  if (frequency == null || frequency.isEmpty) return station;
  return compact ? '$station $frequency' : '$station · $frequency';
}

// ---------------------------------------------------------------------------
// Desktop columns
// ---------------------------------------------------------------------------

class _OrdNumber extends StatelessWidget {
  const _OrdNumber({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$position',
      style: context.text.title.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: context.scheme.onSurfaceVariant,
      ),
    );
  }
}

class _ChannelColumn extends StatelessWidget {
  const _ChannelColumn({
    required this.channel,
    required this.state,
    required this.text,
  });

  final ChannelDto channel;
  final ChannelCardState state;
  final ChannelStatusText text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = _Styles.body(context);
    final muted = _Styles.muted(context);
    final strong = body.copyWith(
      fontWeight: FontWeight.w600,
      color: context.scheme.primary,
    );
    final mono = muted.copyWith(
      fontFamily: FontFamily.mono,
      color: context.scheme.primary,
    );

    final lines = <Widget>[];
    switch (state) {
      case ChannelCardState.live:
        final health = switch (channel.renditionsHealthy) {
          true => l10n.renditionsAllHealthy,
          false => l10n.renditionsSomeDegraded,
          null => null,
        };
        if (channel.nowPlayingTitle case final title?) {
          const mark = '\uE000';
          lines.add(
            Text.rich(
              TextSpan(
                style: body,
                children: [
                  ...markedSpans(l10n.nowPlayingLine(mark), {
                    mark: TextSpan(text: title, style: strong),
                  }),
                  if (health != null) TextSpan(text: ' · $health'),
                ],
              ),
            ),
          );
        } else if (health != null) {
          lines.add(Text(health, style: body));
        }
        if (channel.hasRadio) {
          lines.add(Text(_stationLine(channel), style: muted));
        }
      case ChannelCardState.noSignal:
        final silent = text.since(channel.lastFrameAt);
        lines.add(
          Text(
            silent == null
                ? l10n.noSignalConsequenceNoDuration
                : l10n.noSignalConsequence(text.duration(silent)),
            style: _Styles.alarm(context),
          ),
        );
        if (channel.onAirSince case final since?) {
          lines.add(
            Text(
              channel.lastFrameAt == null
                  ? l10n.onAirSince(text.when(since))
                  : l10n.onAirSinceLastFrame(
                      text.when(since),
                      text.clock(channel.lastFrameAt!),
                    ),
              style: muted,
            ),
          );
        }
      case ChannelCardState.offAir:
        if (_offAirLine(l10n, channel, text) case final line?) {
          lines.add(Text(line, style: body));
        }
        if (channel.isPublished) {
          lines.add(Text(l10n.visibleAsOffAir, style: muted));
        }
      case ChannelCardState.radioOnAir:
        lines.add(
          Text(
            channel.radioStreamHealthy == true
                ? l10n.radioAudioArriving
                : l10n.radioOnAirLine,
            style: body,
          ),
        );
        if (channel.radioFrequencyLabel case final frequency?) {
          lines.add(Text(frequency, style: muted));
        }
      case ChannelCardState.hidden:
        final age = text.since(channel.createdAt);
        lines.add(
          Text(
            age == null
                ? l10n.hiddenNotVisible
                : l10n.createdAgoHidden(text.age(age)),
            style: body,
          ),
        );
        if (channel.hasTv) {
          const mark = '\uE000';
          lines.add(
            Text.rich(
              TextSpan(
                style: muted,
                children: markedSpans(l10n.hiddenNextStep(mark), {
                  mark: TextSpan(text: channelPath(channel.key), style: mono),
                }),
              ),
            ),
          );
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleLine(channel: channel),
        for (final line in lines) ...[const SizedBox(height: 4), line],
      ],
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.channel,
    required this.state,
    required this.text,
  });

  final ChannelDto channel;
  final ChannelCardState state;
  final ChannelStatusText text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = _Styles.muted(context);
    final body = _Styles.body(context);

    final lines = <Widget>[];
    switch (state) {
      case ChannelCardState.live:
        lines.add(
          _StatLine(parts: [(channel.concurrentViewers, l10n.watchingWord)]),
        );
        if (channel.hasRadio) {
          lines.add(
            _StatLine(
              parts: [(channel.radioListeners, l10n.listeningWord)],
              suffix: channel.radioOnAir ? l10n.radioOnAirSuffix : null,
            ),
          );
        }
      case ChannelCardState.noSignal:
        const mark = '\uE000';
        lines
          ..add(
            Text.rich(
              TextSpan(
                style: body,
                children: markedSpans(l10n.ingestNotArriving(mark), {
                  mark: TextSpan(
                    text: l10n.ingestNotArrivingState,
                    style: body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.scheme.error,
                    ),
                  ),
                }),
              ),
            ),
          )
          ..add(
            _StatLine(
              parts: [(channel.concurrentViewers, l10n.watchingASpinner)],
            ),
          );
      case ChannelCardState.radioOnAir:
        lines.add(
          _StatLine(parts: [(channel.radioListeners, l10n.listeningWord)]),
        );
      case ChannelCardState.offAir:
        lines.add(
          Text(
            channel.ingestPublishing
                ? l10n.ingestSignalNotOnAir
                : l10n.noSignalExpected,
            style: muted,
          ),
        );
      case ChannelCardState.hidden:
        if (channel.neverOnAir) {
          lines.add(Text(l10n.neverBeenOnAir, style: muted));
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ChannelStatusPill.of(context, channel, state, text),
        for (final line in lines) ...[const SizedBox(height: 6), line],
      ],
    );
  }
}

/// "Either the encoder stopped publishing to /live/pltv3, or the studio
/// uplink dropped." — the likely causes, and the two fixes, on the card that
/// is failing.
class _NoSignalStrip extends ConsumerWidget {
  const _NoSignalStrip({required this.channel});

  final ChannelDto channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final body = _Styles.body(context);
    const mark = '\uE000';

    final cause = Text.rich(
      TextSpan(
        style: body,
        children: markedSpans(l10n.noSignalCause(mark), {
          mark: TextSpan(
            text: channelPath(channel.key),
            style: body.copyWith(fontFamily: FontFamily.mono),
          ),
        }),
      ),
    );

    final buttons = Wrap(
      spacing: Spacing.chip,
      runSpacing: Spacing.chip,
      children: [
        _AlarmButton(
          label: l10n.openControlRoom,
          onPressed: () => context.openChannelControl(channel.key),
        ),
        _PlainButton(
          label: l10n.takeOffAir,
          onPressed: () => takeChannelOffAir(context, ref, channel),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.all(color: context.colors.errorContainerOutline),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [cause, const SizedBox(height: 10), buttons],
            );
          }
          return Row(
            children: [
              Expanded(child: cause),
              const SizedBox(width: Spacing.listRhythm),
              buttons,
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The spotlight: one channel, expanded
// ---------------------------------------------------------------------------

/// The only channel, given the width instead of leaving the page empty: a
/// large preview, the audience in large numbers, rendition health and the
/// station as bulleted facts, and the schedule's now-and-until.
class ChannelSpotlightCard extends StatelessWidget {
  const ChannelSpotlightCard({
    super.key,
    required this.channels,
    required this.now,
  });

  final List<ChannelDto> channels;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final channel = channels.first;
    final state = ChannelCardState.of(channel);
    final text = ChannelStatusText(l10n, context.languageCode, now);
    final muted = _Styles.muted(context);
    final healthy = channel.renditionsHealthy;
    final labels = channel.renditions.map((r) => r.label).join(' · ');

    final facts = <(bool, String)>[
      if (healthy != null)
        (
          healthy,
          healthy
              ? l10n.renditionLabelsHealthy(labels)
              : l10n.renditionLabelsDegraded(labels),
        ),
      if (channel.hasRadio) (channel.radioOnAir, _stationLine(channel)),
    ];

    final details = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _TitleLine(channel: channel),
          const SizedBox(height: Spacing.listRhythm),
          Wrap(
            spacing: 36,
            runSpacing: Spacing.cardInternal,
            children: [
              if (channel.hasTv)
                _BigStat(
                  value: channel.concurrentViewers,
                  caption: l10n.watchingWord,
                ),
              if (channel.hasRadio)
                _BigStat(
                  value: channel.radioListeners,
                  caption: l10n.listeningWord,
                ),
            ],
          ),
          const SizedBox(height: Spacing.listRhythm),
          for (final (ok, fact) in facts) ...[
            _Bullet(ok: ok, text: fact),
            const SizedBox(height: 6),
          ],
          if (channel.nowPlayingTitle case final title?)
            Text(
              channel.nowPlayingEndsAt == null
                  ? l10n.nowPlayingLine(title)
                  : l10n.nowPlayingUntil(
                      title,
                      text.when(channel.nowPlayingEndsAt!),
                    ),
              style: muted,
            ),
          Divider(height: 32, color: context.colors.outlineSubtle),
          Row(
            children: [
              ChannelActions(channels: channels, index: 0),
              const SizedBox(width: Spacing.listRhythm),
              Flexible(child: _OpenControlRoomLink(channelKey: channel.key)),
            ],
          ),
        ],
      ),
    );

    return _CardSurface(
      key: Key('channel-row-${channel.key}'),
      state: state,
      onTap: () => context.openChannelControl(channel.key),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 9,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 300),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ChannelPreviewTile(
                      channel: channel,
                      state: state,
                      bare: true,
                      rounded: false,
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: ChannelStatusPill.of(
                        context,
                        channel,
                        state,
                        text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(flex: 11, child: details),
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.caption});

  final int value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppNumberFormat.decimal(value, context.languageCode),
          style: context.text.headline.copyWith(
            fontFamily: FontFamily.sans,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: context.scheme.primary,
          ),
        ),
        Text(caption, style: _Styles.muted(context)),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ok ? context.colors.accent : context.scheme.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: _Styles.body(context))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

abstract final class _Styles {
  static TextStyle body(BuildContext context) => context.text.body.copyWith(
    fontSize: 15,
    height: 22 / 15,
    color: context.scheme.onSurface,
  );

  static TextStyle muted(BuildContext context) => context.text.body.copyWith(
    fontSize: 14.5,
    height: 21 / 14.5,
    color: context.scheme.onSurfaceVariant,
  );

  /// The consequence line on the failing card: bold and red, in operator
  /// language rather than a status word.
  static TextStyle alarm(BuildContext context) => context.text.body.copyWith(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
    color: context.scheme.error,
  );
}

/// The name in the serif, the key in monospace beside it, and what the
/// channel carries — or, on tablet and phone, the position before the name.
class _TitleLine extends StatelessWidget {
  const _TitleLine({required this.channel, this.position, this.chips = true});

  final ChannelDto channel;

  /// Shown as "2 · PLTV 3" where there is no order column to carry it.
  final int? position;

  /// Whether to show the carries/hidden chips. The compact cards move them
  /// into the pill row.
  final bool chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.chip,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          position == null ? channel.name : '$position · ${channel.name}',
          style: context.text.cardTitle.copyWith(
            fontSize: 22,
            height: 28 / 22,
            color: context.scheme.primary,
          ),
        ),
        ChannelKeyChip(channelKey: channel.key),
        if (chips) ..._chipsFor(context, channel),
      ],
    );
  }
}

List<Widget> _chipsFor(BuildContext context, ChannelDto channel) {
  final l10n = context.l10n;
  if (!channel.isPublished) return const [ChannelHiddenChip()];
  return [
    _CarriesChip(
      label: channel.hasTv && channel.hasRadio
          ? l10n.chipTvAndRadio
          : channel.hasTv
          ? l10n.chipTvOnly
          : l10n.chipRadioOnly,
    ),
  ];
}

/// The status pill plus, on a hidden channel, the hidden chip beside it —
/// the compact cards' second line.
class _PillRow extends StatelessWidget {
  const _PillRow({
    required this.channel,
    required this.state,
    required this.text,
  });

  final ChannelDto channel;
  final ChannelCardState state;
  final ChannelStatusText text;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.chip,
      runSpacing: 6,
      children: [
        ChannelStatusPill.of(context, channel, state, text),
        if (!channel.isPublished) const ChannelHiddenChip(),
      ],
    );
  }
}

/// A channel key, shown as the identifier it is.
class ChannelKeyChip extends StatelessWidget {
  const ChannelKeyChip({super.key, required this.channelKey});

  final String channelKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.colors.outline),
      ),
      child: Text(
        channelKey,
        style: TextStyle(
          fontFamily: FontFamily.mono,
          fontSize: 13,
          height: 18 / 13,
          fontWeight: FontWeight.w500,
          color: context.scheme.primary,
        ),
      ),
    );
  }
}

class _CarriesChip extends StatelessWidget {
  const _CarriesChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.outlineSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: context.text.overline.copyWith(
          fontSize: 10.5,
          letterSpacing: 1,
          color: context.scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A crossed eye and "HIDDEN": visibly different, never alarming.
class ChannelHiddenChip extends StatelessWidget {
  const ChannelHiddenChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: 13,
            color: context.scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            context.l10n.channelHidden.toUpperCase(),
            style: context.text.overline.copyWith(
              fontSize: 10.5,
              letterSpacing: 1,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PillTone { live, alarm, quiet }

/// The status, in words, never colour alone.
///
/// Green and filled while live, red and filled with a warning triangle while
/// on air with no signal, and a hollow grey outline while off air — off air
/// being a normal state with nothing to fix. The label wraps to two lines
/// rather than truncating: Somali's are the longest on the page.
class ChannelStatusPill extends StatelessWidget {
  const ChannelStatusPill._(this._tone, this._label);

  factory ChannelStatusPill.of(
    BuildContext context,
    ChannelDto channel,
    ChannelCardState state,
    ChannelStatusText text,
  ) {
    final l10n = context.l10n;

    // The words are uppercase, the duration is not: "LIVE · 2h 04m". The
    // duration goes in as a mark, the sentence is uppercased around it, and
    // the mark is swapped back — so a translation can put it anywhere.
    const mark = '\uE000';
    String upper(String Function(String) template, Duration? uptime) =>
        uptime == null
        ? ''
        : template(mark).toUpperCase().replaceAll(mark, text.duration(uptime));

    return switch (state) {
      ChannelCardState.live => ChannelStatusPill._(
        _PillTone.live,
        switch (text.since(channel.liveSince)) {
          final uptime? => upper(l10n.pillLiveFor, uptime),
          null => l10n.live.toUpperCase(),
        },
      ),
      ChannelCardState.noSignal => ChannelStatusPill._(
        _PillTone.alarm,
        l10n.pillNoSignal.toUpperCase(),
      ),
      ChannelCardState.radioOnAir => ChannelStatusPill._(
        _PillTone.live,
        switch (text.since(channel.radioOnAirSince)) {
          final uptime? => upper(l10n.pillOnAirFor, uptime),
          null => l10n.pillOnAir.toUpperCase(),
        },
      ),
      ChannelCardState.offAir || ChannelCardState.hidden => ChannelStatusPill._(
        _PillTone.quiet,
        l10n.pillOffAir.toUpperCase(),
      ),
    };
  }

  final _PillTone _tone;
  final String _label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (_tone) {
      _PillTone.live => (context.colors.accent, Colors.white, null),
      _PillTone.alarm => (context.scheme.error, Colors.white, null),
      _PillTone.quiet => (
        context.scheme.surface,
        context.scheme.onSurfaceVariant,
        context.colors.outline,
      ),
    };

    final Widget lead = switch (_tone) {
      _PillTone.live => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
      _PillTone.alarm => const Icon(
        Icons.warning_amber_rounded,
        size: 15,
        color: Colors.white,
      ),
      _PillTone.quiet => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: foreground, width: 1.4),
        ),
      ),
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          lead,
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _label,
              style: context.text.overline.copyWith(
                fontSize: 11.5,
                height: 16 / 11.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The preview tile, which says the state where the picture would be.
///
/// Live video when there is a playlist to play; otherwise a tile drawn for
/// the state — an explicit "no frames" on the failing card, so the absence is
/// visible where the picture should be, and a quiet striped placeholder for a
/// channel that is simply off air.
class ChannelPreviewTile extends StatelessWidget {
  const ChannelPreviewTile({
    super.key,
    required this.channel,
    required this.state,
    this.bare = false,
    this.rounded = true,
  });

  final ChannelDto channel;
  final ChannelCardState state;

  /// No LIVE flag of its own, because the caller lays the status pill over
  /// the picture.
  final bool bare;

  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final caption = TextStyle(
      fontFamily: FontFamily.mono,
      fontSize: 12,
      height: 16 / 12,
      color: context.scheme.onSurfaceVariant.withValues(alpha: 0.75),
    );

    final Widget tile = switch (state) {
      ChannelCardState.live when channel.previewUrl != null => StreamPreview(
        isLive: true,
        streamUrl: channel.previewUrl,
        showLiveFlag: !bare,
      ),
      ChannelCardState.live => _Striped(
        ground: BrandPalette.navy,
        stripe: const Color(0xFF0E2A57),
        child: bare
            ? null
            : Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _LiveFlag(label: l10n.live),
                ),
              ),
      ),
      ChannelCardState.noSignal => Container(
        color: DarkTokens.errorContainer,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 26,
                color: DarkTokens.error,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.previewNoFrames,
                style: caption.copyWith(color: DarkTokens.error),
              ),
            ],
          ),
        ),
      ),
      ChannelCardState.radioOnAir => Container(
        color: BrandPalette.navy,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.graphic_eq_rounded,
                size: 30,
                color: DarkTokens.accent,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.chipRadioOnly.toUpperCase(),
                style: context.text.overline.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  color: DarkTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      ChannelCardState.offAir || ChannelCardState.hidden => _Striped(
        ground: context.colors.outlineSubtle,
        stripe: context.colors.skeleton,
        child: Center(
          child: Text(
            channel.neverOnAir ? l10n.previewNotSetUp : l10n.previewOffAir,
            style: caption,
          ),
        ),
      ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(rounded ? Radii.button : 0),
      child: tile,
    );
  }
}

class _LiveFlag extends StatelessWidget {
  const _LiveFlag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.accent,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: context.text.overline.copyWith(
              fontSize: 9.5,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// A ground with diagonal stripes: the design's placeholder texture.
class _Striped extends StatelessWidget {
  const _Striped({required this.ground, required this.stripe, this.child});

  final Color ground;
  final Color stripe;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(ground: ground, stripe: stripe),
      child: SizedBox.expand(child: child),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter({required this.ground, required this.stripe});

  final Color ground;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 5;
    const spacing = 12.0;
    for (var x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) =>
      ground != oldDelegate.ground || stripe != oldDelegate.stripe;
}

/// "**4,182** watching · **1,904** listening" — the numbers carry the weight.
class _StatLine extends StatelessWidget {
  const _StatLine({required this.parts, this.suffix});

  final List<(int, String)> parts;

  /// Plain words after the last number: "· radio on air".
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final body = _Styles.body(context);
    final number = body.copyWith(
      fontWeight: FontWeight.w600,
      color: context.scheme.primary,
    );
    return Text.rich(
      TextSpan(
        style: body,
        children: [
          for (final (index, (value, word)) in parts.indexed) ...[
            if (index > 0) const TextSpan(text: ' · '),
            TextSpan(
              text: AppNumberFormat.decimal(value, context.languageCode),
              style: number,
            ),
            TextSpan(text: ' $word'),
          ],
          if (suffix != null) TextSpan(text: ' · $suffix'),
        ],
      ),
    );
  }
}

/// The red, filled button of the alarm: "Open control room".
class _AlarmButton extends StatelessWidget {
  const _AlarmButton({
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(expand ? double.infinity : 0, 48),
        backgroundColor: context.scheme.error,
        foregroundColor: Colors.white,
        textStyle: context.text.label.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
      ),
      child: Text(label),
    );
  }
}

/// The outlined companion to the alarm button: "Take off air".
class _PlainButton extends StatelessWidget {
  const _PlainButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: context.scheme.surface,
        foregroundColor: context.scheme.primary,
        side: BorderSide(color: context.colors.outline),
        textStyle: context.text.label.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
      ),
      child: Text(label),
    );
  }
}

class _OpenControlRoomLink extends StatelessWidget {
  const _OpenControlRoomLink({required this.channelKey});

  final String channelKey;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.openChannelControl(channelKey),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: context.colors.linkText,
        textStyle: context.text.label.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text('${context.l10n.openControlRoom} →'),
    );
  }
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

/// Move up, move down, edit and delete — four visible 48dp targets, one
/// click each, never an overflow menu.
///
/// Disabled buttons stay in place and keep their size, and a disabled delete
/// says why in a tooltip: on air, a signal arriving, or the last channel.
/// They stay focusable, so a keyboard or screen-reader user reaches the same
/// reason a pointer hovering there does.
class ChannelActions extends ConsumerStatefulWidget {
  const ChannelActions({
    super.key,
    required this.channels,
    required this.index,
    this.gap = 8,
    this.spread = false,
  });

  final List<ChannelDto> channels;
  final int index;
  final double gap;

  /// Across the full width, as on a phone.
  final bool spread;

  @override
  ConsumerState<ChannelActions> createState() => _ChannelActionsState();
}

class _ChannelActionsState extends ConsumerState<ChannelActions> {
  var _busy = false;

  ChannelDto get _channel => widget.channels[widget.index];

  Future<void> _move(int by) async {
    final keys = [for (final row in widget.channels) row.key];
    final to = widget.index + by;
    keys
      ..removeAt(widget.index)
      ..insert(to, _channel.key);

    setState(() => _busy = true);
    try {
      await ref.read(channelActionsProvider.notifier).reorder(keys);
    } on Failure catch (failure) {
      ref.invalidate(channelListProvider);
      if (mounted) {
        showConsoleToast(
          context,
          message: channelRefusal(context.l10n, failure),
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    try {
      await confirmDeleteChannel(
        context,
        ref,
        _channel,
        onConfirmed: () => setState(() => _busy = true),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Why delete is unavailable, as a heading and a sentence; null when it is
  /// available.
  (String, String)? _deleteBlocked(AppL10n l10n) {
    final channel = _channel;
    if (channel.tvOnAir) {
      return (
        l10n.deleteBlockedOnAirTitle,
        [
          l10n.deleteBlockedOnAirBody(channel.name),
          if (channel.ingestPublishing) l10n.deleteBlockedSignalBody,
        ].join(' '),
      );
    }
    if (channel.ingestPublishing) {
      return (l10n.deleteBlockedSignalTitle, l10n.deleteBlockedSignalBody);
    }
    if (channel.radioOnAir) {
      return (
        l10n.deleteBlockedOnAirTitle,
        l10n.deleteBlockedRadioBody(channel.name),
      );
    }
    if (widget.channels.length <= 1) {
      return (l10n.deleteBlockedLastTitle, l10n.deleteBlockedLastBody);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final channel = _channel;
    final alarm = ChannelCardState.of(channel) == ChannelCardState.noSignal;
    final blocked = _deleteBlocked(l10n);

    final buttons = [
      _ActionSquare(
        key: Key('move-up-${channel.key}'),
        icon: Icons.arrow_upward_rounded,
        tooltip: l10n.moveChannelUp,
        onPressed: _busy || widget.index == 0 ? null : () => _move(-1),
      ),
      _ActionSquare(
        key: Key('move-down-${channel.key}'),
        icon: Icons.arrow_downward_rounded,
        tooltip: l10n.moveChannelDown,
        onPressed: _busy || widget.index == widget.channels.length - 1
            ? null
            : () => _move(1),
      ),
      _ActionSquare(
        key: Key('edit-${channel.key}'),
        icon: Icons.edit_outlined,
        tooltip: l10n.editChannel,
        onPressed: _busy
            ? null
            : () => showChannelPanel(context, channel: channel),
      ),
      if (_busy)
        const SizedBox.square(
          dimension: kMinTapTarget,
          child: Center(
            child: SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        )
      else
        _ActionSquare(
          key: Key('delete-${channel.key}'),
          icon: Icons.delete_outline_rounded,
          tooltip: l10n.delete,
          destructive: true,
          // On the failing card, the disabled delete takes the card's tint
          // rather than a grey that would read as a hole in it.
          tintedWhenDisabled: alarm,
          blockedReason: blocked,
          onPressed: blocked == null ? _delete : null,
        ),
    ];

    if (widget.spread) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: buttons,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, button) in buttons.indexed) ...[
          if (index > 0) SizedBox(width: widget.gap),
          button,
        ],
      ],
    );
  }
}

/// A 48dp square icon button: white and outlined while it works, a flat grey
/// tile when it does not.
class _ActionSquare extends StatelessWidget {
  const _ActionSquare({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
    this.tintedWhenDisabled = false,
    this.blockedReason,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool tintedWhenDisabled;

  /// Heading and sentence explaining a disabled button, shown in place of
  /// the plain tooltip.
  final (String, String)? blockedReason;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = context.scheme;
    final ink = destructive ? scheme.error : scheme.primary;
    final disabledGround = tintedWhenDisabled
        ? Color.lerp(scheme.errorContainer, colors.errorContainerOutline, 0.55)!
        : scheme.surfaceContainerLow;

    final button = IconButton(
      onPressed: onPressed,
      tooltip: onPressed == null ? null : tooltip,
      icon: Icon(icon, size: 20),
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.square(kMinTapTarget)),
        minimumSize: const WidgetStatePropertyAll(Size.square(kMinTapTarget)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.button),
          ),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? BorderSide.none
              : BorderSide(
                  color: destructive
                      ? colors.errorContainerOutline
                      : colors.outline,
                ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? disabledGround
              : scheme.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? (destructive ? scheme.error : scheme.onSurfaceVariant)
                    .withValues(alpha: 0.38)
              : ink,
        ),
      ),
    );

    final reason = blockedReason;
    if (onPressed != null || reason == null) return button;

    // A disabled button takes no focus of its own, so the reason is given a
    // focus stop and a semantic label here: the keyboard and the screen
    // reader get what the pointer gets from hovering.
    return Semantics(
      button: true,
      enabled: false,
      label: tooltip,
      tooltip: '${reason.$1}. ${reason.$2}',
      child: Focus(
        child: Tooltip(
          richMessage: TextSpan(
            children: [
              TextSpan(
                text: '${reason.$1}\n',
                style: context.text.label.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: reason.$2,
                style: context.text.meta.copyWith(
                  fontSize: 13.5,
                  height: 19 / 13.5,
                  color: DarkTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: BrandPalette.navy,
            borderRadius: BorderRadius.circular(Radii.button),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33061733),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ExcludeSemantics(child: button),
        ),
      ),
    );
  }
}
