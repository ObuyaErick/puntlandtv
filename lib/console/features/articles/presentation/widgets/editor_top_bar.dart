import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/widgets/status_badge.dart';
import '../controllers/article_editor_controller.dart';

/// The editor's 64dp header: where you are, whether it is saved, and what you
/// can do to it.
class EditorTopBar extends StatelessWidget {
  const EditorTopBar({
    super.key,
    required this.editor,
    required this.canPublish,
    required this.onClose,
    required this.onTransition,
  });

  final ArticleEditor editor;
  final bool canPublish;
  final VoidCallback onClose;
  final void Function(ArticleStatus status, {DateTime? scheduledFor})
  onTransition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final article = editor.article;
    final title = editor.draft.title;
    final blocker = _publishBlocker(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: Spacing.gutter, right: Spacing.chip),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Below this there is no room for four controls beside a headline.
          // Preview and Save draft fold into the overflow rather than being
          // squeezed: the one action that must never move is the primary one.
          final roomy = constraints.maxWidth >= 900;

          return Row(
            children: [
              IconButton(
                onPressed: onClose,
                tooltip: l10n.backToArticles,
                constraints: const BoxConstraints.tightFor(
                  width: kMinTapTarget,
                  height: kMinTapTarget,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
              ),
              const SizedBox(width: Spacing.cardInternal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.isEmpty ? l10n.newArticle : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.cardTitle.copyWith(
                        color: context.scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _SaveLine(editor: editor),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.cardInternal),
              if (roomy) ...[
                StatusBadge.forArticle(article.status),
                const SizedBox(width: Spacing.chip + 2),
                OutlinedButton(
                  onPressed: () => _preview(context),
                  style: _outlined(context),
                  child: Text(l10n.preview),
                ),
                const SizedBox(width: Spacing.chip + 2),
                OutlinedButton(
                  onPressed: () => editor.saveDraft(),
                  style: _outlined(context),
                  child: Text(l10n.saveDraft),
                ),
                const SizedBox(width: Spacing.chip + 2),
              ] else
                _Overflow(
                  onPreview: () => _preview(context),
                  onSaveDraft: () => editor.saveDraft(),
                ),
              if (canPublish)
                _PublishButton(
                  blocker: blocker,
                  compact: !roomy,
                  onPublish: () => onTransition(ArticleStatus.published),
                  onSchedule: () => _schedule(context),
                  onSubmitForReview: () => onTransition(ArticleStatus.inReview),
                  onUnpublish: () => onTransition(ArticleStatus.draft),
                  isPublished: article.status == ArticleStatus.published,
                )
              else
                Tooltip(
                  message: blocker ?? '',
                  child: FilledButton(
                    // A journalist cannot publish, so the primary action is the
                    // one they *can* take: hand it to an editor. Showing them a
                    // disabled Publish button would be the console explaining
                    // their job to them on every screen.
                    onPressed: blocker != null
                        ? null
                        : () => onTransition(ArticleStatus.inReview),
                    child: Text(l10n.submitForReview),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Why the primary action is refused, or null when it is allowed.
  ///
  /// These are gates rather than warnings. An unlabelled hero image is
  /// unreadable to a screen-reader user and cannot be fixed after publication
  /// without re-releasing the story; a story with no headline or no body is not
  /// a story.
  ///
  /// The last one is not about the story at all but about the actor: every move
  /// out of `published` is an unpublish, and the backend requires the publish
  /// right for all of them. Without this a journalist would see an enabled
  /// button on their own live story and get a refusal from the server.
  String? _publishBlocker(BuildContext context) {
    final l10n = context.l10n;
    final source = editor.draftFor(editor.article.sourceLocale);

    if (!canPublish && editor.article.status == ArticleStatus.published) {
      return l10n.unpublishNeedsEditor;
    }
    if (source.title.trim().isEmpty) return l10n.headlineRequired;
    if (source.wordCount == 0) return l10n.bodyRequired;
    if (editor.article.imageId != null && editor.article.imageAlt == null) {
      return l10n.altTextRequired;
    }
    return null;
  }

  ButtonStyle _outlined(BuildContext context) => OutlinedButton.styleFrom(
    minimumSize: const Size(0, 40),
    side: BorderSide(color: context.colors.outline, width: 1.5),
    foregroundColor: context.scheme.primary,
  );

  void _preview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _PreviewDialog(editor: editor),
    );
  }

  Future<void> _schedule(BuildContext context) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: editor.article.scheduledFor ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (day == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(editor.article.scheduledFor ?? now),
    );
    if (time == null) return;

    onTransition(
      ArticleStatus.scheduled,
      scheduledFor: DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ),
    );
  }
}

/// "Saved 21:12 · autosave on · article #4182", and what replaces it mid-write.
class _SaveLine extends StatelessWidget {
  const _SaveLine({required this.editor});

  final ArticleEditor editor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failed = editor.saveState == ArticleSaveState.failed;

    final text = switch (editor.saveState) {
      ArticleSaveState.saving => l10n.saving,
      ArticleSaveState.failed => l10n.saveFailed,
      _ =>
        '${l10n.savedAt(AppDateFormat.time(editor.article.updatedAt, context.languageCode))}'
            ' · ${l10n.articleRef(editor.article.id)}',
    };

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.meta.copyWith(
        color: failed ? context.scheme.error : context.scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Publish, with the other state changes behind the caret beside it.
class _PublishButton extends StatelessWidget {
  const _PublishButton({
    required this.blocker,
    required this.compact,
    required this.onPublish,
    required this.onSchedule,
    required this.onSubmitForReview,
    required this.onUnpublish,
    required this.isPublished,
  });

  final String? blocker;

  /// Narrow enough that the button's label has to go.
  final bool compact;

  final VoidCallback onPublish;
  final VoidCallback onSchedule;
  final VoidCallback onSubmitForReview;
  final VoidCallback onUnpublish;
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Tooltip(
      // The refusal is said in words on hover and read out by a screen reader,
      // rather than left as a greyed-out button an editor has to guess at.
      message: blocker ?? '',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: blocker != null ? null : onPublish,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(Radii.button),
                ),
              ),
            ),
            child: compact
                ? Semantics(
                    label: l10n.publishNow,
                    child: const Icon(Icons.publish_rounded, size: 18),
                  )
                : Text(l10n.publishNow),
          ),
          MenuAnchor(
            menuChildren: [
              MenuItemButton(
                onPressed: blocker != null ? null : onSchedule,
                child: Text(l10n.scheduleFor),
              ),
              MenuItemButton(
                onPressed: onSubmitForReview,
                child: Text(l10n.submitForReview),
              ),
              if (isPublished)
                MenuItemButton(
                  onPressed: onUnpublish,
                  child: Text(l10n.unpublish),
                ),
            ],
            builder: (context, controller, _) => FilledButton(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(Radii.button),
                  ),
                ),
              ),
              child: Semantics(
                label: l10n.publishOptions,
                child: const Icon(Icons.expand_more_rounded, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The story as the app would render it.
///
/// Reads the draft rather than the saved article: the point of a preview is to
/// check the sentence you just wrote, and one that showed the last autosave
/// would answer a question nobody asked.
class _PreviewDialog extends StatelessWidget {
  const _PreviewDialog({required this.editor});

  final ArticleEditor editor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = editor.draft;

    return AlertDialog(
      title: Text(l10n.preview, style: context.text.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                draft.title.isEmpty ? l10n.newArticle : draft.title,
                style: context.text.headline.copyWith(
                  color: context.scheme.primary,
                ),
              ),
              if (draft.excerpt.isNotEmpty) ...[
                const SizedBox(height: Spacing.cardInternal),
                Text(
                  draft.excerpt,
                  style: context.text.bodyLarge.copyWith(
                    color: context.scheme.onSurface,
                  ),
                ),
              ],
              const SizedBox(height: Spacing.listRhythm),
              Text(
                l10n.wordCountAndRead(draft.wordCount, draft.readingMinutes),
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}


/// Preview and Save draft, folded away when the header runs out of room.
class _Overflow extends StatelessWidget {
  const _Overflow({required this.onPreview, required this.onSaveDraft});

  final VoidCallback onPreview;
  final VoidCallback onSaveDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(onPressed: onPreview, child: Text(l10n.preview)),
        MenuItemButton(onPressed: onSaveDraft, child: Text(l10n.saveDraft)),
      ],
      builder: (context, controller, _) => IconButton(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        tooltip: l10n.rowActions,
        constraints: const BoxConstraints.tightFor(
          width: kMinTapTarget,
          height: kMinTapTarget,
        ),
        icon: const Icon(Icons.more_vert_rounded, size: 20),
      ),
    );
  }
}
