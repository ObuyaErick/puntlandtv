import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/features/operations/presentation/controllers/push_controller.dart';
import 'package:puntland/console/features/operations/presentation/pages/categories_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/live_control_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/push_composer_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/schedule_page.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedInAs extends AuthController {
  _SignedInAs(this.role);

  final ConsoleRole role;

  @override
  AuthState build() => SignedIn(
    ConsoleUser(
      id: 'u-${role.name}',
      name: 'A. Yuusuf',
      email: 'a@pltv.so',
      role: role,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    ConsoleRole role = ConsoleRole.operations,
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
          authControllerProvider.overrideWith(() => _SignedInAs(role)),
          adminApiProvider.overrideWithValue(
            FixtureAdminApi(
              latency: Duration.zero,
              now: DateTime(2026, 8, 30, 21, 12),
            ),
          ),
        ],
        child: MaterialApp(
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

  group('push composer', () {
    testWidgets('send is blocked until both locales are complete', (
      tester,
    ) async {
      await pumpScreen(tester, const PushComposerPage());

      final reviewButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Review & send'),
      );
      expect(
        reviewButton.onPressed,
        isNull,
        reason: 'an empty draft cannot be sent to 38,000 devices',
      );
      expect(
        find.textContaining('Send is blocked until both locales'),
        findsOneWidget,
      );
    });

    testWidgets('a Somali-only alert still cannot be sent', (tester) async {
      await pumpScreen(tester, const PushComposerPage());

      final push = container.read(pushDraftProvider.notifier);
      push
        ..setTitle('so', 'Warar deg deg')
        ..setBody('so', 'Taabo si aad u akhrido.');
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Review & send'),
            )
            .onPressed,
        isNull,
      );
      expect(container.read(pushDraftProvider).incompleteLocales, ['en']);
    });

    testWidgets('completing both locales unlocks send', (tester) async {
      await pumpScreen(tester, const PushComposerPage());

      final push = container.read(pushDraftProvider.notifier);
      push
        ..setTitle('so', 'Warar deg deg')
        ..setBody('so', 'Taabo si aad u akhrido.')
        ..setTitle('en', 'Breaking news')
        ..setBody('en', 'Tap to read the full report.');
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Review & send'),
            )
            .onPressed,
        isNotNull,
      );
    });
  });

  group('live control', () {
    testWidgets('the off-air toggle is disabled without both slate locales', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage());

      // The fixture seeds a Somali-only slate on purpose.
      final toggle = tester.widget<Switch>(find.byKey(const Key('tv-on-air')));
      expect(toggle.value, isTrue);
      expect(
        toggle.onChanged,
        isNull,
        reason:
            'going off air with no English slate leaves English readers '
            'staring at a dead player',
      );
      expect(find.textContaining('Both locales are required'), findsWidgets);
    });

    /// The fixture ships one rung, `source`, because that is what the
    /// packager publishes: MediaMTX remuxes rather than transcodes, so viewers
    /// receive whatever the studio sends. That one rung is therefore the
    /// lowest, and the server flags it protected.
    ///
    /// This used to assert against `rendition-240p` and `rendition-1080p`
    /// from a three-rung fixture the backend never had. The rung name is not
    /// the point — the point is that the console cannot offer to turn off the
    /// only stream there is.
    testWidgets('the protected rendition switch is not operable', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage());

      // Addressed by key: several switches share this screen, and finding
      // them by type or order asserts the wrong control the moment the layout
      // changes.
      final protected = tester.widget<Switch>(
        find.byKey(const Key('rendition-source')),
      );
      expect(
        protected.onChanged,
        isNull,
        reason: 'it is the only rung, so it is the one the audience receives',
      );
    });

    /// The ingest panel is the answer to an operator's first question about a
    /// live channel — what is actually arriving — which this screen could not
    /// answer at all before there was a packager behind it.
    testWidgets('reports what the packager is receiving', (tester) async {
      await pumpScreen(tester, const LiveControlPage());

      // The fixture publishes over RTMP at 720p.
      expect(find.text('RTMP'), findsOneWidget);
      expect(find.text('720p H264'), findsOneWidget);
      expect(find.textContaining('rtmp://'), findsWidgets);
    });

    /// Never-used is the fastest way to spot a studio still configured with
    /// the credential a newer one was minted to replace.
    testWidgets('lists ingest credentials and flags an unused one', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage());

      expect(find.text('studio-obs'), findsOneWidget);
      expect(find.text('backup-encoder'), findsOneWidget);
      expect(find.text('Never used'), findsOneWidget);
    });

    /// The secret exists in the mint response and nowhere else — the server
    /// keeps a scrypt hash — so the screen has to show it once and say so.
    testWidgets('shows a freshly minted secret once, with the warning', (
      tester,
    ) async {
      await pumpScreen(tester, const LiveControlPage());

      expect(find.byKey(const Key('minted-ingest-secret')), findsNothing);

      await tester.tap(find.byKey(const Key('new-ingest-key')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Outside broadcast');
      await tester.tap(find.text('New key').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('minted-ingest-secret')), findsOneWidget);
      expect(find.textContaining('not be shown again'), findsOneWidget);
      // The whole Stream Key field, assembled: an operator copying two halves
      // into someone else's OBS over the phone is how a broadcast starts late.
      expect(
        find.textContaining('main?user=outside-broadcast'),
        findsOneWidget,
      );
    });
  });

  group('schedule', () {
    testWidgets('surfaces the seeded gap and overlap', (tester) async {
      await pumpScreen(tester, const SchedulePage());

      expect(find.textContaining('GAP'), findsOneWidget);
      expect(find.textContaining('OVERLAP'), findsOneWidget);
    });

    testWidgets('publishing is blocked while an overlap remains', (
      tester,
    ) async {
      await pumpScreen(tester, const SchedulePage());

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Publish day'),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Resolve the overlap'), findsOneWidget);
    });

    testWidgets('auto-resolve clears the overlap and unblocks publishing', (
      tester,
    ) async {
      await pumpScreen(tester, const SchedulePage());

      await tester.tap(find.text('Auto-resolve overlap'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.textContaining('OVERLAP'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Publish day'),
            )
            .onPressed,
        isNotNull,
      );
    });
  });

  group('categories', () {
    testWidgets('an untranslated category is marked and shown hidden', (
      tester,
    ) async {
      await pumpScreen(tester, const CategoriesPage(), role: ConsoleRole.admin);

      // The name falls back to the other language and the gap is stated in
      // words, rather than a "Not translated" placeholder where a name should
      // be.
      expect(find.text('Waxbarasho'), findsOneWidget);
      expect(find.textContaining('No English translation'), findsOneWidget);
      expect(find.textContaining('slug is permanent'), findsOneWidget);
    });
  });
}
