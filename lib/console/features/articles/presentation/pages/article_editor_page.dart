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
import '../widgets/hero_image_panel.dart';
import '../widgets/publishing_panel.dart';
import '../widgets/translation_panel.dart';

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

  @override
  void initState() {
    super.initState();
    _editor.addListener(_onEditorChanged);
  }

  @override
  void dispose() {
    _editor
      ..removeListener(_onEditorChanged)
      ..dispose();
    super.dispose();
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
  Widget _composer() {
    final counterpart = _editor.counterpartLocale;
    if (!_editor.sideBySide || counterpart == null) {
      return _LocaleComposer(
        key: ValueKey(_editor.locale),
        editor: _editor,
        locale: _editor.locale,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LocaleComposer(
            key: ValueKey(_editor.article.sourceLocale),
            editor: _editor,
            locale: _editor.article.sourceLocale,
          ),
        ),
        const SizedBox(width: Spacing.listRhythm),
        Expanded(
          child: _LocaleComposer(
            key: ValueKey(counterpart),
            editor: _editor,
            locale: counterpart,
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
  });

  final ArticleEditor editor;
  final String locale;

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
        _FieldLabel(l10n.editorExcerpt(code)),
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
