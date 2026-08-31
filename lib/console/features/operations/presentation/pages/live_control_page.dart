import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_number_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../../core/widgets/pltv_logo.dart';
import '../../../../core/admin_api/dto/broadcast_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_table.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../../core/widgets/status_badge.dart';

final broadcastControlProvider = FutureProvider<BroadcastControlDto>(
  (ref) => ref.watch(adminApiProvider).fetchBroadcastControl(),
);

/// Operations' control surface for the channel.
///
/// Two things it refuses to do: take the channel off air without a slate in
/// both languages, and disable the 240p rung. Neither refusal is a warning —
/// both are the control being unavailable, because both mistakes are silent
/// and land on the audience least able to report them.
class LiveControlPage extends ConsumerWidget {
  const LiveControlPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final control = ref.watch(broadcastControlProvider);

    // The whole screen is dark, per artboard 11C. Operations work at night in
    // a control room; a white page is the wrong instrument.
    return ColoredBox(
      color: DarkTokens.background,
      child: ConsolePage(
        onDark: true,
        title: l10n.liveControlTitle,
        actions: [
          if (control.value != null)
            StatusBadge(
              kind: control.value!.tvOnAir ? BadgeKind.live : BadgeKind.failed,
            ),
        ],
        child: control.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            failure: error is Failure
                ? error
                : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
            onRetry: () => ref.invalidate(broadcastControlProvider),
          ),
          data: (data) => _ControlBody(control: data),
        ),
      ),
    );
  }
}

/// A dark card: `#0A2247` on `#061733`, 1px `#1B3055`, radius 12, padding 20 —
/// the console's dark-surface container from artboard 11C.
class _DarkCard extends StatelessWidget {
  const _DarkCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      // `overflow:hidden` in the canvas, and load-bearing: a child with its
      // own background — the table header, a row fill — renders square and
      // pokes out through the rounded corners without it.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DarkTokens.surface,
        borderRadius: BorderRadius.circular(Radii.sheet),
        border: Border.all(color: DarkTokens.outline),
      ),
      child: child,
    );
  }
}

/// The stream preview, with its LIVE flag pinned to the corner.
class _StreamPreview extends StatelessWidget {
  const _StreamPreview({required this.isLive});

  final bool isLive;

  /// 212×120 on the TV panel, per the artboard.
  static const width = 212.0;
  static const height = 120.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF04101F),
                borderRadius: BorderRadius.circular(Radii.button),
              ),
              child: const Center(
                child: Icon(
                  Icons.videocam_outlined,
                  size: 26,
                  color: DarkTokens.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (isLive)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LightTokens.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  context.l10n.live,
                  style: context.text.overline.copyWith(
                    fontSize: 9.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlBody extends ConsumerWidget {
  const _ControlBody({required this.control});

  final BroadcastControlDto control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    Future<void> save(BroadcastControlDto next) async {
      await ref.read(adminApiProvider).saveBroadcastControl(next);
      ref.invalidate(broadcastControlProvider);
    }

    return ListView(
      padding: const EdgeInsets.all(Spacing.sectionBreak),
      children: [
        // TV beside radio at width, stacked below it: the two are read
        // together when checking whether the station is up.
        WindowSizeScope(
          builder: (context, size) {
            final tv = _TvPanel(control: control, onSave: save);
            final radio = _RadioPanel(control: control, onSave: save);

            if (!size.isAtLeastExpanded) {
              return Column(
                children: [
                  tv,
                  const SizedBox(height: Spacing.listRhythm),
                  radio,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tv),
                  const SizedBox(width: Spacing.listRhythm),
                  SizedBox(width: 300, child: radio),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: Spacing.sectionBreak),
        _DarkSectionLabel(
          label: l10n.sectionRenditions,
          note: l10n.protectedRungNote(RenditionConfigDto.protectedRung),
        ),
        const SizedBox(height: Spacing.cardInternal),
        _DarkCard(
          padding: EdgeInsets.zero,
          child: _RenditionsTable(
            control: control,
            onToggle: (rung, enabled) {
              final next = control.setRenditionEnabled(rung, enabled: enabled);
              if (identical(next, control)) {
                showConsoleToast(
                  context,
                  message: l10n.protectedRungNote(
                    RenditionConfigDto.protectedRung,
                  ),
                  kind: ToastKind.error,
                );
                return;
              }
              save(next);
            },
          ),
        ),
        const SizedBox(height: Spacing.sectionBreak),
        _DarkSectionLabel(
          label: l10n.sectionSlate,
          note: l10n.slateBothRequired,
        ),
        const SizedBox(height: Spacing.cardInternal),
        // Editor and preview side by side where there is width. Stretched
        // across a 1900dp window the inputs became a single unreadable line;
        // the preview is the natural thing to put in the other half.
        WindowSizeScope(
          builder: (context, size) {
            final editor = _SlateEditor(control: control, onSave: save);
            final preview = _SlatePreview(control: control);

            if (!size.isAtLeastExpanded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  editor,
                  const SizedBox(height: Spacing.listRhythm),
                  preview,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: editor),
                  const SizedBox(width: Spacing.listRhythm),
                  Expanded(flex: 2, child: preview),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// TV channel status, preview and on-air toggle.
class _TvPanel extends StatelessWidget {
  const _TvPanel({required this.control, required this.onSave});

  final BroadcastControlDto control;
  final ValueChanged<BroadcastControlDto> onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blocked = control.tvOnAir && !control.canGoOffAir;

    return _DarkCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StreamPreview(isLive: control.tvOnAir),
          const SizedBox(width: Spacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.sectionTvChannel,
                  style: context.text.overline.copyWith(
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.chip),
                Text(
                  control.channelName,
                  style: context.text.title.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.uptimeAndViewers(
                    '${control.uptime.inHours}h '
                    '${(control.uptime.inMinutes % 60).toString().padLeft(2, '0')}m',
                    AppNumberFormat.decimal(
                      control.concurrentViewers,
                      context.languageCode,
                    ),
                  ),
                  style: context.text.meta.copyWith(
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.gutter),
          // The toggle sits beside the channel it governs rather than spanning
          // the card. Stretched across the full width it read as a section
          // control, not as this channel's switch.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.onAir,
                      style: context.text.body.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: Spacing.cardInternal),
                    Switch(
                      key: const Key('tv-on-air'),
                      value: control.tvOnAir,
                      // Disabled rather than warned: an off-air channel with no
                      // slate is a dead player, and with only one language it is
                      // a dead player for everyone reading in the other.
                      onChanged: blocked
                          ? null
                          : (value) => onSave(control.copyWith(tvOnAir: value)),
                      activeThumbColor: Colors.white,
                      activeTrackColor: LightTokens.accent,
                      inactiveTrackColor: DarkTokens.surfaceRaised,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  control.canGoOffAir
                      ? l10n.switchingOffShowsSlate
                      : l10n.slateBothRequired,
                  textAlign: TextAlign.end,
                  style: context.text.meta.copyWith(
                    color: blocked
                        ? DarkTokens.error
                        : DarkTokens.onSurfaceVariant,
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

class _RadioPanel extends StatelessWidget {
  const _RadioPanel({required this.control, required this.onSave});

  final BroadcastControlDto control;
  final ValueChanged<BroadcastControlDto> onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.sectionRadio,
            style: context.text.overline.copyWith(
              color: DarkTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.chip),
          Text(
            l10n.radioTitle,
            style: context.text.title.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.radioStatusLine(
              48,
              AppNumberFormat.decimal(
                control.radioListeners,
                context.languageCode,
              ),
            ),
            style: context.text.meta.copyWith(
              color: DarkTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.gutter),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.onAir,
                  style: context.text.body.copyWith(color: Colors.white),
                ),
              ),
              Switch(
                key: const Key('radio-on-air'),
                value: control.radioOnAir,
                onChanged: (value) =>
                    onSave(control.copyWith(radioOnAir: value)),
                activeThumbColor: Colors.white,
                activeTrackColor: LightTokens.accent,
                inactiveTrackColor: DarkTokens.surfaceRaised,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkSectionLabel extends StatelessWidget {
  const _DarkSectionLabel({required this.label, this.note});

  final String label;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.overline.copyWith(
            color: DarkTokens.onSurfaceVariant,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note!,
            style: context.text.meta.copyWith(
              color: DarkTokens.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _RenditionsTable extends StatelessWidget {
  const _RenditionsTable({required this.control, required this.onToggle});

  final BroadcastControlDto control;
  final void Function(String rung, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final columns = [
      // Wide enough for the rung plus the KEY badge on the protected row.
      ConsoleColumn(label: l10n.colRung, width: 150),
      // The manifest URL is what an operator copies into a player to check a
      // rung by hand, so it earns a column rather than a detail panel.
      ConsoleColumn(label: l10n.colUrl, flex: 1),
      ConsoleColumn(label: l10n.colBitrate, width: 110),
      // Wide enough for the status dot plus the longer Somali label.
      ConsoleColumn(label: l10n.colHealth, width: 130),
      ConsoleColumn(label: l10n.colEnabled, width: 80, alignEnd: true),
    ];

    final last = control.renditions.last;

    return Column(
      children: [
        // A dark table needs its own header and dividers; the shared
        // `ConsoleTableHeader` is built for the white surface.
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.listRhythm),
          decoration: const BoxDecoration(
            color: DarkTokens.background,
            border: Border(bottom: BorderSide(color: DarkTokens.outline)),
          ),
          child: Row(
            children: [
              for (final column in columns) ...[
                _DarkCell(
                  column: column,
                  child: Text(
                    column.label,
                    textAlign: column.alignEnd
                        ? TextAlign.end
                        : TextAlign.start,
                    style: context.text.overline.copyWith(
                      fontSize: 10.5,
                      color: DarkTokens.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.cardInternal),
              ],
            ],
          ),
        ),
        for (final rendition in control.renditions)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.listRhythm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              // No divider under the last row: it would sit on top of the
              // card's own border and read as a doubled line.
              border: rendition.rung == last.rung
                  ? null
                  : const Border(bottom: BorderSide(color: DarkTokens.outline)),
            ),
            child: _DarkRow(
              columns: columns,
              cells: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        rendition.rung,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.label.copyWith(color: Colors.white),
                      ),
                    ),
                    if (rendition.isProtected) ...[
                      const SizedBox(width: Spacing.chip),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DarkTokens.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          l10n.keyRung,
                          style: context.text.overline.copyWith(
                            fontSize: 9,
                            color: const Color(0xFF04220F),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  rendition.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.meta.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
                Text(
                  rendition.bitrateLabel,
                  style: context.text.meta.copyWith(
                    color: DarkTokens.onSurface,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rendition.healthy
                            ? DarkTokens.accent
                            : DarkTokens.error,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        rendition.healthy ? l10n.healthy : l10n.degraded,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.meta.copyWith(
                          color: DarkTokens.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                Switch(
                  key: Key('rendition-${rendition.rung}'),
                  value: rendition.enabled,
                  onChanged: rendition.isProtected
                      ? null
                      : (value) => onToggle(rendition.rung, value),
                  activeThumbColor: const Color(0xFF04220F),
                  activeTrackColor: DarkTokens.accent,
                  inactiveTrackColor: DarkTokens.surfaceRaised,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A row on the dark table. Fixed-width cells, no ink, no light dividers.
class _DarkRow extends StatelessWidget {
  const _DarkRow({required this.columns, required this.cells});

  final List<ConsoleColumn> columns;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < columns.length; i++) ...[
          _DarkCell(
            column: columns[i],
            child: Align(
              alignment: columns[i].alignEnd
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: cells[i],
            ),
          ),
          const SizedBox(width: Spacing.cardInternal),
        ],
      ],
    );
  }
}

/// Sizes a cell by its column: fixed width, or flexible when the column has
/// none. Without this a flex column collapses to zero on the dark table.
class _DarkCell extends StatelessWidget {
  const _DarkCell({required this.column, required this.child});

  final ConsoleColumn column;
  final Widget child;

  @override
  Widget build(BuildContext context) => column.width != null
      ? SizedBox(width: column.width, child: child)
      : Expanded(flex: column.flex, child: child);
}

/// The off-air message, in every required language.
///
/// Real text fields with Material's own borders. Only a *validation* failure
/// paints one red — an untouched empty field is not an error, it is a field
/// nobody has filled in yet, and colouring it on arrival trains people to
/// ignore the colour.
class _SlateEditor extends StatefulWidget {
  const _SlateEditor({required this.control, required this.onSave});

  final BroadcastControlDto control;
  final ValueChanged<BroadcastControlDto> onSave;

  @override
  State<_SlateEditor> createState() => _SlateEditorState();
}

class _SlateEditorState extends State<_SlateEditor> {
  final _controllers = <String, TextEditingController>{};
  final _focus = <String, FocusNode>{};
  final _touched = <String>{};

  @override
  void initState() {
    super.initState();
    for (final locale in BroadcastControlDto.requiredSlateLocales) {
      final message = widget.control.slate[locale] ?? const SlateMessageDto();
      _controllers[locale] = TextEditingController(
        text: message.isComplete ? '${message.title} · ${message.detail}' : '',
      );
      _focus[locale] = FocusNode()
        ..addListener(() {
          if (_focus[locale]!.hasFocus) {
            setState(() => _touched.add(locale));
          } else {
            _persist(locale);
          }
        });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focus.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Persists on focus loss rather than on every keystroke: saving mid-word
  /// invalidates the provider and takes the caret with it.
  void _persist(String locale) {
    final raw = _controllers[locale]!.text.trim();
    final parts = raw.split('·');
    final next = SlateMessageDto(
      title: parts.first.trim(),
      detail: parts.length > 1 ? parts.sublist(1).join('·').trim() : '',
    );

    widget.onSave(
      widget.control.copyWith(slate: {...widget.control.slate, locale: next}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final locale in BroadcastControlDto.requiredSlateLocales) ...[
            _SlateField(
              label: context.languageNameOf(locale),
              controller: _controllers[locale]!,
              focusNode: _focus[locale]!,
              // An error only once someone has been in the field and left it
              // empty — the section note already says both are required.
              errorText:
                  _touched.contains(locale) &&
                      _controllers[locale]!.text.trim().isEmpty
                  ? context.l10n.required
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacing.listRhythm),
          ],
        ],
      ),
    );
  }
}

/// A dark-surface text field using Material's default borders.
class _SlateField extends StatelessWidget {
  const _SlateField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.label.copyWith(
            color: DarkTokens.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          maxLines: null,
          minLines: 2,
          style: context.text.body.copyWith(
            fontSize: 13.5,
            height: 20 / 13.5,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: DarkTokens.background,
            errorText: errorText,
            errorStyle: context.text.meta.copyWith(color: DarkTokens.error),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            // Ordinary borders in every state but error. The canvas rings a
            // completed field in green; that reads as a permanent alarm once
            // there is more than one field on screen.
            enabledBorder: border(DarkTokens.outlineStrong),
            focusedBorder: border(DarkTokens.link, 2),
            errorBorder: border(DarkTokens.error),
            focusedErrorBorder: border(DarkTokens.error, 2),
          ),
        ),
      ],
    );
  }
}

/// What the app renders while the channel is down.
class _SlatePreview extends StatelessWidget {
  const _SlatePreview({required this.control});

  final BroadcastControlDto control;

  @override
  Widget build(BuildContext context) {
    final preview = control.slateFor(context.languageCode);

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.slatePreview,
            style: context.text.overline.copyWith(
              color: DarkTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.cardInternal),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 170),
              decoration: BoxDecoration(
                color: const Color(0xFF04101F),
                borderRadius: BorderRadius.circular(Radii.button),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.gutter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PltvMark(height: 30, onDark: true),
                      const SizedBox(height: Spacing.listRhythm),
                      Text(
                        preview.title,
                        textAlign: TextAlign.center,
                        style: context.text.title.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview.detail,
                        textAlign: TextAlign.center,
                        style: context.text.meta.copyWith(
                          color: DarkTokens.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
