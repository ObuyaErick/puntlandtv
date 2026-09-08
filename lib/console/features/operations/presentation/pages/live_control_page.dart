import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/app_number_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/playback/video_engine.dart';
import '../../../../../core/playback/video_engine_factory.dart';
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
    this.padding = const EdgeInsets.all(inset),
  });

  /// Named so a caller working out how much room a card leaves its content
  /// does not have to repeat the number.
  static const inset = 20.0;

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

/// Names the protected rung in the operator's language.
///
/// The server decides which one it is and sends `protected` on the row, so
/// this reads the flag rather than comparing against a hard-coded `240p` —
/// which protected a row that does not exist under the passthrough setup.
String _protectedRungNote(BuildContext context, BroadcastControlDto control) {
  final rung = control.renditions
      .where((rendition) => rendition.isProtected)
      .map((rendition) => rendition.rung)
      .firstOrNull;
  return context.l10n.protectedRungNote(rung ?? '');
}

/// The playlist the preview plays.
///
/// The highest-bitrate rung that is enabled and healthy — the same choice
/// `GET /v1/live` makes for a reader, so the operator is watching what the
/// audience is watching rather than a stream picked by different rules.
String? _previewUrl(BroadcastControlDto control) {
  final playable =
      control.renditions
          .where((rendition) => rendition.enabled && rendition.healthy)
          .toList(growable: false)
        ..sort((a, b) => b.bitrateKbps.compareTo(a.bitrateKbps));
  return playable.isEmpty ? null : playable.first.url;
}

/// The stream preview: the actual channel, with its LIVE flag pinned to the
/// corner.
///
/// This was a static box with a `videocam` glyph in it — a picture of a
/// preview. An operator's first question about a live channel is "what is
/// going out", and the one screen built to answer it could not.
///
/// Plays the same URL a reader gets, so it fails the same way a reader's
/// player fails. Muted, because the alternative is a newsroom where every open
/// tab is talking, and because a browser refuses to autoplay audible video
/// without a gesture anyway.
class _StreamPreview extends StatefulWidget {
  const _StreamPreview({required this.isLive, this.streamUrl, this.maxWidth});

  final bool isLive;

  /// The playlist to show. Null, or off air, renders the placeholder.
  final String? streamUrl;

  /// Caps the preview below its artboard size, keeping the aspect. Stacked on
  /// a phone the card has less than 212 to give once its padding is paid.
  final double? maxWidth;

  /// 212×120 on the TV panel, per the artboard.
  static const width = 212.0;
  static const height = 120.0;

  @override
  State<_StreamPreview> createState() => _StreamPreviewState();
}

class _StreamPreviewState extends State<_StreamPreview> {
  VideoEngine? _engine;
  StreamSubscription<VideoEngineState>? _sub;
  String? _loadedUrl;

  bool get _shouldPlay =>
      widget.isLive && (widget.streamUrl?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_StreamPreview old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Starts, stops, or re-points the preview to match the channel.
  ///
  /// Guarded on the URL so the poll-driven rebuilds this screen does every few
  /// seconds do not restart playback on every tick.
  void _sync() {
    if (!_shouldPlay) {
      if (_loadedUrl != null) {
        _sub?.cancel();
        _sub = null;
        _engine?.dispose();
        _engine = null;
        _loadedUrl = null;
      }
      return;
    }
    if (_loadedUrl == widget.streamUrl) return;

    _loadedUrl = widget.streamUrl;
    final engine = _engine ??= createVideoEngine();

    // Replaced, not stacked: the engine outlives a URL, so re-listening
    // without cancelling would leave one live subscription per channel change,
    // each calling setState on every frame.
    _sub?.cancel();
    _sub = engine.states.listen((_) {
      if (mounted) setState(() {});
    });
    // Volume zero, and stated at load time rather than after: an audible
    // autoplay is refused outright without a user gesture, so a preview that
    // asks to be silent afterwards never starts at all.
    engine.load(widget.streamUrl!, live: true, volume: 0);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.maxWidth == null
        ? _StreamPreview.width
        : math.max(0.0, math.min(_StreamPreview.width, widget.maxWidth!));
    return SizedBox(
      width: w,
      height: w * _StreamPreview.height / _StreamPreview.width,
      child: _box(context),
    );
  }

  Widget _box(BuildContext context) {
    final surface = _engine?.buildSurface(fit: BoxFit.cover);

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.button),
            child: ColoredBox(
              color: const Color(0xFF04101F),
              child:
                  surface ??
                  Center(
                    child: Icon(
                      widget.isLive
                          ? Icons.hourglass_empty_rounded
                          : Icons.videocam_off_outlined,
                      size: 26,
                      color: DarkTokens.onSurfaceVariant,
                    ),
                  ),
            ),
          ),
        ),
        if (widget.isLive)
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
        //
        // A LayoutBuilder rather than a WindowSizeScope, and it has to stay
        // outside the IntrinsicHeight below: intrinsics cannot be measured
        // through a layout callback, so the TV panel is handed the width it
        // will get instead of measuring it for itself.
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final sideBySide = width >= WindowSizeClass.expandedMin;
            final tvWidth = sideBySide
                ? (width - Spacing.listRhythm) * 3 / 5
                : width;

            final tv = _TvPanel(
              control: control,
              onSave: save,
              contentWidth: tvWidth - _DarkCard.inset * 2,
            );
            final radio = _RadioPanel(control: control, onSave: save);

            if (!sideBySide) {
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
                  Expanded(flex: 3, child: tv),
                  const SizedBox(width: Spacing.listRhythm),
                  Expanded(flex: 2, child: radio),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: Spacing.sectionBreak),
        _DarkSectionLabel(label: l10n.sectionIngest),
        const SizedBox(height: Spacing.cardInternal),
        _IngestPanel(
          control: control,
          onChanged: () => ref.invalidate(broadcastControlProvider),
        ),
        const SizedBox(height: Spacing.sectionBreak),
        _DarkSectionLabel(
          label: l10n.sectionRenditions,
          // Whichever rung the server flagged, not a constant the console
          // keeps its own copy of — with one passthrough rung that is
          // `source`, and when the ladder lands it is 240p again on its own.
          note: _protectedRungNote(context, control),
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
                  message: _protectedRungNote(context, control),
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

            if (!size.isAtLeastExpanded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  editor,
                  const SizedBox(height: Spacing.listRhythm),
                  _SlatePreview(control: control),
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: editor),
                  const SizedBox(width: Spacing.listRhythm),
                  Expanded(
                    flex: 2,
                    child: _SlatePreview(control: control, expand: true),
                  ),
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
  const _TvPanel({
    required this.control,
    required this.onSave,
    required this.contentWidth,
  });

  final BroadcastControlDto control;
  final ValueChanged<BroadcastControlDto> onSave;

  /// What the card has left for its contents once its own padding is paid.
  final double contentWidth;

  /// The preview, the channel name and the toggle need about this much between
  /// them before the name is squeezed to one word per line.
  static const _threeAcrossMin = 560.0;

  @override
  Widget build(BuildContext context) {
    final info = _TvIdentity(control: control);

    return _DarkCard(
      child: contentWidth >= _threeAcrossMin
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StreamPreview(
                  isLive: control.isLiveToReaders,
                  streamUrl: _previewUrl(control),
                ),
                const SizedBox(width: Spacing.gutter),
                Expanded(child: info),
                const SizedBox(width: Spacing.gutter),
                // The toggle sits beside the channel it governs rather than
                // spanning the card. Stretched across the full width it read
                // as a section control, not as this channel's switch.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: _TvOnAirToggle(control: control, onSave: onSave),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _StreamPreview(
                  isLive: control.isLiveToReaders,
                  streamUrl: _previewUrl(control),
                  maxWidth: contentWidth,
                ),
                const SizedBox(height: Spacing.listRhythm),
                info,
                const SizedBox(height: Spacing.listRhythm),
                // Stacked, the switch is unambiguously this card's, so it can
                // take the full width and read left to right.
                _TvOnAirToggle(
                  control: control,
                  onSave: onSave,
                  stretched: true,
                ),
              ],
            ),
    );
  }
}

/// What the packager is doing, and how to point an encoder at it.
///
/// Separate from the on-air switch above it because they are separate facts.
/// The switch is what the operator wants; this is what the studio is actually
/// sending. When they disagree, this is the panel that says which way.
class _IngestPanel extends ConsumerStatefulWidget {
  const _IngestPanel({required this.control, required this.onChanged});

  final BroadcastControlDto control;
  final VoidCallback onChanged;

  @override
  ConsumerState<_IngestPanel> createState() => _IngestPanelState();
}

class _IngestPanelState extends ConsumerState<_IngestPanel> {
  /// The secret from the most recent mint, held only until dismissed.
  ///
  /// Not in the DTO and not re-fetchable: the server stores a scrypt hash, so
  /// this is the one moment it exists anywhere the operator can reach.
  IngestKeyDto? _justMinted;
  bool _busy = false;

  Future<void> _mint() async {
    final label = await _askForLabel();
    if (label == null || label.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      final minted = await ref
          .read(adminApiProvider)
          .createIngestKey(label: label.trim());
      if (!mounted) return;
      setState(() => _justMinted = minted);
      widget.onChanged();
    } on Failure catch (failure) {
      if (!mounted) return;
      showConsoleToast(context, message: failure.code, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askForLabel() {
    final l10n = context.l10n;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DarkTokens.surface,
        title: Text(
          l10n.newIngestKeyTitle,
          style: context.text.title.copyWith(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: context.text.body.copyWith(color: Colors.white),
          decoration: InputDecoration(hintText: l10n.ingestKeyLabelHint),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.newIngestKey),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(IngestKeyDto key) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DarkTokens.surface,
        content: Text(
          l10n.revokeIngestKeyConfirm(key.label),
          style: context.text.body.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.revokeIngestKey),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).revokeIngestKey(key.id);
      widget.onChanged();
    } on Failure catch (failure) {
      if (!mounted) return;
      showConsoleToast(context, message: failure.code, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ingest = widget.control.ingest;

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HealthDot(healthy: ingest.isPublishing),
              const SizedBox(width: Spacing.chip),
              Text(
                ingest.isPublishing ? l10n.ingestPublishing : l10n.ingestIdle,
                style: context.text.body.copyWith(color: Colors.white),
              ),
              const Spacer(),
              if (_busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          // The two disagreement cases, each named. Silence here would leave
          // an operator comparing two indicators in different panels.
          if (widget.control.isArmedWithoutSignal)
            _IngestNote(text: l10n.ingestArmedNoSignal, isProblem: true),
          if (!widget.control.tvOnAir && ingest.isPublishing)
            _IngestNote(text: l10n.ingestSignalNotOnAir, isProblem: false),

          if (ingest.isPublishing) ...[
            const SizedBox(height: Spacing.cardInternal),
            _IngestFact(
              label: l10n.ingestProtocolLabel,
              value: ingest.protocol?.toUpperCase(),
            ),
            _IngestFact(
              label: l10n.ingestSourceLabel,
              value: ingest.videoLabel,
            ),
            _IngestFact(
              label: l10n.ingestPublisherLabel,
              value: ingest.publisher,
            ),
          ],

          const SizedBox(height: Spacing.cardInternal),
          _CopyableFact(label: l10n.ingestServerLabel, value: ingest.rtmpUrl),
          if (ingest.srtUrl.isNotEmpty)
            _CopyableFact(label: 'SRT', value: ingest.srtUrl),

          const SizedBox(height: Spacing.sectionBreak),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sectionIngestKeys,
                  style: context.text.overline.copyWith(
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('new-ingest-key'),
                onPressed: _busy ? null : _mint,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.newIngestKey),
                style: TextButton.styleFrom(
                  // Plain text on the navy surface all but disappears. A tonal
                  // accent chip reads as the affordance it is.
                  foregroundColor: DarkTokens.onAccentContainer,
                  backgroundColor: DarkTokens.accentContainer,
                  disabledForegroundColor: DarkTokens.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.cardInternal,
                    vertical: Spacing.chip,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                      color: DarkTokens.accentContainerOutline,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Shown once, with the reason it will not be shown again. Dismissing
          // it is the only way it leaves the screen — an operator who has not
          // copied it yet must not lose it to a rebuild.
          if (_justMinted?.secret != null)
            _MintedSecret(
              minted: _justMinted!,
              path: ingest.path,
              onDismiss: () => setState(() => _justMinted = null),
            ),

          if (widget.control.ingestKeys.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.chip),
              child: Text(
                l10n.noIngestKeys,
                style: context.text.meta.copyWith(color: DarkTokens.error),
              ),
            ),
          for (final key in widget.control.ingestKeys)
            _IngestKeyRow(
              entry: key,
              onRevoke: _busy ? null : () => _revoke(key),
            ),
        ],
      ),
    );
  }
}

/// A sentence about a disagreement between intent and signal.
class _IngestNote extends StatelessWidget {
  const _IngestNote({required this.text, required this.isProblem});

  final String text;
  final bool isProblem;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Spacing.chip),
    child: Text(
      text,
      style: context.text.meta.copyWith(
        color: isProblem ? DarkTokens.error : DarkTokens.onSurfaceVariant,
      ),
    ),
  );
}

/// One measured fact about the incoming signal.
class _IngestFact extends StatelessWidget {
  const _IngestFact({required this.label, required this.value});

  final String label;

  /// Null renders nothing at all. A labelled blank says less than no row.
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: context.text.meta.copyWith(
                color: DarkTokens.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: context.text.meta.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// A value an operator has to get into someone else's encoder verbatim.
class _CopyableFact extends StatelessWidget {
  const _CopyableFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: context.text.meta.copyWith(
                color: DarkTokens.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: context.text.meta.copyWith(color: Colors.white),
            ),
          ),
          _CopyButton(value: value),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.copyToClipboard,
    iconSize: 16,
    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    onPressed: () {
      Clipboard.setData(ClipboardData(text: value));
      showConsoleToast(context, message: context.l10n.copiedToClipboard);
    },
    icon: const Icon(
      Icons.content_copy_rounded,
      color: DarkTokens.onSurfaceVariant,
    ),
  );
}

/// A freshly minted secret, with the warning that it is the only showing.
class _MintedSecret extends StatelessWidget {
  const _MintedSecret({
    required this.minted,
    required this.path,
    required this.onDismiss,
  });

  final IngestKeyDto minted;
  final String path;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The whole Stream Key field, assembled — an operator copying two halves
    // into someone else's OBS over the phone is how a broadcast starts late.
    final streamKey = '$path?user=${minted.username}&pass=${minted.secret}';

    return Container(
      key: const Key('minted-ingest-secret'),
      margin: const EdgeInsets.only(top: Spacing.chip),
      padding: const EdgeInsets.all(Spacing.cardInternal),
      decoration: BoxDecoration(
        color: DarkTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.all(color: LightTokens.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ingestSecretShownOnce,
                  style: context.text.meta.copyWith(color: LightTokens.accent),
                ),
              ),
              IconButton(
                iconSize: 16,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: Spacing.chip),
          _CopyableFact(label: l10n.ingestStreamKeyLabel, value: streamKey),
        ],
      ),
    );
  }
}

/// One credential in the list, with what it is and when it was last used.
class _IngestKeyRow extends StatelessWidget {
  const _IngestKeyRow({required this.entry, required this.onRevoke});

  final IngestKeyDto entry;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.chip),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: context.text.label.copyWith(color: Colors.white),
                ),
                Text(
                  entry.username,
                  style: context.text.meta.copyWith(
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // "Never used" is the fastest way to spot a studio still configured
          // with the credential this one was minted to replace.
          Text(
            entry.hasNeverBeenUsed
                ? l10n.ingestKeyNeverUsed
                : l10n.ingestKeyLastUsed(
                    // Day and time, not a relative phrase: "2 hours ago" is
                    // read at a glance and then quoted wrongly in a handover
                    // an hour later.
                    '${AppDateFormat.dayMonth(entry.lastUsedAt!, context.languageCode)} '
                    '${AppDateFormat.time(entry.lastUsedAt!, context.languageCode)}',
                  ),
            style: context.text.meta.copyWith(
              color: entry.hasNeverBeenUsed
                  ? DarkTokens.error
                  : DarkTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Spacing.chip),
          TextButton(
            onPressed: onRevoke,
            style: TextButton.styleFrom(
              // Destructive, and it was near-invisible plain text before. An
              // error-toned chip both surfaces it and warns what it does.
              foregroundColor: DarkTokens.error,
              backgroundColor: DarkTokens.errorContainer,
              disabledForegroundColor: DarkTokens.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.cardInternal,
                vertical: Spacing.chip,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(
                  color: DarkTokens.errorContainerOutline,
                ),
              ),
            ),
            child: Text(l10n.revokeIngestKey),
          ),
        ],
      ),
    );
  }
}

/// Channel name, uptime and audience.
class _TvIdentity extends StatelessWidget {
  const _TvIdentity({required this.control});

  final BroadcastControlDto control;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
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
          style: context.text.meta.copyWith(color: DarkTokens.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The on-air switch and the sentence explaining why it may be unavailable.
class _TvOnAirToggle extends StatelessWidget {
  const _TvOnAirToggle({
    required this.control,
    required this.onSave,
    this.stretched = false,
  });

  final BroadcastControlDto control;
  final ValueChanged<BroadcastControlDto> onSave;

  /// Fills the card rather than hugging its own width.
  final bool stretched;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Blocked in both directions now, not just on the way down. While this
    // switch was the only thing that could take the channel off air, an
    // operator was always present when the slate was needed. A dropped feed
    // shows it unattended, so an incomplete slate is a latent outage and the
    // moment to refuse is before the channel goes up.
    final blocked = !control.canToggleOnAir;

    final label = Text(
      l10n.onAir,
      style: context.text.body.copyWith(color: Colors.white),
    );
    final switchControl = Switch(
      key: const Key('tv-on-air'),
      value: control.tvOnAir,
      // Disabled rather than warned: an off-air channel with no slate is a
      // dead player, and with only one language it is a dead player for
      // everyone reading in the other.
      onChanged: blocked
          ? null
          : (value) => onSave(control.copyWith(tvOnAir: value)),
      activeThumbColor: Colors.white,
      activeTrackColor: LightTokens.accent,
      inactiveTrackColor: DarkTokens.surfaceRaised,
    );
    final note = Text(
      !control.canToggleOnAir
          ? l10n.slateBothRequired
          // The armed-but-silent case is the one worth interrupting for: the
          // operator believes the channel is up and readers are seeing the
          // slate. Nothing else on this screen says so in a sentence.
          : control.isArmedWithoutSignal
          ? l10n.ingestArmedNoSignal
          : l10n.switchingOffShowsSlate,
      textAlign: stretched ? TextAlign.start : TextAlign.end,
      style: context.text.meta.copyWith(
        color: blocked || control.isArmedWithoutSignal
            ? DarkTokens.error
            : DarkTokens.onSurfaceVariant,
      ),
    );

    return Column(
      crossAxisAlignment: stretched
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: stretched ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Flexible either way: the Somali label plus a switch is wider
            // than the 200 the beside-the-channel form allows.
            if (stretched) Expanded(child: label) else Flexible(child: label),
            const SizedBox(width: Spacing.cardInternal),
            switchControl,
          ],
        ),
        const SizedBox(height: 4),
        note,
      ],
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

    // A channel that has never carried a ladder — or one whose rungs have not
    // arrived yet — has no rows to draw. The header alone would read as a
    // broken table, so say plainly that there is nothing yet.
    if (control.renditions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Spacing.listRhythm),
        child: Text(
          l10n.noRenditions,
          style: context.text.meta.copyWith(
            color: DarkTokens.onSurfaceVariant,
          ),
        ),
      );
    }

    final last = control.renditions.last;

    return WindowSizeScope(
      builder: (context, size) {
        // Five columns, four of them fixed, need ~700dp before the URL is
        // clipped to nothing. Below that each rung becomes its own block —
        // an operator on a phone still has to see health and flip a switch.
        if (!size.isAtLeastExpanded) {
          return Column(
            children: [
              for (final rendition in control.renditions)
                _RenditionCard(
                  rendition: rendition,
                  last: rendition.rung == last.rung,
                  onToggle: onToggle,
                ),
            ],
          );
        }

        return Column(
          children: [
            // A dark table needs its own header and dividers; the shared
            // `ConsoleTableHeader` is built for the white surface.
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.listRhythm,
              ),
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
                      : const Border(
                          bottom: BorderSide(color: DarkTokens.outline),
                        ),
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
                            style: context.text.label.copyWith(
                              color: Colors.white,
                            ),
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
      },
    );
  }
}

/// One rung as a block, for widths where the table cannot hold five columns.
class _RenditionCard extends StatelessWidget {
  const _RenditionCard({
    required this.rendition,
    required this.last,
    required this.onToggle,
  });

  final RenditionConfigDto rendition;
  final bool last;
  final void Function(String rung, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.listRhythm,
        vertical: Spacing.cardInternal,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: DarkTokens.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: Spacing.chip,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      rendition.rung,
                      style: context.text.label.copyWith(color: Colors.white),
                    ),
                    if (rendition.isProtected) const _KeyRungBadge(),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.chip),
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
          const SizedBox(height: 2),
          Row(
            children: [
              _HealthDot(healthy: rendition.healthy),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${rendition.healthy ? l10n.healthy : l10n.degraded}'
                  ' · ${rendition.bitrateLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.meta.copyWith(
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            rendition.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.meta.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: DarkTokens.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The badge marking the rung that cannot be switched off.
class _KeyRungBadge extends StatelessWidget {
  const _KeyRungBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: DarkTokens.accent,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        context.l10n.keyRung,
        style: context.text.overline.copyWith(
          fontSize: 9,
          color: const Color(0xFF04220F),
        ),
      ),
    );
  }
}

class _HealthDot extends StatelessWidget {
  const _HealthDot({required this.healthy});

  final bool healthy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: healthy ? DarkTokens.accent : DarkTokens.error,
      ),
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
          minLines: 3,
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
  const _SlatePreview({required this.control, this.expand = false});

  final BroadcastControlDto control;

  /// Fills the height of the row it shares with the editor. Only ever true
  /// inside that [IntrinsicHeight] — stacked, the card is a child of a
  /// scrollable and has no height to expand into.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final preview = control.slateFor(context.languageCode);

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            context.l10n.slatePreview,
            style: context.text.overline.copyWith(
              color: DarkTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.cardInternal),
          _MaybeExpanded(
            expand: expand,
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

/// [Expanded] where there is a height to expand into, a plain child where
/// there is not.
class _MaybeExpanded extends StatelessWidget {
  const _MaybeExpanded({required this.expand, required this.child});

  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) => expand ? Expanded(child: child) : child;
}
