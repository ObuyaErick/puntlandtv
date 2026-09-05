import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show TextSelection;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/admin_api/puntland_admin_api.dart';
import '../../../../core/providers/console_providers.dart';
import '../rich_text/article_html.dart';

part 'article_editor_controller.g.dart';

/// The article the editor is working on.
///
/// A provider of its own rather than a lookup in the list: the editor is a URL
/// an editor can be sent, so it has to be able to load one story without the
/// list ever having been fetched.
@riverpod
Future<AdminArticleDto> articleById(Ref ref, String id) =>
    ref.watch(adminApiProvider).fetchArticle(id);

/// Where a locale's unsaved edits live while the editor is open.
///
/// Held per locale rather than per article, because that is the unit the
/// backend writes: switching to the English tab must not carry the Somali
/// tab's dirty state with it, and saving English must not restate Somali.
class ArticleDraft {
  ArticleDraft({
    required this.locale,
    required this.title,
    required this.excerpt,
    required this.caption,
    required this.body,
  });

  /// Opens [translation] for editing, parsing its stored body once.
  factory ArticleDraft.of(String locale, ArticleTranslationDto? translation) =>
      ArticleDraft(
        locale: locale,
        title: translation?.title ?? '',
        excerpt: translation?.excerpt ?? '',
        caption: translation?.caption ?? '',
        body: QuillController(
          document: articleHtmlToDocument(translation?.bodyHtml),
          selection: const TextSelection.collapsed(offset: 0),
        ),
      );

  final String locale;
  String title;
  String excerpt;
  String caption;

  /// The Quill controller for this language's body.
  ///
  /// One per locale and kept alive for as long as the editor is: rebuilding it
  /// on every tab switch would discard that language's undo history, and an
  /// editor who tabs away to check a translation expects ctrl-Z to still know
  /// what they did before they left.
  final QuillController body;

  bool get isEmpty =>
      title.trim().isEmpty &&
      excerpt.trim().isEmpty &&
      isArticleDocumentEmpty(body.document);

  int get wordCount => articleDocumentWordCount(body.document);

  int get readingMinutes => articleReadingMinutes(wordCount);

  String get bodyHtml => documentToArticleHtml(body.document);

  void dispose() => body.dispose();

  /// True when this differs from the [saved] version of the same language.
  bool isDirtyAgainst(ArticleTranslationDto? saved) =>
      title != (saved?.title ?? '') ||
      excerpt != (saved?.excerpt ?? '') ||
      caption != (saved?.caption ?? '') ||
      bodyHtml != (saved?.bodyHtml ?? '');
}

/// What the editor's chrome needs to know about work in flight.
enum ArticleSaveState { idle, saving, saved, failed }

/// Holds one article's edits and writes them back a locale at a time.
///
/// **Autosave is per translation, and debounced.** The journalist typing in the
/// Somali tab produces one write against one row; nothing else about the
/// article is sent, so a sub-editor changing the category in another tab is
/// not overwritten by a keystroke. That is the decoupling the whole freshness
/// model rests on — see `saveArticleTranslation`.
class ArticleEditor extends ChangeNotifier {
  ArticleEditor({
    required AdminArticleDto article,
    required this.api,
    this.autosaveDelay = const Duration(seconds: 2),
  }) : _article = article {
    _locale = article.sourceLocale;
    for (final locale in _localesOf(article)) {
      final draft = ArticleDraft.of(locale, article.translations[locale]);
      draft.body.addListener(_onEdited);
      _drafts[locale] = draft;
    }
  }

  final PuntlandAdminApi api;

  /// How long typing has to stop before a save goes out.
  ///
  /// Long enough that a sentence is one write rather than forty; short enough
  /// that "Saved 21:12" is true by the time an editor looks up at it.
  final Duration autosaveDelay;

  final Map<String, ArticleDraft> _drafts = {};
  AdminArticleDto _article;
  late String _locale;
  Timer? _autosave;
  ArticleSaveState _saveState = ArticleSaveState.idle;
  Object? _saveError;
  bool _sideBySide = false;

  AdminArticleDto get article => _article;
  String get locale => _locale;
  ArticleDraft get draft => _drafts[_locale]!;
  ArticleSaveState get saveState => _saveState;
  Object? get saveError => _saveError;
  bool get sideBySide => _sideBySide;

  /// Locales with a tab, source first.
  List<String> get locales => _drafts.keys.toList(growable: false);

  ArticleDraft draftFor(String locale) =>
      _drafts[locale] ??= _added(locale);

  /// The other language, for side-by-side. Null when there is only one.
  String? get counterpartLocale =>
      locales.length < 2 ? null : locales.firstWhere((l) => l != _locale);

  bool get isDirty => _drafts.entries.any(
    (e) => e.value.isDirtyAgainst(_article.translations[e.key]),
  );

  /// Locales whose text is older than the source's, taking unsaved edits into
  /// account — a translation the editor has just retyped is not stale, even
  /// though the row on the server still says it is.
  List<String> get staleLocales => _article.staleLocales
      .where((l) => !_drafts[l]!.isDirtyAgainst(_article.translations[l]))
      .toList(growable: false);

  void selectLocale(String locale) {
    if (_locale == locale) return;
    // The language being left is saved on the way out. Tabbing away is the
    // most common way to stop typing, and it would otherwise be the one edit
    // the debounce never gets to flush.
    unawaited(saveDraft());
    _locale = locale;
    notifyListeners();
  }

  void toggleSideBySide() {
    _sideBySide = !_sideBySide;
    notifyListeners();
  }

  void setTitle(String value) {
    draft.title = value;
    _onEdited();
  }

  void setExcerpt(String value) {
    draft.excerpt = value;
    _onEdited();
  }

  void setCaption(String value) {
    draft.caption = value;
    _onEdited();
  }

  /// Adds a language to the article and switches to it.
  void addLocale(String locale) {
    if (_drafts.containsKey(locale)) return;
    _drafts[locale] = _added(locale);
    _locale = locale;
    notifyListeners();
  }

  ArticleDraft _added(String locale) =>
      ArticleDraft.of(locale, null)..body.addListener(_onEdited);

  void _onEdited() {
    _autosave?.cancel();
    _autosave = Timer(autosaveDelay, () => unawaited(saveDraft()));
    notifyListeners();
  }

  /// Writes the active language, if it has changed.
  Future<void> saveDraft({String? locale}) async {
    _autosave?.cancel();
    final target = locale ?? _locale;
    final draft = _drafts[target];
    if (draft == null) return;
    if (!draft.isDirtyAgainst(_article.translations[target])) return;

    await _write(
      () => api.saveArticleTranslation(
        id: _article.id,
        locale: target,
        title: draft.title,
        // Empty strings are stored as absent rather than as `''`: an excerpt
        // an editor has cleared is one the app should fall back from, not one
        // it should render as a blank line.
        excerpt: _orNull(draft.excerpt),
        bodyHtml: _orNull(draft.bodyHtml),
        caption: _orNull(draft.caption),
      ),
    );
  }

  /// Clears the stale flag on [locale] without touching its text.
  Future<void> reconfirm(String locale) => _write(
    () => api.reconfirmArticleTranslation(id: _article.id, locale: locale),
  );

  Future<void> setCategory(String slug) =>
      _write(() => api.updateArticle(id: _article.id, categorySlug: slug));

  Future<void> setBreaking(bool value) =>
      _write(() => api.updateArticle(id: _article.id, isBreaking: value));

  Future<void> setHeroImage(String? assetId) => _write(
    () => api.updateArticle(
      id: _article.id,
      imageId: assetId,
      clearImage: assetId == null,
    ),
  );

  /// Moves the article's state, flushing any unsaved prose first.
  ///
  /// The order matters: publishing an article whose last sentence is still
  /// sitting in the debounce timer would put the previous draft in front of
  /// readers, and the sentence would arrive a moment later as an edit to a
  /// live story.
  Future<void> transition(ArticleStatus status, {DateTime? scheduledFor}) async {
    await saveDraft();
    await _write(
      () => api.setArticleStatus(
        id: _article.id,
        status: status,
        scheduledFor: scheduledFor,
      ),
    );
  }

  Future<void> _write(Future<AdminArticleDto> Function() request) async {
    _saveState = ArticleSaveState.saving;
    _saveError = null;
    notifyListeners();
    try {
      _article = await request();
      _saveState = ArticleSaveState.saved;
      _saveError = null;
    } catch (error) {
      // The draft is kept exactly as it is. A failed save that discarded the
      // editor's text to match the server would be the worst possible reading
      // of "the write did not happen".
      _saveState = ArticleSaveState.failed;
      _saveError = error;
    }
    notifyListeners();
  }

  static String? _orNull(String value) =>
      value.trim().isEmpty ? null : value;

  static List<String> _localesOf(AdminArticleDto article) {
    final locales = article.locales;
    return locales.isEmpty ? [article.sourceLocale] : locales;
  }

  @override
  void dispose() {
    _autosave?.cancel();
    for (final draft in _drafts.values) {
      draft.body.removeListener(_onEdited);
      draft.dispose();
    }
    super.dispose();
  }
}
