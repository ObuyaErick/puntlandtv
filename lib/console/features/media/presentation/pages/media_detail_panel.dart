import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/media_dto.dart';
import '../../../../core/widgets/console_fields.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../../core/widgets/side_panel.dart';
import '../controllers/media_library_controller.dart';
import '../media_format.dart';
import '../widgets/alt_text_editor.dart';
import '../widgets/media_thumbnail.dart';

/// Opens the asset panel.
Future<void> showMediaAsset(BuildContext context, {required String id}) {
  return showSidePanel<void>(
    context: context,
    builder: (context) => MediaDetailPanel(assetId: id),
  );
}

/// Everything about one asset, and the two decisions someone opens it to make:
/// describe it, or get rid of it.
///
/// Watches the asset by id rather than holding the row it was opened from, so
/// a save is reflected in place instead of requiring the panel to close and
/// the grid to be re-read.
class MediaDetailPanel extends ConsumerWidget {
  const MediaDetailPanel({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(mediaAssetProvider(assetId));

    return asset.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        failure: error is Failure
            ? error
            : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
        onRetry: () => ref.invalidate(mediaAssetProvider(assetId)),
      ),
      data: (value) => _Loaded(asset: value),
    );
  }
}

class _Loaded extends ConsumerStatefulWidget {
  const _Loaded({required this.asset});

  final MediaAssetDto asset;

  @override
  ConsumerState<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends ConsumerState<_Loaded> {
  late final Map<String, TextEditingController> _alt = {
    for (final locale in MediaAssetDto.requiredAltLocales)
      locale: TextEditingController(text: widget.asset.alt[locale] ?? ''),
  };
  late final _credit = TextEditingController(text: widget.asset.credit ?? '');

  var _saving = false;

  @override
  void dispose() {
    for (final controller in _alt.values) {
      controller.dispose();
    }
    _credit.dispose();
    super.dispose();
  }

  /// The draft as it stands in the fields, not as it stands on the server.
  ///
  /// The rule summary under the fields has to react to typing, not to saving —
  /// telling someone their alt text is incomplete after they have already
  /// filled it in is how a form loses trust.
  MediaAssetDto get _draft {
    var draft = widget.asset;
    for (final entry in _alt.entries) {
      draft = draft.withAlt(entry.key, entry.value.text);
    }
    return draft.copyWith(
      credit: _credit.text.trim().isEmpty ? null : _credit.text.trim(),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(mediaActionsProvider.notifier).save(_draft);
      if (!mounted) return;
      showConsoleToast(
        context,
        message: context.l10n.altTextSaved,
        kind: ToastKind.success,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final asset = widget.asset;
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAssetTitle),
        content: Text(l10n.deleteAssetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.scheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAsset),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final refused = await ref.read(mediaActionsProvider.notifier).delete([
      asset.id,
    ]);

    if (!mounted) return;
    Navigator.of(context).maybePop();
    showConsoleToast(
      context,
      message: refused.isEmpty
          ? l10n.assetDeleted(asset.filename)
          : l10n.deleteRefusedCount(refused.length),
      kind: refused.isEmpty ? ToastKind.success : ToastKind.error,
    );
  }

  Future<void> _retry() async {
    await ref.read(mediaActionsProvider.notifier).retryIngest(widget.asset.id);
    if (!mounted) return;
    showConsoleToast(context, message: context.l10n.retryQueued);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final asset = widget.asset;
    final draft = _draft;

    return SidePanelScaffold(
      title: l10n.mediaAssetTitle,
      subtitle: asset.filename,
      actions: [
        // Delete sits beside Save rather than behind an overflow: it is one of
        // exactly two things this panel is for. It is disabled — not hidden —
        // when the asset is in use, because "why can I not delete this" is a
        // question the screen has to answer, and a missing button answers
        // nothing.
        Tooltip(
          message: asset.canDelete ? '' : l10n.deleteBlockedInUse,
          child: OutlinedButton(
            onPressed: asset.canDelete ? _delete : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              side: BorderSide(color: context.colors.outline),
              foregroundColor: context.scheme.error,
            ),
            child: Text(l10n.deleteAsset),
          ),
        ),
        FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: Radii.cardBorder,
            child: MediaThumbnail(
              asset: asset,
              aspectRatio: 16 / 9,
              iconSize: 40,
            ),
          ),
          if (asset.hasFailed) ...[
            const SizedBox(height: Spacing.listRhythm),
            _IngestFailure(asset: asset, onRetry: _retry),
          ] else if (!asset.isReady) ...[
            const SizedBox(height: Spacing.listRhythm),
            ConsoleNotice(
              message: l10n.transcodeNotAttachable,
              icon: Icons.sync_rounded,
              warning: true,
            ),
          ],
          // Alt text applies to images and nothing else. A video needs a
          // caption track, which is a different rule at a different point in
          // the pipeline — showing empty alt fields on a video would teach the
          // newsroom that captions had been dealt with.
          if (asset.kind == MediaKind.image) ...[
            const SizedBox(height: Spacing.sectionBreak),
            _SectionLabel(l10n.sectionAltText),
            const SizedBox(height: Spacing.cardInternal),
            AltTextEditor(
              controllers: _alt,
              missingLocales: draft.missingAltLocales,
              onChanged: () => setState(() {}),
            ),
          ],
          const SizedBox(height: Spacing.sectionBreak),
          ConsoleTextField(label: l10n.fieldCredit, controller: _credit),
          const SizedBox(height: 6),
          Text(
            l10n.creditNotTranslated,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sectionBreak),
          _SectionLabel(l10n.sectionFileDetails),
          const SizedBox(height: Spacing.cardInternal),
          _FileDetails(asset: asset),
          const SizedBox(height: Spacing.sectionBreak),
          _SectionLabel(l10n.sectionUsage),
          const SizedBox(height: Spacing.cardInternal),
          _Usage(asset: asset),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.overline.copyWith(
        color: context.scheme.onSurfaceVariant,
      ),
    );
  }
}

/// The failure, its reason, and the one action that answers it.
class _IngestFailure extends StatelessWidget {
  const _IngestFailure({required this.asset, required this.onRetry});

  final MediaAssetDto asset;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(Spacing.listRhythm),
      decoration: BoxDecoration(
        color: context.scheme.errorContainer,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.errorContainerOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 17,
                color: context.scheme.error,
              ),
              const SizedBox(width: Spacing.chip),
              Text(
                l10n.transcodeFailedTitle,
                style: context.text.label.copyWith(color: context.scheme.error),
              ),
            ],
          ),
          if (asset.failureReason != null) ...[
            const SizedBox(height: Spacing.chip),
            // The reason comes from the ingest pipeline verbatim. It is
            // operator-facing diagnostics, not prose, which is why it is not
            // translated — the same string has to be greppable in the logs.
            Text(
              asset.failureReason!,
              style: context.text.meta.copyWith(
                color: context.scheme.onSurface,
              ),
            ),
          ],
          const SizedBox(height: Spacing.cardInternal),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                side: BorderSide(color: context.colors.errorContainerOutline),
                foregroundColor: context.scheme.error,
              ),
              label: Text(l10n.retryIngest),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileDetails extends StatelessWidget {
  const _FileDetails({required this.asset});

  final MediaAssetDto asset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = context.languageCode;

    return Column(
      children: [
        _DetailRow(label: l10n.fieldFilename, value: asset.filename),
        if (asset.dimensionLabel != null)
          _DetailRow(label: l10n.fieldDimensions, value: asset.dimensionLabel!),
        _DetailRow(
          label: l10n.fieldFileSize,
          value: MediaFormat.bytes(l10n, asset.byteSize, code),
        ),
        if (asset.duration != null)
          _DetailRow(
            label: l10n.fieldDuration,
            value: MediaFormat.duration(asset.duration!),
          ),
        _DetailRow(
          label: l10n.fieldUploaded,
          value: l10n.uploadedByOn(
            asset.uploadedBy,
            AppDateFormat.byline(asset.uploadedAt, code),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.cardInternal),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.body.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: Spacing.cardInternal),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.text.body.copyWith(color: context.scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// What points at this asset — the list that makes the delete refusal
/// actionable rather than merely correct.
class _Usage extends StatelessWidget {
  const _Usage({required this.asset});

  final MediaAssetDto asset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!asset.isInUse) {
      return Text(
        l10n.usedInCount(0),
        style: context.text.body.copyWith(
          color: context.scheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.usedInCount(asset.usageCount),
          style: context.text.body.copyWith(color: context.scheme.onSurface),
        ),
        if (asset.publishedUsageCount > 0) ...[
          const SizedBox(height: 2),
          // A published use is the expensive one: deleting behind it breaks a
          // page a reader can already open.
          Text(
            l10n.usedInPublishedCount(asset.publishedUsageCount),
            style: context.text.meta.copyWith(color: context.scheme.error),
          ),
        ],
        const SizedBox(height: Spacing.cardInternal),
        for (final use in asset.usedIn)
          Container(
            margin: const EdgeInsets.only(bottom: Spacing.chip),
            padding: const EdgeInsets.all(Spacing.cardInternal),
            decoration: BoxDecoration(
              color: context.scheme.surfaceContainerLow,
              borderRadius: Radii.cardBorder,
              border: Border.all(color: context.colors.outlineSubtle),
            ),
            child: Row(
              children: [
                Icon(
                  use.isPublished
                      ? Icons.public_rounded
                      : Icons.edit_note_rounded,
                  size: 16,
                  color: context.scheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.chip),
                Expanded(
                  child: Text(
                    use.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.meta.copyWith(
                      color: context.scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
