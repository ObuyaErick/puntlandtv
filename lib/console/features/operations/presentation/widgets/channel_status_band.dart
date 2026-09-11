import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_number_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../app/console_navigation.dart';
import '../../../../core/admin_api/dto/channel_dto.dart';
import '../pages/channel_panel.dart';
import 'channel_card.dart';
import 'channel_status_text.dart';

/// "On air now": the page's one summary, and its one alarm.
///
/// The console's dark surface on a light page — the same material every
/// channel's control room is made of, so opening a channel feels like walking
/// through this block into the room behind it rather than into a different
/// product.
///
/// The no-signal alarm appears here and only here, before the list: the
/// first of the five ways the design makes that one state unmissable.
class ChannelStatusBand extends StatelessWidget {
  const ChannelStatusBand({
    super.key,
    required this.channels,
    required this.layout,
    required this.now,
  });

  final List<ChannelDto> channels;
  final ChannelCardLayout layout;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.languageCode;

    // Readers' numbers: a hidden channel is on nobody's screen, so it counts
    // in neither the total nor the on-air figure.
    final published = channels.where((c) => c.isPublished).toList();
    final onAir = published.where((c) => c.tvOnAir || c.radioOnAir).length;
    // Viewers of a channel with no signal are watching a spinner, not the
    // channel; they are on its card, not in the total.
    final viewers = channels
        .where((c) => c.isLiveToReaders)
        .fold(0, (sum, c) => sum + c.concurrentViewers);
    final listeners = channels
        .where((c) => c.radioOnAir)
        .fold(0, (sum, c) => sum + c.radioListeners);
    final alarms = channels
        .where((c) => ChannelCardState.of(c) == ChannelCardState.noSignal)
        .toList();

    String number(int value) => AppNumberFormat.decimal(value, language);

    final overline = Text(
      l10n.onAirNow,
      style: context.text.overline.copyWith(
        fontSize: 11.5,
        letterSpacing: 1.5,
        color: DarkTokens.onSurfaceVariant,
      ),
    );

    final onAirCount = _Figure(
      value: '$onAir',
      of: ' / ${published.length}',
      caption: layout == ChannelCardLayout.stacked
          ? null
          : l10n.bandChannelsOnAir,
    );

    final Widget content;
    switch (layout) {
      case ChannelCardLayout.row:
        final stats = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            overline,
            const SizedBox(height: 18),
            Wrap(
              spacing: 48,
              runSpacing: Spacing.listRhythm,
              children: [
                onAirCount,
                _Figure(value: number(viewers), caption: l10n.bandTvViewers),
                _Figure(
                  value: number(listeners),
                  caption: l10n.bandRadioListeners,
                ),
              ],
            ),
          ],
        );
        content = alarms.isEmpty
            ? stats
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 11, child: stats),
                    const VerticalDivider(width: 48, color: DarkTokens.outline),
                    Expanded(
                      flex: 9,
                      child: _AlarmPanel(
                        alarms: alarms,
                        now: now,
                        form: _AlarmForm.full,
                      ),
                    ),
                  ],
                ),
              );
      case ChannelCardLayout.twoRows:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            overline,
            const SizedBox(height: 14),
            Wrap(
              spacing: 40,
              runSpacing: Spacing.cardInternal,
              children: [
                onAirCount,
                _Figure(
                  value: number(viewers),
                  caption: l10n.bandTvViewers,
                  small: true,
                ),
                _Figure(
                  value: number(listeners),
                  caption: l10n.bandListeners,
                  small: true,
                ),
              ],
            ),
            if (alarms.isNotEmpty) ...[
              const SizedBox(height: Spacing.listRhythm),
              _AlarmPanel(alarms: alarms, now: now, form: _AlarmForm.inline),
            ],
          ],
        );
      case ChannelCardLayout.stacked:
        final side = context.text.meta.copyWith(
          fontSize: 13.5,
          height: 19 / 13.5,
          color: DarkTokens.onSurfaceVariant,
        );
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            overline,
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: onAirCount),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${number(viewers)} ${l10n.watchingWord}',
                      style: side,
                    ),
                    Text(
                      '${number(listeners)} ${l10n.listeningWord}',
                      style: side,
                    ),
                  ],
                ),
              ],
            ),
            if (alarms.isNotEmpty) ...[
              const SizedBox(height: Spacing.listRhythm),
              _AlarmPanel(alarms: alarms, now: now, form: _AlarmForm.stacked),
            ],
          ],
        );
    }

    return Container(
      key: const Key('channel-status-band'),
      padding: EdgeInsets.all(switch (layout) {
        ChannelCardLayout.row => 24,
        ChannelCardLayout.twoRows => 20,
        ChannelCardLayout.stacked => 18,
      }),
      decoration: BoxDecoration(
        color: BrandPalette.navy,
        borderRadius: BorderRadius.circular(Radii.sheet),
      ),
      child: content,
    );
  }
}

/// A large white number, an optional smaller "/ 4", and a caption.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.value,
    this.of,
    this.caption,
    this.small = false,
  });

  final String value;
  final String? of;
  final String? caption;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final big = context.text.headline.copyWith(
      fontFamily: FontFamily.sans,
      fontSize: small ? 28 : 38,
      height: 1.15,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: value,
            style: big,
            children: [
              if (of != null)
                TextSpan(
                  text: of,
                  style: big.copyWith(
                    fontSize: small ? 17 : 19,
                    fontWeight: FontWeight.w400,
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: context.text.meta.copyWith(
              fontSize: 14,
              height: 20 / 14,
              color: DarkTokens.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

enum _AlarmForm { full, inline, stacked }

/// The no-signal alarm: what is failing, for how long, and the two fixes.
///
/// With several channels failing at once it counts them in the heading and
/// leads with the first — the fixes are per channel, and the rest are each
/// called out on their own cards below.
class _AlarmPanel extends ConsumerWidget {
  const _AlarmPanel({
    required this.alarms,
    required this.now,
    required this.form,
  });

  final List<ChannelDto> alarms;
  final DateTime now;
  final _AlarmForm form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final first = alarms.first;
    final text = ChannelStatusText(l10n, context.languageCode, now);
    final onAirFor = text.since(first.onAirSince);
    final silentFor = text.since(first.lastFrameAt);

    final headingStyle = context.text.overline.copyWith(
      fontSize: 12,
      height: 17 / 12,
      letterSpacing: 1.3,
      fontWeight: FontWeight.w700,
      color: DarkTokens.error,
    );
    final bodyStyle = context.text.body.copyWith(
      fontSize: 15,
      height: 22 / 15,
      color: DarkTokens.onSurface,
    );

    final heading = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: DarkTokens.error,
          ),
        ),
        const SizedBox(width: Spacing.chip),
        Expanded(
          child: Text(
            (form == _AlarmForm.full
                    ? l10n.alarmTitle(alarms.length)
                    : l10n.alarmTitleShort(first.name))
                .toUpperCase(),
            style: headingStyle,
          ),
        ),
      ],
    );

    final body = Text(
      form == _AlarmForm.full
          ? (onAirFor != null && silentFor != null
                ? l10n.alarmBody(
                    first.name,
                    text.minutes(onAirFor),
                    text.duration(silentFor),
                  )
                : l10n.alarmBodyNoDuration(first.name))
          : (silentFor != null
                ? l10n.alarmBodyShort(text.duration(silentFor))
                : l10n.alarmBodyShortNoDuration),
      style: bodyStyle,
    );

    void open() => context.openChannelControl(first.key);

    final Widget inner = switch (form) {
      _AlarmForm.full => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          heading,
          const SizedBox(height: 10),
          body,
          const SizedBox(height: Spacing.listRhythm),
          Wrap(
            spacing: Spacing.chip,
            runSpacing: Spacing.chip,
            children: [
              _SalmonButton(
                key: const Key('alarm-open'),
                label: l10n.openNamed(first.name),
                onPressed: open,
              ),
              OutlinedButton(
                key: const Key('alarm-take-off-air'),
                onPressed: () => takeChannelOffAir(context, ref, first),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: DarkTokens.outlineStrong),
                  textStyle: context.text.label.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(l10n.takeOffAir),
              ),
            ],
          ),
        ],
      ),
      _AlarmForm.inline => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                heading,
                const SizedBox(height: 4),
                Padding(padding: const EdgeInsets.only(left: 26), child: body),
              ],
            ),
          ),
          const SizedBox(width: Spacing.cardInternal),
          _SalmonButton(
            key: const Key('alarm-open'),
            label: l10n.openShort,
            onPressed: open,
          ),
        ],
      ),
      _AlarmForm.stacked => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          heading,
          const SizedBox(height: Spacing.chip),
          body,
          const SizedBox(height: 14),
          _SalmonButton(
            key: const Key('alarm-open'),
            label: l10n.openNamed(first.name),
            onPressed: open,
          ),
        ],
      ),
    };

    return Container(
      padding: EdgeInsets.all(form == _AlarmForm.full ? 18 : 14),
      decoration: BoxDecoration(
        color: Color.lerp(BrandPalette.navy, DarkTokens.surfaceRaised, 0.45),
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: DarkTokens.error, width: 1.5),
      ),
      child: inner,
    );
  }
}

/// The alarm's own button: the dark surface's error colour, filled, with
/// navy text — red-on-navy reads as the alarm without shouting in white.
class _SalmonButton extends StatelessWidget {
  const _SalmonButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        backgroundColor: DarkTokens.error,
        foregroundColor: BrandPalette.navy,
        textStyle: context.text.label.copyWith(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label),
    );
  }
}
