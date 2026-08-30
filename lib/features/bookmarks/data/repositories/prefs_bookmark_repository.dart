import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../news/domain/entities/article.dart';
import '../../domain/repositories/bookmark_repository.dart';

/// [BookmarkRepository] on `shared_preferences`.
///
/// The MVP plan specifies SQLite (drift) for bookmarks. This implementation is
/// the same contract on a simpler store, which is a deliberate staging choice:
/// bookmark counts in the MVP are tens of items, and every byte of that fits
/// comfortably in preferences. When downloads and offline episodes arrive in
/// Phase 2 — thousands of rows, queries, migrations — swapping in a
/// `DriftBookmarkRepository` touches this one file, because nothing above
/// depends on how the rows are stored.
class PrefsBookmarkRepository implements BookmarkRepository {
  PrefsBookmarkRepository(this._prefs) {
    _slugs = _readSlugs();
  }

  final SharedPreferences _prefs;

  static const _indexKey = 'bookmarks.index';
  static const _entryPrefix = 'bookmarks.entry.';

  late Set<String> _slugs;
  final _controller = StreamController<Set<String>>.broadcast();

  @override
  Set<String> get savedSlugs => Set.unmodifiable(_slugs);

  @override
  Stream<Set<String>> watchSavedSlugs() => _controller.stream;

  Set<String> _readSlugs() =>
      (_prefs.getStringList(_indexKey) ?? const <String>[]).toSet();

  @override
  Future<List<ArticleSummary>> saved() async {
    // The index is ordered newest-first; the entry map is keyed by slug.
    final ordered = _prefs.getStringList(_indexKey) ?? const <String>[];
    final out = <ArticleSummary>[];
    for (final slug in ordered) {
      final raw = _prefs.getString('$_entryPrefix$slug');
      if (raw == null) continue;
      final map = json.decode(raw) as Map<String, dynamic>;
      out.add(_summaryFromJson(map));
    }
    return out;
  }

  @override
  Future<Article?> cached(String slug) async {
    final raw = _prefs.getString('$_entryPrefix$slug');
    if (raw == null) return null;
    final map = json.decode(raw) as Map<String, dynamic>;
    return Article(
      summary: _summaryFromJson(map),
      bodyHtml: map['bodyHtml'] as String? ?? '',
      author: map['author'] as String?,
      imageCaption: map['imageCaption'] as String?,
      relatedSlugs: (map['relatedSlugs'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );
  }

  @override
  Future<void> save(Article article) async {
    final s = article.summary;
    await _prefs.setString(
      '$_entryPrefix${s.slug}',
      json.encode({
        'slug': s.slug,
        'title': s.title,
        'categorySlug': s.categorySlug,
        'categoryName': s.categoryName,
        'publishedAt': s.publishedAt.toIso8601String(),
        'contentLanguage': s.contentLanguage,
        'excerpt': s.excerpt,
        'imageUrl': s.imageUrl,
        'readingMinutes': s.readingMinutes,
        'bodyHtml': article.bodyHtml,
        'author': article.author,
        'imageCaption': article.imageCaption,
        'relatedSlugs': article.relatedSlugs,
        'savedAt': DateTime.now().toIso8601String(),
      }),
    );

    final ordered = [
      s.slug,
      ...(_prefs.getStringList(_indexKey) ?? const <String>[]).where(
        (e) => e != s.slug,
      ),
    ];
    await _prefs.setStringList(_indexKey, ordered);
    _emit(ordered.toSet());
  }

  @override
  Future<void> remove(String slug) async {
    await _prefs.remove('$_entryPrefix$slug');
    final ordered = (_prefs.getStringList(_indexKey) ?? const <String>[])
        .where((e) => e != slug)
        .toList();
    await _prefs.setStringList(_indexKey, ordered);
    _emit(ordered.toSet());
  }

  void _emit(Set<String> slugs) {
    _slugs = slugs;
    if (!_controller.isClosed) _controller.add(Set.unmodifiable(slugs));
  }

  ArticleSummary _summaryFromJson(Map<String, dynamic> map) => ArticleSummary(
    slug: map['slug'] as String,
    title: map['title'] as String,
    categorySlug: map['categorySlug'] as String? ?? '',
    categoryName: map['categoryName'] as String? ?? '',
    publishedAt: DateTime.parse(map['publishedAt'] as String),
    contentLanguage: map['contentLanguage'] as String? ?? 'so',
    excerpt: map['excerpt'] as String?,
    imageUrl: map['imageUrl'] as String?,
    readingMinutes: map['readingMinutes'] as int?,
  );

  void dispose() => _controller.close();
}
