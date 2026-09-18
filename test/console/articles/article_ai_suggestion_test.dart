import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/ai_api/dto/ai_suggestion_dto.dart';
import 'package:puntland/console/core/ai_api/fixture_ai_api.dart';
import 'package:puntland/console/features/articles/presentation/controllers/article_editor_controller.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_html.dart';

/// Accepting a machine suggestion has to be indistinguishable, to the rest of
/// the system, from an editor typing the same words.
///
/// That is the whole safety argument for this feature. The freshness model —
/// "English is behind Somali" — is derived entirely from comparing one
/// translation's `updatedAt` against another's, so an assistance path that
/// wrote two languages, or moved the source's clock, or saved without anyone
/// having read it, would not be a new feature. It would be the quiet removal of
/// the one signal the newsroom uses to know its English is trustworthy.
void main() {
  late FixtureAdminApi api;

  setUp(() => api = FixtureAdminApi(latency: Duration.zero));

  Future<ArticleEditor> open(String id) async {
    final editor = ArticleEditor(
      article: await api.fetchArticle(id),
      api: api,
      autosaveDelay: const Duration(days: 1),
    );
    addTearDown(editor.dispose);
    return editor;
  }

  group('applySuggestion · writes one language and nothing else', () {
    test('leaves every other language’s draft untouched', () async {
      final editor = await open('a-rains');
      final somaliTitleBefore = editor.draftFor('so').title;

      editor.applySuggestion(
        'en',
        title: 'Heavy rains cut the Garoowe road',
        excerpt: 'Two districts are unreachable.',
      );

      expect(
        editor.draftFor('en').title,
        'Heavy rains cut the Garoowe road',
        reason: 'the accepted headline lands in the language it was for',
      );
      expect(
        editor.draftFor('so').title,
        somaliTitleBefore,
        reason: 'accepting an English suggestion must not edit the Somali',
      );
    });

    test('does not move any clock on its own', () async {
      final editor = await open('a-rains');
      final before = editor.article.translations;

      editor.applySuggestion('en', title: 'Something new');

      expect(
        editor.article.translations['so']!.updatedAt,
        before['so']!.updatedAt,
      );
      expect(
        editor.article.translations['en']!.updatedAt,
        before['en']!.updatedAt,
        reason: 'applying is a draft edit — nothing is written until the caller saves',
      );
    });

    /// The sequence the review panel performs. One save, one language, and the
    /// source untouched — which is exactly what a typed edit produces.
    test('saving after an apply moves only the target’s clock', () async {
      final editor = await open('a-rains');
      final somaliBefore = editor.article.translations['so']!.updatedAt;

      editor.applySuggestion('en', title: 'Heavy rains cut the road');
      await editor.saveDraft(locale: 'en');

      expect(
        editor.article.translations['en']!.title,
        'Heavy rains cut the road',
      );
      expect(
        editor.article.translations['so']!.updatedAt,
        somaliBefore,
        reason:
            'the source language is never rewritten by an accepted '
            'translation — if it were, "English is behind" would stop meaning '
            'anything',
      );
      expect(editor.saveState, ArticleSaveState.saved);
    });

    /// Per-field accept is the point of the review panel: an editor often wants
    /// the suggested headline and their own standfirst.
    test('writes only the fields the reviewer accepted', () async {
      final editor = await open('a-rains');
      final excerptBefore = editor.draftFor('en').excerpt;

      editor.applySuggestion('en', title: 'Only the headline');

      expect(editor.draftFor('en').title, 'Only the headline');
      expect(
        editor.draftFor('en').excerpt,
        excerptBefore,
        reason: 'a field the reviewer did not tick is not a field to overwrite',
      );
    });

    test('ignores a language the article does not have open', () async {
      final editor = await open('a-rains');
      editor.applySuggestion('fr', title: 'Nope');
      expect(editor.locales, isNot(contains('fr')));
    });
  });

  group('applySuggestion · the body', () {
    test('replaces the document and survives a round trip to HTML', () async {
      final editor = await open('a-rains');
      const html = '<p>First paragraph.</p><h2>A heading</h2><p>Second.</p>';

      editor.applySuggestion('en', bodyHtml: html);

      final draft = editor.draftFor('en');
      expect(draft.bodyHtml, html);
      expect(
        isArticleDocumentEmpty(draft.body.document),
        isFalse,
        reason:
            'the suggestion reached the live editor document, not just a '
            'string beside it',
      );
    });

    /// Undo is the entire answer to a suggestion that turned out wrong, and a
    /// suggestion that undid in fragments would be worse than one that could
    /// not be undone at all.
    test('is a single undo step', () async {
      final editor = await open('a-rains');
      final draft = editor.draftFor('en');
      final before = draft.bodyHtml;

      editor.applySuggestion('en', bodyHtml: '<p>Replaced entirely.</p>');
      expect(draft.bodyHtml, '<p>Replaced entirely.</p>');

      draft.body.undo();
      draft.invalidateBodyHtml();

      expect(
        draft.bodyHtml,
        before,
        reason: 'one undo returns the whole body, not the last few words of it',
      );
    });

    test('recomputes the memoised HTML rather than serving the old body', () async {
      final editor = await open('a-rains');
      final draft = editor.draftFor('en');
      // Prime the memo, which is what the dirty check reads on every keystroke.
      final primed = draft.bodyHtml;

      editor.applySuggestion('en', bodyHtml: '<p>New body.</p>');

      expect(draft.bodyHtml, isNot(primed));
      expect(draft.bodyHtml, '<p>New body.</p>');
    });
  });

  group('applySuggestion · making the change visible', () {
    /// The headline and excerpt fields seed their controllers once and never
    /// re-read the draft, so without a revision bump the editor would save text
    /// the person never saw on screen. This is the mechanism that prevents it.
    test('bumps only the target language’s revision', () async {
      final editor = await open('a-rains');
      expect(editor.revisionOf('en'), 0);
      expect(editor.revisionOf('so'), 0);

      editor.applySuggestion('en', title: 'Changed');

      expect(editor.revisionOf('en'), 1);
      expect(
        editor.revisionOf('so'),
        0,
        reason:
            'rebuilding the Somali composer would throw away that tab’s '
            'cursor for an edit that never touched it',
      );
    });

    test(
      'notifies listeners so the panel can close and the toast can show',
      () async {
        final editor = await open('a-rains');
        var notifications = 0;
        editor.addListener(() => notifications++);

        editor.applySuggestion('en', title: 'Changed');

        expect(notifications, greaterThan(0));
      },
    );
  });

  group('FixtureAiApi · the console works with no backend', () {
    test('reports every feature as available', () async {
      final ai = FixtureAiApi(admin: api, latency: Duration.zero);
      final capabilities = await ai.fetchCapabilities();

      expect(capabilities.enabled, isTrue);
      expect(capabilities.has(AiFeature.translateArticle), isTrue);
      expect(capabilities.has(AiFeature.suggestAltText), isTrue);
    });

    test(
      'can be switched off, so the hidden-affordance path is testable',
      () async {
        final ai = FixtureAiApi(
          admin: api,
          latency: Duration.zero,
          enabled: false,
        );
        final capabilities = await ai.fetchCapabilities();

        expect(capabilities.enabled, isFalse);
        expect(capabilities.has(AiFeature.translateArticle), isFalse);
      },
    );

    test('reports the source clock it read', () async {
      final ai = FixtureAiApi(admin: api, latency: Duration.zero);
      final article = await api.fetchArticle('a-rains');
      final suggestion = await ai.translateArticle(
        articleId: 'a-rains',
        from: 'so',
        to: 'en',
      );

      expect(suggestion.sourceUpdatedAt, article.translations['so']!.updatedAt);
      expect(
        suggestion.isStaleAgainst(article.translations['so']!.updatedAt),
        isFalse,
      );
      expect(
        suggestion.isStaleAgainst(
          article.translations['so']!.updatedAt.add(const Duration(minutes: 1)),
        ),
        isTrue,
        reason:
            'a source edited after the suggestion was drafted makes it '
            'stale, and the review panel has to say so',
      );
    });

    /// Structure is the thing the apply path has to get right, so the fixture
    /// preserves it rather than returning a flat string that would never
    /// exercise the failure.
    test('keeps the body’s tags where they were', () async {
      final ai = FixtureAiApi(admin: api, latency: Duration.zero);
      final article = await api.fetchArticle('a-rains');
      final sourceHtml = article.translations['so']!.bodyHtml;

      final suggestion = await ai.translateArticle(
        articleId: 'a-rains',
        from: 'so',
        to: 'en',
      );

      if (sourceHtml == null || sourceHtml.isEmpty) return;
      expect(suggestion.bodyHtml, isNotNull);
      expect(
        RegExp('<p[ >]').allMatches(suggestion.bodyHtml!).length,
        RegExp('<p[ >]').allMatches(sourceHtml).length,
        reason: 'the same number of paragraphs came back',
      );
    });

    test('narrows to the requested fields', () async {
      final ai = FixtureAiApi(admin: api, latency: Duration.zero);
      final suggestion = await ai.translateArticle(
        articleId: 'a-rains',
        from: 'so',
        to: 'en',
        fields: const ['title'],
      );

      expect(suggestion.title, isNotEmpty);
      expect(suggestion.bodyHtml, isNull);
      expect(suggestion.excerpt, isNull);
    });
  });
}
