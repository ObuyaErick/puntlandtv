import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../app/console_navigation.dart';
import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/ai_api/ai_assist_controller.dart';
import '../../../../core/ai_api/ai_refusal.dart';
import '../../../../core/ai_api/dto/ai_suggestion_dto.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/console_user.dart';
import '../controllers/article_editor_controller.dart';
import '../controllers/article_list_controller.dart';
import '../../../media/presentation/media_format.dart';
import '../../../media/presentation/pages/media_detail_panel.dart';
import '../rich_text/article_body_editor.dart';
import '../rich_text/article_paste_handler.dart';
import '../widgets/editor_locale_tabs.dart';
import '../widgets/editor_top_bar.dart';
import '../widgets/headline_choices_dialog.dart';
import '../widgets/hero_image_panel.dart';
import '../widgets/publishing_panel.dart';
import '../widgets/translation_panel.dart';
import '../widgets/translation_review_panel.dart';

/// The article editor page, which is the canvas for writing and translating articles.
class ArticleEditorPage extends ConsumerWidget {
  const ArticleEditorPage({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleByIdProvider(articleId));

    return Scaffold(
      backgroundColor: context.scheme.surfaceContainerLow,
      body: article.when(
        loading: () => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(articleByIdProvider(articleId)),
        ),
        data: (loaded) => _Editor(key: ValueKey(loaded.id), article: loaded),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({super.key, required this.article});

  final AdminArticleDto article;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final ArticleEditor _editor = ArticleEditor(
    article: widget.article,
    api: ref.read(adminApiProvider),
    autosaveEnabled: () => _autosaveEnabled,
  );

  /// Whether the editor writes on its own.
  ///
  /// **On by default, and it lives here.** It is a property of this session at
  /// this desk — someone drafting a sensitive story who does not want half a
  /// sentence reaching the server, or working against a flaky connection —
  /// not a property of the article, and it should not outlive the screen. So
  /// [ArticleEditor] is handed a predicate rather than a flag: it asks, this
  /// answers, and there is one copy of the answer.
  ///
  /// Turning it off never discards anything. The edits stay in the drafts,
  /// the header says so, and Save draft, publishing and closing all still
  /// write — see `ArticleEditor.autosaveEnabled` for which paths are gated.
  var _autosaveEnabled = true;

  /// Drives the one assistance request this screen can have in flight.
  late final AiAssistController<ArticleTranslationSuggestion> _translator =
      AiAssistController(ai: ref.read(aiApiProvider));

  /// Separate from [_translator] on purpose: drafting a standfirst while a
  /// translation is still running is a reasonable thing to do, and one shared
  /// controller would refuse the second press for no reason the editor could see.
  late final AiAssistController<ExcerptSuggestion> _excerptWriter =
      AiAssistController(ai: ref.read(aiApiProvider));

  late final AiAssistController<HeadlineSuggestion> _headlineWriter =
      AiAssistController(ai: ref.read(aiApiProvider));

  @override
  void initState() {
    super.initState();
    _editor.addListener(_onEditorChanged);
    _translator.addListener(_onAssistChanged);
    _excerptWriter.addListener(_onAssistChanged);
    _headlineWriter.addListener(_onAssistChanged);
  }

  @override
  void dispose() {
    _headlineWriter
      ..removeListener(_onAssistChanged)
      ..dispose();
    _excerptWriter
      ..removeListener(_onAssistChanged)
      ..dispose();
    _translator
      ..removeListener(_onAssistChanged)
      ..dispose();
    _editor
      ..removeListener(_onEditorChanged)
      ..dispose();
    super.dispose();
  }

  void _onAssistChanged() {
    if (mounted) setState(() {});
  }

  /// Drafts a standfirst for [locale] from that language's own body.
  ///
  /// No review panel. One or two sentences landing in a visible, unsaved field
  /// is already the review — the editor is looking straight at it, and the
  /// autosave they already live with is what commits it. A panel to approve a
  /// sentence you can read in place would be ceremony, not care. The article
  /// body gets one because it is not readable at a glance.
  Future<void> _suggestExcerpt(String locale) async {
    final suggestion = await _excerptWriter.run(
      () => ref
          .read(aiApiProvider)
          .suggestExcerpt(articleId: _editor.article.id, locale: locale),
    );

    if (!mounted) return;
    if (suggestion == null) {
      final failure = _excerptWriter.error;
      if (failure != null) {
        showConsoleToast(
          context,
          message: assistRefusal(context.l10n, failure),
          kind: ToastKind.error,
        );
        _excerptWriter.reset();
      }
      return;
    }

    // Through `applySuggestion` rather than `setExcerpt`, because only that one
    // bumps the revision — and without the bump the field would keep showing
    // the old text while the draft held the new.
    _editor.applySuggestion(locale, excerpt: suggestion.excerpt);
    _excerptWriter.reset();
  }

  /// Whether this deployment offers machine translation at all.
  ///
  /// A deployment with no model key configured is a normal deployment, and the
  /// capabilities call is specified never to throw — so an unreachable or
  /// unconfigured backend reads as "no", and the affordance simply never
  /// appears. Nothing here asks the operator to deal with its absence.
  bool get _canDraft =>
      ref
          .watch(aiCapabilitiesProvider)
          .value
          ?.has(AiFeature.translateArticle) ??
      false;

  bool get _canSuggestExcerpt =>
      ref.watch(aiCapabilitiesProvider).value?.has(AiFeature.suggestExcerpt) ??
      false;

  bool get _canSuggestHeadlines =>
      ref
          .watch(aiCapabilitiesProvider)
          .value
          ?.has(AiFeature.suggestHeadlines) ??
      false;

  /// Offers alternative headlines for the language being edited.
  ///
  /// Chosen from a dialog rather than applied straight in, because unlike a
  /// standfirst there is already a headline there — replacing it without
  /// showing what it is replacing would be the one assistance path here that
  /// destroys a person's work without asking.
  Future<void> _suggestHeadlines() async {
    final locale = _editor.locale;
    final suggestion = await _headlineWriter.run(
      () => ref
          .read(aiApiProvider)
          .suggestHeadlines(articleId: _editor.article.id, locale: locale),
    );

    if (!mounted) return;
    if (suggestion == null) {
      final failure = _headlineWriter.error;
      if (failure != null) {
        showConsoleToast(
          context,
          message: assistRefusal(context.l10n, failure),
          kind: ToastKind.error,
        );
        _headlineWriter.reset();
      }
      return;
    }

    final chosen = await showHeadlineChoices(
      context,
      headlines: suggestion.headlines,
      current: _editor.draftFor(locale).title,
    );
    if (!mounted) return;

    _headlineWriter.reset();
    if (chosen == null) return;

    _editor.applySuggestion(locale, title: chosen);
  }

  /// Draft a translation of [locale], read it, then apply what was accepted.
  ///
  /// The order of the first two steps is the part that matters.
  ///
  /// **The source is saved first.** The backend translates what is *stored*,
  /// not what is in this browser's buffer, so an unflushed Somali edit would
  /// otherwise produce an English draft of the previous version — and the
  /// editor would have no way to tell. Flushing first also puts the source's
  /// clock before the translation's, which is exactly what the freshness model
  /// needs for the result to count as current.
  ///
  /// **Then a human reads it.** Nothing is written until the review panel comes
  /// back with the fields somebody ticked, and the write that follows is the
  /// ordinary one-locale save — the same event typing would have produced.
  Future<void> _draftTranslation(String locale) async {
    final source = _editor.article.sourceLocale;
    await _editor.saveDraft(locale: source);
    if (!mounted) return;

    final suggestion = await _translator.run(
      () => ref
          .read(aiApiProvider)
          .translateArticle(
            articleId: _editor.article.id,
            from: source,
            to: locale,
          ),
    );

    if (!mounted) return;
    if (suggestion == null) {
      final failure = _translator.error;
      if (failure != null) {
        showConsoleToast(
          context,
          message: assistRefusal(context.l10n, failure),
          kind: ToastKind.error,
        );
        _translator.reset();
      }
      return;
    }

    final accepted = await showTranslationReview(
      context: context,
      editor: _editor,
      suggestion: suggestion,
    );
    if (!mounted) return;

    _translator.reset();
    if (accepted == null || accepted.isEmpty) return;

    _editor.applySuggestion(
      locale,
      title: accepted.title,
      excerpt: accepted.excerpt,
      caption: accepted.caption,
      bodyHtml: accepted.bodyHtml,
    );
    // One language, one clock — the same write a typed edit performs.
    await _editor.saveDraft(locale: locale);
    if (!mounted) return;

    showConsoleToast(
      context,
      message: context.l10n.aiApplied(context.languageNameOf(locale)),
      kind: ToastKind.success,
    );
  }

  ArticleSaveState _lastSaveState = ArticleSaveState.idle;
  var _lastPasteCount = 0;

  void _onEditorChanged() {
    if (!mounted) return;
    if (_editor.saveState == ArticleSaveState.failed &&
        _lastSaveState != ArticleSaveState.failed) {
      showConsoleToast(
        context,
        message: context.l10n.saveFailed,
        kind: ToastKind.error,
      );
    }
    if (_editor.pasteCount != _lastPasteCount) {
      _lastPasteCount = _editor.pasteCount;
      _announcePaste(_editor.lastPasteOutcome!);
    }
    if (_editor.saveState == ArticleSaveState.saved &&
        _lastSaveState == ArticleSaveState.saving) {
      ref.read(articleActionsProvider.notifier).refreshList();
    }
    _lastSaveState = _editor.saveState;
    setState(() {});
  }

  /// Says what a paste did, and offers the one action that answers it.
  ///
  /// The undo on a reformat is the important one. Reading plain text as
  /// markdown is the only place this editor guesses, and a guess with no way
  /// back is a guess nobody should be making on someone's copy.
  void _announcePaste(ArticlePasteOutcome outcome) {
    final l10n = context.l10n;

    switch (outcome.result) {
      case ArticlePasteResult.reformatted:
        showConsoleToast(
          context,
          message: l10n.pastedAsFormatted,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: _editor.draft.body.undo,
          ),
        );
      case ArticlePasteResult.imageAdded:
        final assetId = outcome.assetId;
        showConsoleToast(
          context,
          message: l10n.pastedImageAdded,
          action: assetId == null
              ? null
              : SnackBarAction(
                  label: l10n.describeImage,
                  onPressed: () => showMediaAsset(context, id: assetId),
                ),
        );
      case ArticlePasteResult.imageTooLarge:
        showConsoleToast(
          context,
          message: l10n.imageTooLarge(
            MediaFormat.bytes(l10n, kMaxPastedImageBytes, context.languageCode),
          ),
          kind: ToastKind.error,
        );
      case ArticlePasteResult.imageRejected:
        showConsoleToast(
          context,
          message: l10n.imageNotSupported,
          kind: ToastKind.error,
        );
      case ArticlePasteResult.uploadFailed:
        showConsoleToast(
          context,
          message: l10n.imageUploadFailed,
          kind: ToastKind.error,
        );
    }
  }

  /// Turns unattended saving on or off.
  ///
  /// Switching it back on adopts whatever is already unsaved rather than
  /// waiting for one more keystroke to notice — otherwise a journalist who
  /// re-enables it and walks away has been told their work is being saved
  /// while nothing is scheduled to save it.
  void _setAutosave({required bool enabled}) {
    if (_autosaveEnabled == enabled) return;
    setState(() => _autosaveEnabled = enabled);
    if (enabled && _editor.isDirty) unawaited(_editor.saveAll());
  }

  Future<void> _close() async {
    await _editor.saveAll();
    if (!mounted) return;
    ref.read(articleActionsProvider.notifier).refreshList();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.openArticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPublish =
        ref.watch(currentUserProvider)?.can(Capability.publishArticles) ??
        false;

    return WindowSizeScope(
      builder: (context, size) {
        final asColumns = size.isAtLeastExpanded;

        return Column(
          children: [
            EditorTopBar(
              editor: _editor,
              canPublish: canPublish,
              autosaveEnabled: _autosaveEnabled,
              onAutosaveChanged: (value) => _setAutosave(enabled: value),
              onClose: _close,
              onTransition: _transition,
              onSuggestHeadlines:
                  _canSuggestHeadlines && !_headlineWriter.isRunning
                  ? _suggestHeadlines
                  : null,
            ),
            EditorLocaleTabs(editor: _editor),
            Expanded(child: asColumns ? _wide() : _narrow()),
          ],
        );
      },
    );
  }

  Widget _wide() => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.sectionBreak,
      Spacing.gutter + 4,
      Spacing.sectionBreak,
      Spacing.gutter + 4,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _composer()),
        const SizedBox(width: Spacing.gutter),
        SizedBox(
          width: _metadataWidth,
          child: SingleChildScrollView(child: _metadata()),
        ),
      ],
    ),
  );

  Widget _narrow() => ListView(
    padding: const EdgeInsets.all(Spacing.gutter),
    children: [
      SizedBox(height: 800, child: _composer()),
      const SizedBox(height: Spacing.gutter),
      _metadata(),
    ],
  );

  /// Headline, excerpt and body — one language, or two side by side.
  /// A composer's identity: its language, plus how many times that language has
  /// been rewritten from outside its own text fields.
  ///
  /// The revision half is what makes an accepted suggestion visible. The
  /// headline and excerpt controllers are seeded once and never re-read the
  /// draft — see `ArticleEditor.revisionOf` — so changing the draft has to
  /// change the key, or the editor saves text the person never saw.
  ValueKey<String> _composerKey(String locale) =>
      ValueKey('$locale#${_editor.revisionOf(locale)}');

  Widget _composer() {
    final counterpart = _editor.counterpartLocale;
    if (!_editor.sideBySide || counterpart == null) {
      return _LocaleComposer(
        key: _composerKey(_editor.locale),
        editor: _editor,
        locale: _editor.locale,
        onSuggestExcerpt: _canSuggestExcerpt ? _suggestExcerpt : null,
        isSuggestingExcerpt: _excerptWriter.isRunning,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LocaleComposer(
            key: _composerKey(_editor.article.sourceLocale),
            editor: _editor,
            locale: _editor.article.sourceLocale,
            onSuggestExcerpt: _canSuggestExcerpt ? _suggestExcerpt : null,
            isSuggestingExcerpt: _excerptWriter.isRunning,
          ),
        ),
        const SizedBox(width: Spacing.listRhythm),
        Expanded(
          child: _LocaleComposer(
            key: _composerKey(counterpart),
            editor: _editor,
            locale: counterpart,
            onSuggestExcerpt: _canSuggestExcerpt ? _suggestExcerpt : null,
            isSuggestingExcerpt: _excerptWriter.isRunning,
          ),
        ),
      ],
    );
  }

  Widget _metadata() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Card(
        child: TranslationPanel(
          editor: _editor,
          onReconfirm: _reconfirm,
          onOpenSideBySide: _openSideBySide,
          // Null unless this deployment actually has assistance configured, so
          // the button is absent rather than present-and-refusing.
          onDraftTranslation: _canDraft ? _draftTranslation : null,
          isDrafting: _translator.isRunning,
        ),
      ),
      const SizedBox(height: Spacing.listRhythm),
      _Card(
        child: HeroImagePanel(
          editor: _editor,
          onChanged: (assetId) => _editor.setHeroImage(assetId),
        ),
      ),
      const SizedBox(height: Spacing.listRhythm),
      _Card(
        child: PublishingPanel(
          editor: _editor,
          onCategoryChanged: _editor.setCategory,
          onBreakingChanged: _editor.setBreaking,
          onSchedule: (at) =>
              _transition(ArticleStatus.scheduled, scheduledFor: at),
        ),
      ),
    ],
  );

  static const _metadataWidth = 392.0;

  void _openSideBySide(String locale) {
    _editor
      ..selectLocale(locale)
      ..toggleSideBySide();
  }

  Future<void> _reconfirm(String locale) async {
    await _editor.reconfirm(locale);
    if (!mounted) return;
    if (_editor.saveState != ArticleSaveState.failed) {
      showConsoleToast(
        context,
        message: context.l10n.translationCurrent,
        kind: ToastKind.success,
      );
    }
  }

  Future<void> _transition(
    ArticleStatus status, {
    DateTime? scheduledFor,
  }) async {
    await _editor.transition(status, scheduledFor: scheduledFor);
    if (!mounted) return;
    ref.read(articleActionsProvider.notifier).refreshList();
    if (_editor.saveState != ArticleSaveState.failed) {
      showConsoleToast(
        context,
        message: context.l10n.statusChangedTo(
          StatusBadge.articleLabel(context.l10n, status),
        ),
        kind: ToastKind.success,
      );
    }
  }
}

/// One language's headline, excerpt and body.
class _LocaleComposer extends StatefulWidget {
  const _LocaleComposer({
    super.key,
    required this.editor,
    required this.locale,
    this.onSuggestExcerpt,
    this.isSuggestingExcerpt = false,
  });

  final ArticleEditor editor;
  final String locale;

  /// Drafts a standfirst from this language's body. Null when the deployment
  /// has no assistance, and the affordance then does not exist.
  final ValueChanged<String>? onSuggestExcerpt;
  final bool isSuggestingExcerpt;

  @override
  State<_LocaleComposer> createState() => _LocaleComposerState();
}

class _LocaleComposerState extends State<_LocaleComposer> {
  late final _headline = TextEditingController(text: _draft.title);
  late final _excerpt = TextEditingController(text: _draft.excerpt);

  /// The canvas's guidance figure, and the counter's ceiling.
  static const _headlineLimit = 120;

  ArticleDraft get _draft => widget.editor.draftFor(widget.locale);

  bool get _isActive => widget.editor.locale == widget.locale;

  @override
  void dispose() {
    _headline.dispose();
    _excerpt.dispose();
    super.dispose();
  }

  void _focusThisLocale() {
    if (!_isActive) widget.editor.selectLocale(widget.locale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = widget.locale.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(l10n.editorHeadline(code)),
        _Field(
          controller: _headline,
          onChanged: (value) {
            _focusThisLocale();
            _draft.title = value;
            widget.editor.setTitle(value);
          },
          onTap: _focusThisLocale,
          minLines: 1,
          maxLines: 3,
          emphasised: true,
          style: TextStyle(
            fontFamily: FontFamily.serif,
            fontSize: 20,
            height: 27 / 20,
            fontWeight: FontWeight.w600,
            color: context.scheme.primary,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Flexible(
              child: Text(
                l10n.headlineHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Spacing.chip),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _headline,
              builder: (context, value, _) => Text(
                l10n.charCount(value.text.length, _headlineLimit),
                style: context.text.meta.copyWith(
                  color: value.text.length > _headlineLimit
                      ? context.scheme.error
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.listRhythm + 2),
        Row(
          children: [
            Expanded(child: _FieldLabel(l10n.editorExcerpt(code))),
            if (widget.onSuggestExcerpt case final onSuggest?)
              TextButton.icon(
                onPressed: widget.isSuggestingExcerpt
                    ? null
                    : () {
                        _focusThisLocale();
                        onSuggest(widget.locale);
                      },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: widget.isSuggestingExcerpt
                    ? const SizedBox.square(
                        dimension: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined, size: 14),
                label: Text(
                  widget.isSuggestingExcerpt
                      ? l10n.aiWorking
                      : l10n.aiSuggestExcerpt,
                  style: context.text.meta,
                ),
              ),
          ],
        ),
        _Field(
          controller: _excerpt,
          onChanged: (value) {
            _focusThisLocale();
            _draft.excerpt = value;
            widget.editor.setExcerpt(value);
          },
          onTap: _focusThisLocale,
          minLines: 3,
          maxLines: 4,
          style: context.text.body.copyWith(color: context.scheme.onSurface),
        ),
        const SizedBox(height: Spacing.listRhythm + 2),
        Expanded(
          child: Focus(
            onFocusChange: (has) {
              if (has) _focusThisLocale();
            },
            child: ArticleBodyEditor(
              controller: _draft.body,
              locale: widget.locale,
              paste: _draft.paste,
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: context.text.overline.copyWith(
        color: context.scheme.onSurfaceVariant,
      ),
    ),
  );
}

/// A bordered field in the editor's own chrome.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.onChanged,
    required this.onTap,
    required this.minLines,
    required this.maxLines,
    required this.style,
    this.emphasised = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final int minLines;
  final int maxLines;
  final TextStyle style;

  /// The headline gets the 2px focus ring the canvas draws around it.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: Radii.cardBorder,
      borderSide: BorderSide(color: color, width: width),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      minLines: minLines,
      maxLines: maxLines,
      style: style,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: border(context.colors.outline, emphasised ? 1.5 : 1),
        focusedBorder: border(context.colors.link, 2),
      ),
    );
  }
}

/// The white card the metadata column is built from.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Spacing.listRhythm),
    decoration: BoxDecoration(
      color: context.scheme.surface,
      borderRadius: Radii.cardBorder,
      border: Border.all(color: context.colors.outline),
    ),
    child: child,
  );
}
