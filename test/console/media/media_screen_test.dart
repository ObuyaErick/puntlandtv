import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/features/media/presentation/controllers/media_library_controller.dart';
import 'package:puntland/console/features/media/presentation/pages/media_detail_panel.dart';
import 'package:puntland/console/features/media/presentation/pages/media_library_page.dart';
import 'package:puntland/console/features/media/presentation/widgets/media_grid_tile.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedInEditor extends AuthController {
  @override
  AuthState build() => const SignedIn(
    ConsoleUser(
      id: 'u-editor',
      name: 'A. Yuusuf',
      email: 'a@pltv.so',
      role: ConsoleRole.editor,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Locale locale = const Locale('en', 'US'),
    Size size = const Size(1440, 900),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_SignedInEditor.new),
          adminApiProvider.overrideWithValue(
            FixtureAdminApi(
              latency: Duration.zero,
              now: DateTime(2026, 8, 30, 21, 12),
            ),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          theme: AppTheme.light(),
          supportedLocales: const [Locale('en', 'US'), Locale('so')],
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppL10n.delegate,
            SoMaterialLocalizations.delegate,
            SoCupertinoLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(body: screen),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pump();

    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  group('media library', () {
    testWidgets('renders every asset in the fixture', (tester) async {
      await pump(tester, const MediaLibraryPage());

      expect(find.byType(MediaGridTile), findsNWidgets(9));
      expect(find.text('Media library'), findsOneWidget);
    });

    testWidgets('leads with the per-locale alt text rule', (tester) async {
      await pump(tester, const MediaLibraryPage());

      expect(
        find.textContaining('required in both languages'),
        findsOneWidget,
        reason: 'someone has to know the rule before they upload, not after',
      );
    });

    testWidgets('the needs-alt chip counts the Somali-only image too', (
      tester,
    ) async {
      await pump(tester, const MediaLibraryPage());

      await tester.tap(find.text('Needs alt text'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      final shown = container.read(mediaLibraryProvider).value!;
      expect(shown.map((a) => a.id), containsAll(['m-school', 'm-livestock']));
      expect(shown.every((a) => a.blocksPublishing), isTrue);
    });

    testWidgets('a tile says what is wrong rather than what it weighs', (
      tester,
    ) async {
      await pump(tester, const MediaLibraryPage());

      // m-livestock is undescribed; m-school is Somali-only.
      expect(find.text('Missing alt text in 2 languages'), findsOneWidget);
      expect(find.text('Missing alt text in 1 language'), findsOneWidget);
    });

    testWidgets('a failed ingest is visible without opening anything', (
      tester,
    ) async {
      await pump(tester, const MediaLibraryPage());

      expect(find.text('FAILED'), findsWidgets);
      expect(find.text('TRANSCODING'), findsWidgets);
      expect(find.textContaining('Transcoding · 62%'), findsWidgets);
    });

    testWidgets('search narrows the grid', (tester) async {
      await pump(tester, const MediaLibraryPage());

      await tester.enterText(find.byType(TextField).first, 'Reuters');
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.byType(MediaGridTile), findsOneWidget);
    });

    testWidgets('an excluding filter offers a way back', (tester) async {
      await pump(tester, const MediaLibraryPage());

      await tester.enterText(find.byType(TextField).first, 'zzzznothing');
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.text('No files match this filter'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
    });
  });

  group('asset panel', () {
    testWidgets('shows one alt field per required locale', (tester) async {
      await pump(tester, const MediaDetailPanel(assetId: 'm-school'));

      expect(find.text('Alt text (Somali)'), findsOneWidget);
      expect(find.text('Alt text (English)'), findsOneWidget);
      expect(
        find.text('Missing alt text in 1 language'),
        findsOneWidget,
        reason: 'the Somali-only fixture image',
      );
    });

    testWidgets('the summary reacts to typing, not to saving', (tester) async {
      await pump(tester, const MediaDetailPanel(assetId: 'm-school'));

      final english = find.byType(TextField).at(1);
      await tester.enterText(english, 'Students in a classroom');
      await tester.pump();

      expect(find.text('Described in both languages'), findsOneWidget);
      expect(find.text('Missing alt text in 1 language'), findsNothing);
    });

    testWidgets('delete is disabled — not hidden — while in use', (
      tester,
    ) async {
      await pump(tester, const MediaDetailPanel(assetId: 'm-school'));

      final delete = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Delete'),
      );
      expect(
        delete.onPressed,
        isNull,
        reason:
            '"why can I not delete this" is a question the screen has to '
            'answer, and a missing button answers nothing',
      );
      expect(find.textContaining('1 of them is published'), findsOneWidget);
    });

    testWidgets('delete is available on an unused asset', (tester) async {
      await pump(tester, const MediaDetailPanel(assetId: 'm-livestock'));

      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Delete'),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.text('Not used yet'), findsOneWidget);
    });

    testWidgets('a video panel shows no alt fields and offers a retry', (
      tester,
    ) async {
      await pump(tester, const MediaDetailPanel(assetId: 'm-dood-17'));

      expect(
        find.text('Alt text (Somali)'),
        findsNothing,
        reason:
            'empty alt fields on a video would teach the newsroom that '
            'captions had been dealt with',
      );
      // Twice: over the poster, and in the block that explains it.
      expect(find.text('Ingest failed'), findsWidgets);
      expect(find.text('Retry ingest'), findsOneWidget);
    });

    testWidgets('saving alt text clears the needs-alt state', (tester) async {
      await pump(tester, const MediaDetailPanel(assetId: 'm-school'));

      await tester.enterText(
        find.byType(TextField).at(1),
        'Students in a classroom on the first day of term',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      final saved = await container.read(mediaAssetProvider('m-school').future);
      expect(saved.blocksPublishing, isFalse);
      expect(saved.alt['en'], contains('Students'));
    });
  });

  group('locale uniformity', () {
    testWidgets('one switch re-hydrates chrome and rule text alike', (
      tester,
    ) async {
      await pump(tester, const MediaLibraryPage(), locale: const Locale('so'));

      expect(find.text('Maktabadda warbaahinta'), findsOneWidget);
      expect(find.text('Dhammaan'), findsOneWidget);
      expect(find.text('Wuxuu u baahan yahay qoraal sawir'), findsOneWidget);
      expect(
        find.textContaining('Media library'),
        findsNothing,
        reason: 'no English may survive a switch to Somali',
      );
    });

    testWidgets('the alt field labels name the language in Somali', (
      tester,
    ) async {
      await pump(
        tester,
        const MediaDetailPanel(assetId: 'm-school'),
        locale: const Locale('so'),
      );

      expect(find.text('Qoraalka sawirka (Soomaali)'), findsOneWidget);
      expect(find.text('Qoraalka sawirka (Ingiriisi)'), findsOneWidget);
    });
  });

  group('layout', () {
    for (final (label, size) in const [
      ('compact', Size(390, 844)),
      ('medium', Size(760, 1024)),
      ('expanded', Size(1100, 800)),
      ('large', Size(1440, 900)),
    ]) {
      testWidgets('the grid lays out with no overflow at $label', (
        tester,
      ) async {
        await pump(tester, const MediaLibraryPage(), size: size);

        expect(tester.takeException(), isNull);
        expect(find.byType(MediaGridTile), findsWidgets);
      });
    }
  });
}
