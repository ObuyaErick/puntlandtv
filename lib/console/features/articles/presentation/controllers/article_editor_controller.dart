import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show TextSelection;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/admin_api/puntland_admin_api.dart';
import '../../../../core/providers/console_providers.dart';
import '../rich_text/article_html.dart';
import '../rich_text/article_paste_handler.dart';

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
    required this.paste,
  });

  /// Opens [translation] for editing, parsing its stored body once.
  ///
  /// [api] and [onPaste] are threaded down for the paste handler rather than
  /// reached for later, because `QuillController.config` is final: a
  /// controller that accepts pasted images has to be built already knowing how
  /// to upload one.
  factory ArticleDraft.of(
    String locale,
    ArticleTranslationDto? translation, {
    required PuntlandAdminApi api,
    required void Function(ArticlePasteOutcome outcome) onPaste,
  }) {
    final paste = ArticlePasteHandler(api: api, onOutcome: onPaste);
    final body = QuillController(
      document: articleHtmlToDocument(translation?.bodyHtml),
      selection: const TextSelection.collapsed(offset: 0),
      config: QuillControllerConfig(
        // Experimental in flutter_quill, and pinned against in `pubspec.yaml`.
        // See `article_paste_handler.dart` for what it buys and what it costs.
        // ignore: experimental_member_use
        clipboardConfig: paste.clipboardConfig,
      ),
    );
    paste.attach(body);

    return ArticleDraft(
      locale: locale,
      title: translation?.title ?? '',
      excerpt: translation?.excerpt ?? '',
      caption: translation?.caption ?? '',
      body: body,
      paste: paste,
    );
  }

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

  /// What happens when something is pasted into [body].
  final ArticlePasteHandler paste;

  String? _bodyHtml;

  bool get isEmpty =>
      title.trim().isEmpty &&
      excerpt.trim().isEmpty &&
      isArticleDocumentEmpty(body.document);

  int get wordCount => articleDocumentWordCount(body.document);

  int get readingMinutes => articleReadingMinutes(wordCount);

  /// The stored form of this language's body.
  ///
  /// Memoised because it is on the typing path and it is not cheap: it runs
  /// the whole delta-to-HTML conversion, `isDirtyAgainst` reads it, `isDirty`
  /// reads that once per language, and the editor page asks `isDirty` on every
  /// keystroke. With a pasted image in the document that is a base64 string
  /// being rebuilt and compared between two letters of a word.
  String get bodyHtml => _bodyHtml ??= documentToArticleHtml(body.document);

  /// Drops the memo. Called from the listener the editor already has on
  /// [body], so a conversion can never outlive the document it described.
  void invalidateBodyHtml() => _bodyHtml = null;

  void dispose() {
    paste.detach();
    body.dispose();
  }

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
    this.autosaveEnabled = _autosaveAlways,
  }) : _article = article {
    _locale = article.sourceLocale;
    for (final locale in _localesOf(article)) {
      _drafts[locale] = _open(locale, article.translations[locale]);
    }
  }

  final PuntlandAdminApi api;

  /// How long typing has to stop before a save goes out.
  ///
  /// Long enough that a sentence is one write rather than forty; short enough
  /// that "Saved 21:12" is true by the time an editor looks up at it.
  final Duration autosaveDelay;

  /// Whether an **unattended** save may go out, asked each time one is about
  /// to be.
  ///
  /// A predicate rather than a flag because the answer is not this object's to
  /// hold: whether the editor writes on its own is a property of the session
  /// at a desk, not of the article, and it outlives none of the drafts here.
  /// The editor screen owns it — see `_EditorState` — and this asks.
  ///
  /// It gates only the writes nobody asked for: the debounce timer, and the
  /// flush when a language tab is left. Everything explicit — the Save draft
  /// button, publishing, closing the editor — goes straight to [saveDraft] and
  /// is never gated, because refusing those would lose an edit rather than
  /// defer one.
  ///
  /// Defaults to yes, so an [ArticleEditor] built without one behaves exactly
  /// as it always has.
  final bool Function() autosaveEnabled;

  final Map<String, ArticleDraft> _drafts = {};
  AdminArticleDto _article;
  late String _locale;
  Timer? _autosave;
  ArticleSaveState _saveState = ArticleSaveState.idle;
  Object? _saveError;
  bool _sideBySide = false;
  ArticlePasteOutcome? _lastPasteOutcome;
  var _pasteCount = 0;

  AdminArticleDto get article => _article;
  String get locale => _locale;
  ArticleDraft get draft => _drafts[_locale]!;
  ArticleSaveState get saveState => _saveState;
  Object? get saveError => _saveError;
  bool get sideBySide => _sideBySide;

  /// The most recent thing a paste has to report, or null if none has.
  ArticlePasteOutcome? get lastPasteOutcome => _lastPasteOutcome;

  /// How many pastes have reported something. Increments even when
  /// [lastPasteOutcome] repeats, so a listener can tell a second identical
  /// outcome from a rebuild.
  int get pasteCount => _pasteCount;

  /// True while a pasted image is still on its way to the media library.
  bool get isUploadingPastedImage =>
      _drafts.values.any((draft) => draft.paste.isUploading);

  /// Locales with a tab, source first.
  List<String> get locales => _drafts.keys.toList(growable: false);

  ArticleDraft draftFor(String locale) => _drafts[locale] ??= _added(locale);

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
    // the debounce never gets to flush — which is why this answers to the
    // same switch the debounce does. With autosave off the edit stays in the
    // draft, and [saveAll] is what eventually carries it.
    if (autosaveEnabled()) unawaited(saveDraft());
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

  ArticleDraft _added(String locale) => _open(locale, null);

  ArticleDraft _open(String locale, ArticleTranslationDto? translation) =>
      ArticleDraft.of(locale, translation, api: api, onPaste: _onPasted)
        ..body.addListener(_onEdited);

  void _onEdited() {
    for (final draft in _drafts.values) {
      draft.invalidateBodyHtml();
    }
    _scheduleAutosave();
    notifyListeners();
  }

  /// The one place an unattended save is armed.
  ///
  /// Everything automatic comes through here, so "autosave is off" is a
  /// property of one branch rather than a rule every call site has to
  /// remember — and adding a new trigger tomorrow inherits the switch instead
  /// of quietly escaping it.
  ///
  /// [autosaveEnabled] is asked twice on purpose: once here, so a disabled
  /// editor arms no timer at all, and again when the timer fires, because two
  /// seconds is long enough for someone to turn it off after the keystroke
  /// that armed it.
  void _scheduleAutosave() {
    _autosave?.cancel();
    if (!autosaveEnabled()) {
      _autosave = null;
      return;
    }
    _autosave = Timer(autosaveDelay, () {
      if (!autosaveEnabled()) return;
      unawaited(saveDraft());
    });
  }

  void _onPasted(ArticlePasteOutcome outcome) {
    _lastPasteOutcome = outcome;
    // Counted rather than compared: pasting two screenshots in a row produces
    // two identical outcomes, and the second one still has something to say.
    _pasteCount++;
    notifyListeners();
  }

  /// Writes the active language, if it has changed.
  Future<void> saveDraft({String? locale}) async {
    _autosave?.cancel();

    // A pasted image is a placeholder embed until its upload returns, and the
    // HTML converter renders an embed it does not know as nothing at all. A
    // save landing in that window writes a body with the picture silently
    // missing — and then the upload finishes and only an edit will send it.
    // The save is retried instead, once the document is telling the truth.
    //
    // Deliberately not routed through [_scheduleAutosave]: this is a save that
    // has already been asked for — possibly by the Save draft button — being
    // deferred, not a new unattended one being invented. Dropping it because
    // autosave is off would lose the write rather than delay it.
    if (isUploadingPastedImage) {
      _autosave = Timer(
        autosaveDelay,
        () => unawaited(saveDraft(locale: locale)),
      );
      return;
    }

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

  /// Writes **every** language that has unsaved edits.
  ///
  /// [saveDraft] writes one translation because that is the unit the backend
  /// takes, and until now that was enough: leaving a language tab flushed it
  /// on the way out, so only the active one could ever be behind. With
  /// autosave off that flush does not happen, and the Somali tab's edits exist
  /// nowhere but memory — so the explicit flushes, closing and publishing,
  /// have to cover all of them or the toggle becomes a way to lose a
  /// translation.
  ///
  /// Never gated: this is only ever reached because someone asked.
  Future<void> saveAll() async {
    for (final locale in _drafts.keys.toList(growable: false)) {
      await saveDraft(locale: locale);
    }
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
  /// live story. Every language, not just the one on screen — a bilingual
  /// article published with the English tab unsaved is the same failure.
  Future<void> transition(
    ArticleStatus status, {
    DateTime? scheduledFor,
  }) async {
    await saveAll();
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

  /// The default for [autosaveEnabled]: an editor nobody has told otherwise
  /// saves on its own, as it always did.
  static bool _autosaveAlways() => true;

  static String? _orNull(String value) => value.trim().isEmpty ? null : value;

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
