import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/channel_dto.dart';
import '../../../../core/widgets/console_fields.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../../core/widgets/side_panel.dart';
import '../controllers/channel_controller.dart';

/// Opens the channel form: blank for [channel] null, otherwise that channel.
Future<void> showChannelPanel(BuildContext context, {ChannelDto? channel}) =>
    showSidePanel<void>(
      context: context,
      builder: (context) => ChannelPanel(channel: channel),
    );

/// The broadcast write's refusal for a slate not written in every language.
const _slateIncomplete = 'BROADCAST_SLATE_INCOMPLETE';

/// The sentence for a refused channel write, by the server's code.
String channelRefusal(AppL10n l10n, Failure failure) => switch (failure.code) {
  ChannelFailureCode.onAir => l10n.channelOnAirRefusal,
  ChannelFailureCode.last => l10n.deleteChannelBlockedLast,
  ChannelFailureCode.empty => l10n.channelNeedsSomething,
  ChannelFailureCode.keyTaken => l10n.channelKeyTakenError,
  ChannelFailureCode.orderMismatch => l10n.channelOrderStale,
  _slateIncomplete => l10n.slateBothRequired,
  _ => l10n.errorCodeLine(failure.code),
};

/// The stream path an encoder publishes [key] to, as the cards and the
/// delete confirmation name it.
String channelPath(String key) => '/live/$key';

/// [template] with [marks] replaced by their spans — how a translated
/// sentence carries a word in another style without being split into
/// fragments a translator cannot reorder. Each mark is a placeholder value
/// passed to the string, found and swapped here.
List<InlineSpan> markedSpans(String template, Map<String, InlineSpan> marks) {
  final spans = <InlineSpan>[];
  var rest = template;
  while (rest.isNotEmpty) {
    final next = marks.keys
        .map((mark) => (mark, rest.indexOf(mark)))
        .where((hit) => hit.$2 >= 0)
        .fold<(String, int)?>(
          null,
          (best, hit) => best == null || hit.$2 < best.$2 ? hit : best,
        );
    if (next == null) {
      spans.add(TextSpan(text: rest));
      break;
    }
    if (next.$2 > 0) spans.add(TextSpan(text: rest.substring(0, next.$2)));
    spans.add(marks[next.$1]!);
    rest = rest.substring(next.$2 + next.$1.length);
  }
  return spans;
}

/// Takes [channel]'s TV off air from the channel list, and says how it went.
Future<void> takeChannelOffAir(
  BuildContext context,
  WidgetRef ref,
  ChannelDto channel,
) async {
  final l10n = context.l10n;
  try {
    await ref.read(channelActionsProvider.notifier).takeOffAir(channel.key);
    if (context.mounted) {
      showConsoleToast(
        context,
        message: l10n.channelTakenOffAir(channel.name),
        kind: ToastKind.success,
      );
    }
  } on Failure catch (failure) {
    if (context.mounted) {
      showConsoleToast(
        context,
        message: channelRefusal(l10n, failure),
        kind: ToastKind.error,
      );
    }
  }
}

/// Asks before deleting [channel], then deletes it and says how it went.
///
/// Shared by the panel's Delete button and the channel list's row action, so
/// the question and the refusal read the same from either. [onConfirmed] fires
/// once the answer is yes, before the write, so the caller can show itself
/// busy. Returns whether the channel is gone.
Future<bool> confirmDeleteChannel(
  BuildContext context,
  WidgetRef ref,
  ChannelDto channel, {
  VoidCallback? onConfirmed,
}) async {
  final l10n = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _DeleteChannelDialog(channel: channel),
  );
  if (confirmed != true || !context.mounted) return false;

  onConfirmed?.call();
  try {
    await ref.read(channelActionsProvider.notifier).delete(channel.key);
    if (context.mounted) {
      showConsoleToast(
        context,
        message: l10n.channelDeleted(channel.name),
        kind: ToastKind.success,
      );
    }
    return true;
  } on Failure catch (failure) {
    // The row on screen was stale: the channel went on air, or the others
    // were deleted, since the list loaded. Re-read it so the disabled state
    // catches up with the refusal.
    ref.invalidate(channelListProvider);
    if (context.mounted) {
      showConsoleToast(
        context,
        message: channelRefusal(l10n, failure),
        kind: ToastKind.error,
      );
    }
    return false;
  }
}

/// Creates a channel, or edits and deletes one.
///
/// Built around the same lesson as the category form: the **key is
/// permanent** — the stream path every encoder publishes to and every player
/// reads from — so it is a checked field with a warning when creating and a
/// locked one when editing. Everything else about a channel is safe to change,
/// except while somebody is watching or listening to the part being changed,
/// which the server refuses and this form explains.
class ChannelPanel extends ConsumerStatefulWidget {
  const ChannelPanel({super.key, this.channel});

  /// Null when creating.
  final ChannelDto? channel;

  @override
  ConsumerState<ChannelPanel> createState() => _ChannelPanelState();
}

class _ChannelPanelState extends ConsumerState<ChannelPanel> {
  late final _key = TextEditingController(text: widget.channel?.key ?? '');
  late final _name = TextEditingController(text: widget.channel?.name ?? '');
  late final _radioUrl = TextEditingController(
    text: widget.channel?.radioStreamUrl ?? '',
  );
  late final _radioStation = TextEditingController(
    text: widget.channel?.radioStationName ?? '',
  );
  late final _radioFrequency = TextEditingController(
    text: widget.channel?.radioFrequencyLabel ?? '',
  );

  late bool _isPublished = widget.channel?.isPublished ?? false;
  late bool _hasTv = widget.channel?.hasTv ?? true;

  /// The key error stays quiet until someone has typed into the field, so a
  /// freshly opened form does not open by shouting at them.
  var _keyTouched = false;
  var _busy = false;

  bool get _isNew => widget.channel == null;

  @override
  void dispose() {
    for (final controller in [
      _key,
      _name,
      _radioUrl,
      _radioStation,
      _radioFrequency,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _keyValue => _key.text.trim();

  ChannelSettingsDto get _settings => ChannelSettingsDto(
    name: _name.text.trim(),
    isPublished: _isPublished,
    hasTv: _hasTv,
    radioStreamUrl: _radioUrl.text.trim(),
    radioStationName: _radioStation.text.trim(),
    radioFrequencyLabel: _radioFrequency.text.trim(),
  );

  String? _keyError(List<ChannelDto> existing) {
    if (!_isNew) return null;
    final key = _keyValue;
    if (key.length > ChannelDto.keyMaxLength ||
        !ChannelDto.keyPattern.hasMatch(key)) {
      return context.l10n.channelKeyFormatError;
    }
    if (existing.any((row) => row.key == key)) {
      return context.l10n.channelKeyTakenError;
    }
    return null;
  }

  bool _isDirty() {
    final original = widget.channel;
    if (original == null) return true;
    final before = original.settings;
    final after = _settings;
    return before.name != after.name ||
        before.isPublished != after.isPublished ||
        before.hasTv != after.hasTv ||
        before.radioStreamUrl != after.radioStreamUrl ||
        before.radioStationName != after.radioStationName ||
        before.radioFrequencyLabel != after.radioFrequencyLabel;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final actions = ref.read(channelActionsProvider.notifier);
    final settings = _settings;

    setState(() => _busy = true);
    try {
      if (_isNew) {
        await actions.create(key: _keyValue, settings: settings);
      } else {
        await actions.update(widget.channel!.key, settings);
      }
      if (!mounted) return;
      Navigator.of(context).maybePop();
      showConsoleToast(
        context,
        message: _isNew
            ? l10n.channelCreated(settings.name)
            : l10n.channelSaved(settings.name),
        kind: ToastKind.success,
      );
    } on Failure catch (failure) {
      if (!mounted) return;
      showConsoleToast(
        context,
        message: channelRefusal(l10n, failure),
        kind: ToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ChannelDto channel) async {
    try {
      final deleted = await confirmDeleteChannel(
        context,
        ref,
        channel,
        onConfirmed: () => setState(() => _busy = true),
      );
      if (deleted && mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final existing = ref.watch(channelListProvider).value ?? const [];
    final channel = _isNew
        ? null
        // The live row rather than the one the panel was opened with, so a
        // refetch after a refused delete updates the button and its reason.
        : existing.where((row) => row.key == widget.channel!.key).firstOrNull ??
              widget.channel;

    final keyError = _keyError(existing);
    final settings = _settings;
    final canSave =
        !_busy &&
        keyError == null &&
        settings.name.isNotEmpty &&
        !settings.isEmpty &&
        _isDirty();

    final isLast = existing.length <= 1;
    final deleteBlocked = channel == null
        ? null
        : !channel.canDelete
        ? l10n.deleteChannelBlockedOnAir
        : isLast
        ? l10n.deleteChannelBlockedLast
        : null;

    return SidePanelScaffold(
      title: _isNew ? l10n.newChannel : l10n.editChannel,
      subtitle: channel?.key,
      actions: [
        if (channel != null)
          // Disabled rather than hidden, with the reason below the form: "why
          // can I not delete this" is a question the panel has to answer.
          OutlinedButton(
            onPressed: !_busy && deleteBlocked == null
                ? () => _delete(channel)
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              side: BorderSide(color: context.colors.outline),
              foregroundColor: context.scheme.error,
            ),
            child: Text(l10n.delete),
          ),
        FilledButton(
          key: const Key('save-channel'),
          onPressed: canSave ? _save : null,
          child: Text(_isNew ? l10n.createChannel : l10n.save),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConsoleTextField(
            key: const Key('channel-key-field'),
            label: l10n.fieldChannelKey,
            controller: _key,
            hintText: l10n.channelKeyHint,
            enabled: _isNew,
            autofocus: _isNew,
            errorText: _keyTouched ? keyError : null,
            onChanged: (_) => setState(() => _keyTouched = true),
          ),
          const SizedBox(height: 6),
          Text(
            _isNew ? l10n.channelKeyChooseCarefully : l10n.channelKeyLocked,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sectionBreak),
          ConsoleTextField(
            key: const Key('channel-name-field'),
            label: l10n.fieldChannelName,
            controller: _name,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Spacing.sectionBreak),
          _SwitchRow(
            switchKey: const Key('channel-published'),
            label: l10n.channelPublishedLabel,
            hint: l10n.channelPublishedHint,
            value: _isPublished,
            onChanged: _busy
                ? null
                : (value) => setState(() => _isPublished = value),
          ),
          Divider(
            height: Spacing.sectionBreak,
            color: context.colors.outlineSubtle,
          ),
          _SwitchRow(
            switchKey: const Key('channel-has-tv'),
            label: l10n.channelHasTvLabel,
            hint: l10n.channelHasTvHint,
            value: _hasTv,
            onChanged: _busy ? null : (value) => setState(() => _hasTv = value),
          ),
          const SizedBox(height: Spacing.sectionBreak),
          Text(
            l10n.sectionChannelRadio,
            style: context.text.overline.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.cardInternal),
          // No radio switch: a channel has radio exactly when it has a stream
          // to play, so the URL *is* the switch and the two cannot disagree.
          ConsoleTextField(
            key: const Key('channel-radio-url-field'),
            label: l10n.fieldRadioStreamUrl,
            controller: _radioUrl,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.radioStreamUrlHint,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          if (settings.hasRadio) ...[
            const SizedBox(height: Spacing.listRhythm),
            ConsoleTextField(
              label: l10n.fieldRadioStationName,
              controller: _radioStation,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacing.listRhythm),
            ConsoleTextField(
              label: l10n.fieldRadioFrequency,
              controller: _radioFrequency,
              hintText: l10n.radioFrequencyHint,
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (settings.isEmpty) ...[
            const SizedBox(height: Spacing.listRhythm),
            Text(
              l10n.channelNeedsSomething,
              style: context.text.meta.copyWith(color: context.scheme.error),
            ),
          ],
          if (deleteBlocked != null) ...[
            const SizedBox(height: Spacing.sectionBreak),
            Text(
              deleteBlocked,
              style: context.text.meta.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A label, the sentence that explains it, and its switch — the row shape the
/// app configuration page uses, for the reason given there.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.switchKey,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.text.body.copyWith(
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.cardInternal),
        Switch.adaptive(key: switchKey, value: value, onChanged: onChanged),
      ],
    );
  }
}

/// The delete confirmation, always shown.
///
/// Says what goes and what it breaks — the key becomes free, and an encoder
/// still pointed at the path stops reaching anyone — with the key and path in
/// monospace so they read as the identifiers they are, and the irreversibility
/// set apart rather than trailing the paragraph.
class _DeleteChannelDialog extends StatelessWidget {
  const _DeleteChannelDialog({required this.channel});

  final ChannelDto channel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = context.text.body.copyWith(
      fontSize: 15,
      height: 22 / 15,
      color: context.scheme.onSurface,
    );
    final mono = body.copyWith(
      fontFamily: FontFamily.mono,
      color: context.scheme.primary,
    );

    // Placeholder values from the private-use area, which no translation
    // contains, found again after the string is built and swapped for the
    // monospace spans.
    const keyMark = '\uE000';
    const pathMark = '\uE001';

    return Dialog(
      backgroundColor: context.scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sheet),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.deleteChannelTitle(channel.name),
                style: context.text.headline.copyWith(
                  fontSize: 22,
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: Spacing.listRhythm),
              Text.rich(
                TextSpan(
                  style: body,
                  children: markedSpans(
                    l10n.deleteChannelBody(keyMark, pathMark),
                    {
                      keyMark: TextSpan(text: channel.key, style: mono),
                      pathMark: TextSpan(
                        text: channelPath(channel.key),
                        style: mono,
                      ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: Spacing.listRhythm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.listRhythm,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.scheme.errorContainer,
                  borderRadius: BorderRadius.circular(Radii.button),
                  border: Border.all(
                    color: context.colors.errorContainerOutline,
                  ),
                ),
                child: Text(l10n.cantBeUndone, style: body),
              ),
              const SizedBox(height: Spacing.gutter),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: Spacing.cardInternal,
                runSpacing: Spacing.chip,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: context.scheme.primary,
                      side: BorderSide(color: context.colors.outline),
                    ),
                    child: Text(l10n.keepChannel),
                  ),
                  FilledButton(
                    key: const Key('confirm-delete-channel'),
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: context.scheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.deleteChannelConfirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
