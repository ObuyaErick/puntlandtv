import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/admin_api/dto/admin_article_dto.dart';
import 'package:puntland/core/error/failure.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/admin_api/puntland_admin_api.dart';
import 'package:puntland/console/features/articles/presentation/controllers/article_editor_controller.dart';

/// The decoupled-write model the editor is built on: metadata and prose are
/// separate writes, one translation moves one clock, and nothing else ages.
///
/// These are the rules the freshness flag depends on. If a metadata change or a
/// save of the English text could touch the Somali timestamp, "English is
/// behind" would stop meaning anything.
void main() {
  late FixtureAdminApi api;

  setUp(() => api = FixtureAdminApi(latency: Duration.zero));

  Future<ArticleEditor> open(String id) async {
    final editor = ArticleEditor(
      article: await api.fetchArticle(id),
      api: api,
      // Autosave is exercised explicitly here; a timer would make every test
      // in this file a race.
      autosaveDelay: const Duration(days: 1),
    );
    addTearDown(editor.dispose);
    return editor;
  }

  group('one translation, one clock', () {
    test('saving a language moves only its own timestamp', () async {
      final editor = await open('a-rains');
      final before = editor.article.translations;
      final somaliBefore = before['so']!.updatedAt;
      final englishBefore = before['en']!.updatedAt;

      editor
        ..selectLocale('en')
        ..setTitle('Heavy rains, revised');
      await editor.saveDraft();

      final after = editor.article.translations;
      expect(
        after['en']!.updatedAt.isAfter(englishBefore),
        isTrue,
        reason: 'the edited language must be stamped',
      );
      expect(
        after['so']!.updatedAt,
        somaliBefore,
        reason: 'the language nobody touched must not move',
      );
      expect(after['so']!.title, before['so']!.title);
    });

    test('saving a language leaves the other language\'s text alone', () async {
      final editor = await open('a-rains');
      final somaliBody = editor.article.translations['so']!.bodyHtml;

      editor
        ..selectLocale('en')
        ..setTitle('Revised');
      await editor.saveDraft();

      expect(editor.article.translations['so']!.bodyHtml, somaliBody);
    });

    test('an unchanged language is not written at all', () async {
      final editor = await open('a-rains');
      final stamp = editor.article.translations['so']!.updatedAt;

      await editor.saveDraft();

      expect(
        editor.article.translations['so']!.updatedAt,
        stamp,
        reason: 'a save with nothing to save must not stamp the row',
      );
    });
  });

  group('metadata does not age the story', () {
    test(
      'flipping breaking news leaves every translation where it was',
      () async {
        final editor = await open('a-rains');
        final stamps = {
          for (final e in editor.article.translations.entries)
            e.key: e.value.updatedAt,
        };

        await editor.setBreaking(true);

        expect(editor.article.isBreaking, isTrue);
        for (final entry in stamps.entries) {
          expect(
            editor.article.translations[entry.key]!.updatedAt,
            entry.value,
            reason: 'toggling a flag must not mark ${entry.key} stale',
          );
        }
      },
    );

    test('changing the category does not mark a translation behind', () async {
      final editor = await open('a-rains');
      final staleBefore = editor.article.staleLocales;

      await editor.setCategory('economy');

      expect(editor.article.categorySlug, 'economy');
      expect(editor.article.staleLocales, staleBefore);
    });
  });

  group('re-confirming a translation', () {
    test('clears the stale flag without changing a word', () async {
      final editor = await open('a-rains');
      final english = editor.article.translations['en']!;
      expect(editor.article.staleLocales, contains('en'));

      await editor.reconfirm('en');

      expect(editor.article.staleLocales, isNot(contains('en')));
      expect(editor.article.translations['en']!.title, english.title);
      expect(editor.article.translations['en']!.bodyHtml, english.bodyHtml);
    });
  });

  group('staleness accounts for unsaved work', () {
    test('a translation being retyped is not reported as behind', () async {
      final editor = await open('a-rains');
      expect(editor.article.staleLocales, contains('en'));

      editor
        ..selectLocale('en')
        ..setTitle('Being rewritten right now');

      expect(
        editor.staleLocales,
        isNot(contains('en')),
        reason: 'the flag describes the saved row; the editor knows better',
      );
    });
  });

  group('publishing', () {
    test('flushes unsaved prose before it changes state', () async {
      final editor = await open('a-football');
      editor.setTitle('Tartanka kubbadda cagta, la cusboonaysiiyay');

      await editor.transition(ArticleStatus.published);

      expect(editor.article.status, ArticleStatus.published);
      expect(
        editor.article.translations['so']!.title,
        'Tartanka kubbadda cagta, la cusboonaysiiyay',
        reason: 'publishing the previous draft would put stale copy in the app',
      );
    });

    test('scheduling records the time', () async {
      final editor = await open('a-football');
      final at = DateTime(2026, 9, 6, 21, 30);

      await editor.transition(ArticleStatus.scheduled, scheduledFor: at);

      expect(editor.article.status, ArticleStatus.scheduled);
      expect(editor.article.scheduledFor, at);
    });
  });

  group('a failed write', () {
    test(
      'keeps the editor\'s text rather than reverting to the server',
      () async {
        final editor = ArticleEditor(
          article: await api.fetchArticle('a-rains'),
          // Every write fails from here on.
          api: _AlwaysFails(),
          autosaveDelay: const Duration(days: 1),
        );
        addTearDown(editor.dispose);

        editor.setTitle('Work the operator would not want thrown away');
        await editor.saveDraft();

        expect(editor.saveState, ArticleSaveState.failed);
        expect(
          editor.draft.title,
          'Work the operator would not want thrown away',
        );
      },
    );
  });

  group('bodies', () {
    test('a body typed in the editor is stored as HTML', () async {
      final editor = await open('a-football');
      editor.draft.body.document.insert(0, 'Warbixin cusub oo dhammaystiran');
      await editor.saveDraft();

      expect(
        editor.article.translations['so']!.bodyHtml,
        contains('Warbixin cusub oo dhammaystiran'),
      );
      expect(editor.article.translations['so']!.bodyHtml, startsWith('<p>'));
    });

    test('an existing body round-trips through the editor untouched', () async {
      final editor = await open('a-rains');
      final before = editor.article.translations['so']!.bodyHtml;

      // Touch a different field, forcing a save of this locale.
      editor.setExcerpt('Soo koobid');
      await editor.saveDraft();

      expect(editor.article.translations['so']!.bodyHtml, before);
    });
  });

  group('adding a language', () {
    test('a new locale starts empty and becomes the active tab', () async {
      final editor = await open('a-road');
      expect(editor.locales, isNot(contains('en')));

      editor.addLocale('en');

      expect(editor.locale, 'en');
      expect(editor.draft.isEmpty, isTrue);
    });

    test('saving it adds the translation to the article', () async {
      final editor = await open('a-road')
        ..addLocale('en')
        ..setTitle('Main road reopened');
      await editor.saveDraft();

      expect(editor.article.translations.keys, contains('en'));
      expect(editor.article.translations['en']!.title, 'Main road reopened');
    });
  });

  group('the autosave switch', () {
    /// An editor whose autosave answers to [enabled], with a delay short
    /// enough to wait out.
    Future<ArticleEditor> openGated(String id, bool Function() enabled) async {
      final editor = ArticleEditor(
        article: await api.fetchArticle(id),
        api: api,
        autosaveDelay: const Duration(milliseconds: 10),
        autosaveEnabled: enabled,
      );
      addTearDown(editor.dispose);
      return editor;
    }

    /// Long enough for the debounce above to have fired if it was going to.
    Future<void> pastTheDebounce() =>
        Future<void>.delayed(const Duration(milliseconds: 60));

    test(
      'defaults to on, and an editor built without one still writes',
      () async {
        final editor = ArticleEditor(
          article: await api.fetchArticle('a-rains'),
          api: api,
          autosaveDelay: const Duration(milliseconds: 10),
        );
        addTearDown(editor.dispose);

        expect(editor.autosaveEnabled(), isTrue);
        editor.setTitle('Heavy rains, revised');
        await pastTheDebounce();

        expect(
          editor.article.translations['so']!.title,
          'Heavy rains, revised',
        );
      },
    );

    test('off means the debounce writes nothing', () async {
      final editor = await openGated('a-rains', () => false);
      final before = editor.article.translations['so']!.title;

      editor.setTitle('Heavy rains, revised');
      await pastTheDebounce();

      expect(editor.article.translations['so']!.title, before);
      expect(
        editor.isDirty,
        isTrue,
        reason:
            'the edit is kept, not discarded — the switch defers writes, '
            'it does not throw work away',
      );
    });

    test('turned off during the debounce still writes nothing', () async {
      // Two seconds in production is long enough to change your mind after
      // the keystroke that armed the timer, which is why the switch is asked
      // again when it fires.
      var enabled = true;
      final editor = await openGated('a-rains', () => enabled);
      final before = editor.article.translations['so']!.title;

      editor.setTitle('Heavy rains, revised');
      enabled = false;
      await pastTheDebounce();

      expect(editor.article.translations['so']!.title, before);
    });

    test('off means leaving a language tab writes nothing either', () async {
      final editor = await openGated('a-rains', () => false);
      final before = editor.article.translations['so']!.title;

      editor
        ..setTitle('Heavy rains, revised')
        ..selectLocale('en');
      await pastTheDebounce();

      expect(editor.article.translations['so']!.title, before);
    });

    test('off does not stop the Save draft button', () async {
      final editor = await openGated('a-rains', () => false);

      editor.setTitle('Heavy rains, revised');
      await editor.saveDraft();

      expect(editor.article.translations['so']!.title, 'Heavy rains, revised');
    });

    test('off does not stop publishing from flushing first', () async {
      // The order this protects: publishing an article whose last sentence is
      // unsaved puts the previous draft in front of readers.
      final editor = await openGated('a-rains', () => false);

      editor.setTitle('Heavy rains, revised');
      await editor.transition(ArticleStatus.published);

      expect(editor.article.translations['so']!.title, 'Heavy rains, revised');
      expect(editor.article.status, ArticleStatus.published);
    });

    test('saveAll carries the language you are no longer looking at', () async {
      // With autosave off nothing flushes on the way out of a tab, so the
      // Somali edits exist nowhere but memory. This is what closing and
      // publishing call, and why they call it instead of saveDraft.
      final editor = await openGated('a-rains', () => false);

      editor
        ..setTitle('Heavy rains, revised')
        ..selectLocale('en')
        ..setTitle('Heavy rains, revised (EN)');
      await editor.saveAll();

      expect(editor.article.translations['so']!.title, 'Heavy rains, revised');
      expect(
        editor.article.translations['en']!.title,
        'Heavy rains, revised (EN)',
      );
      expect(editor.isDirty, isFalse);
    });
  });
}

/// Every write refuses. The admin fixture has no failure injection — the
/// reader's does — and adding one to production code for a single test would
/// be the tail wagging the dog.
class _AlwaysFails implements PuntlandAdminApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<Never>.error(
    const Failure(kind: FailureKind.offline, code: 'OFFLINE'),
  );
}
