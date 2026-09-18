import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/ai_api/dto/ai_suggestion_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/widgets/side_panel.dart';
import '../controllers/article_editor_controller.dart';

/// Which fields of a suggestion a reviewer accepted.
///
/// Returned by [showTranslationReview], and the only thing that ever reaches
/// `ArticleEditor.applySuggestion`. A null field means "leave what is there" —
/// not "clear it" — which is why the caller passes these straight through
/// rather than mapping unticked boxes to empty strings.
class TranslationReviewResult {
  const TranslationReviewResult({
    this.title,
    this.excerpt,
    this.bodyHtml,
    this.caption,
  });

  final String? title;
  final String? excerpt;
  final String? bodyHtml;
  final String? caption;

  bool get isEmpty =>
      title == null && excerpt == null && bodyHtml == null && caption == null;
}

/// Opens the review panel for [suggestion] and answers what was accepted.
///
/// Null when the reviewer discarded it, closed the panel, or ticked nothing.
Future<TranslationReviewResult?> showTranslationReview({
  required BuildContext context,
  required ArticleEditor editor,
  required ArticleTranslationSuggestion suggestion,
}) => showSidePanel<TranslationReviewResult>(
  context: context,
  builder: (_) =>
      TranslationReviewPanel(editor: editor, suggestion: suggestion),
);

/// Where a machine translation is read before any of it becomes the article.
///
/// The entire safety argument for this feature lives in this widget. A model
/// that writes straight into the editor is a model whose mistakes are published
/// under a journalist's byline; one that proposes into a panel somebody has to
/// tick through is a drafting tool. The two differ by exactly this screen, so
/// it is deliberately a little slower than it could be:
///
/// - Every field is shown in full, never summarised or diffed away.
/// - Each is accepted **separately**, because an editor commonly wants the
///   suggested headline and their own standfirst.
/// - A field that would overwrite existing text says so, next to the tick.
/// - If the source language moved while this was open, that is said at the top
///   rather than discovered afterwards.
///
/// The panel does not save. It hands back what was accepted, and the caller
/// writes one language through the ordinary save path.
class TranslationReviewPanel extends StatefulWidget {
  const TranslationReviewPanel({
    super.key,
    required this.editor,
    required this.suggestion,
  });

  final ArticleEditor editor;
  final ArticleTranslationSuggestion suggestion;

  @override
  State<TranslationReviewPanel> createState() => _TranslationReviewPanelState();
}

class _TranslationReviewPanelState extends State<TranslationReviewPanel> {
  /// Ticked by default, for every field the suggestion actually carries.
  ///
  /// Defaulting to on rather than off because the common case is accepting the
  /// lot, and a panel that made an editor tick four boxes to do the expected
  /// thing would teach them to stop reading the boxes.
  late final Map<_Field, bool> _accepted = {
    for (final field in _Field.values)
      if (_valueOf(field) != null) field: true,
  };

  String? _valueOf(_Field field) {
    final suggestion = widget.suggestion;
    final value = switch (field) {
      _Field.title => suggestion.title,
      _Field.excerpt => suggestion.excerpt,
      _Field.caption => suggestion.caption,
      _Field.body => suggestion.bodyHtml,
    };
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// What the target language holds right now, to warn about replacement.
  String? _currentOf(_Field field) {
    final draft = widget.editor.draftFor(widget.suggestion.to);
    final value = switch (field) {
      _Field.title => draft.title,
      _Field.excerpt => draft.excerpt,
      _Field.caption => draft.caption,
      _Field.body => draft.bodyHtml,
    };
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get _anyAccepted => _accepted.values.any((on) => on);

  void _apply() {
    String? taken(_Field field) =>
        (_accepted[field] ?? false) ? _valueOf(field) : null;

    Navigator.of(context).pop(
      TranslationReviewResult(
        title: taken(_Field.title),
        excerpt: taken(_Field.excerpt),
        bodyHtml: taken(_Field.body),
        caption: taken(_Field.caption),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suggestion = widget.suggestion;
    final targetName = context.languageNameOf(suggestion.to);

    final sourceUpdatedAt =
        widget.editor.article.translations[suggestion.from]?.updatedAt;
    final sourceMoved = suggestion.isStaleAgainst(sourceUpdatedAt);

    return SidePanelScaffold(
      title: l10n.aiReviewTitle(targetName),
      subtitle: l10n.aiReviewIntro,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.aiDiscard),
        ),
        FilledButton(
          onPressed: _anyAccepted ? _apply : null,
          child: Text(l10n.aiApplySelected),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MachineBadge(),
          if (sourceMoved) ...[
            const SizedBox(height: Spacing.cardInternal),
            _SourceMovedNote(language: context.languageNameOf(suggestion.from)),
          ],
          const SizedBox(height: Spacing.listRhythm),
          for (final field in _Field.values)
            if (_valueOf(field) case final value?) ...[
              _FieldCard(
                label: field.label(l10n, suggestion.to.toUpperCase()),
                value: value,
                isHtml: field == _Field.body,
                replaces: _currentOf(field),
                accepted: _accepted[field] ?? false,
                onChanged: (on) => setState(() => _accepted[field] = on),
              ),
              const SizedBox(height: Spacing.cardInternal),
            ],
        ],
      ),
    );
  }
}

enum _Field {
  title,
  excerpt,
  caption,
  body;

  /// Reuses the composer's own field labels, locale code and all.
  ///
  /// Every card in this panel is the same language, so the code is strictly
  /// redundant here — and it is kept anyway, because a reviewer glancing at one
  /// card should not have to remember which direction they asked for.
  String label(AppL10n l10n, String locale) => switch (this) {
    _Field.title => l10n.editorHeadline(locale),
    _Field.excerpt => l10n.editorExcerpt(locale),
    _Field.caption => l10n.editorCaption(locale),
    _Field.body => l10n.editorBody(locale),
  };
}

/// States what this text is, once, at the top.
///
/// Present because the panel is otherwise indistinguishable from an editing
/// form, and a reviewer who forgets they are reading model output is a reviewer
/// who stops reviewing.
class _MachineBadge extends StatelessWidget {
  const _MachineBadge();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 14,
            color: context.scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.aiMachineDrafted,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SourceMovedNote extends StatelessWidget {
  const _SourceMovedNote({required this.language});

  final String language;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: context.scheme.errorContainer,
      borderRadius: Radii.cardBorder,
      border: Border.all(color: context.colors.errorContainerOutline),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: context.scheme.error,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            context.l10n.aiSourceChanged(language),
            style: context.text.meta.copyWith(
              color: context.scheme.error,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

/// One field, in full, with its own tick.
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.value,
    required this.isHtml,
    required this.replaces,
    required this.accepted,
    required this.onChanged,
  });

  final String label;
  final String value;
  final bool isHtml;

  /// The text this would overwrite, or null when the field is empty.
  final String? replaces;

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(
          color: accepted ? scheme.primary : context.colors.outline,
          width: accepted ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(Spacing.cardInternal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The whole row toggles: a 44dp target beats an 18dp one for a
              // decision somebody makes four times per story.
              Checkbox(
                value: accepted,
                onChanged: (on) => onChanged(on ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.text.meta.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (replaces != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.aiReplaceWarning,
                        style: context.text.meta.copyWith(color: scheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.cardInternal),
          // Rendered as it will read, not as a source string. A reviewer
          // judging a translation should be looking at the paragraphs and
          // headings a reader will see, not at markup.
          if (isHtml)
            HtmlWidget(value, textStyle: context.text.body)
          else
            Text(value, style: context.text.body),
        ],
      ),
    );
  }
}
