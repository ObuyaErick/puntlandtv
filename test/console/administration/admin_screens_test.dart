import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/administration/presentation/controllers/administration_controller.dart';
import 'package:puntland/console/features/administration/presentation/pages/app_config_page.dart';
import 'package:puntland/console/features/administration/presentation/pages/member_panel.dart';
import 'package:puntland/console/features/administration/presentation/pages/users_page.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/features/programs/presentation/controllers/program_controller.dart';
import 'package:puntland/console/features/programs/presentation/pages/programs_page.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedInAdmin extends AuthController {
  @override
  AuthState build() => const SignedIn(
    ConsoleUser(
      id: 'u-admin',
      name: 'S. Warsame',
      email: 's.warsame@pltv.so',
      role: ConsoleRole.admin,
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
          authControllerProvider.overrideWith(_SignedInAdmin.new),
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

  group('programmes', () {
    testWidgets('lists every seeded programme', (tester) async {
      await pump(tester, const ProgramsPage());

      // English titles under an English UI: the table resolves every title
      // through the active locale, like the rest of the console.
      expect(find.text('Evening News'), findsOneWidget);
      expect(find.text('Open Debate'), findsOneWidget);
      expect(find.text('Programmes'), findsOneWidget);
      expect(
        find.text('Barnaamijka Caruurta'),
        findsOneWidget,
        reason:
            'the untitled-in-English programme falls back rather than '
            'showing its slug',
      );
    });

    testWidgets('says which shelf an untitled programme is missing from', (
      tester,
    ) async {
      await pump(tester, const ProgramsPage());

      expect(
        find.text('Hidden from the English shelf'),
        findsOneWidget,
        reason: 'the Somali-only kids programme is published',
      );
    });

    testWidgets('an unfinished draft is not called hidden', (tester) async {
      await pump(tester, const ProgramsPage());

      // The sport programme is unpublished and Somali-only; it gets a DRAFT
      // badge, not a "hidden from" line.
      expect(find.text('DRAFT'), findsWidgets);
      expect(find.text('Hidden from the English shelf'), findsOneWidget);
    });

    testWidgets('opening a programme shows its episodes', (tester) async {
      await pump(tester, const ProgramsPage());

      await tester.tap(find.text('Open Debate'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(container.read(openProgramProvider), 'dood-furan');
      expect(find.textContaining('Episodes · Open Debate'), findsOneWidget);
      expect(find.text('All programmes'), findsOneWidget);
    });
  });

  group('episodes', () {
    Future<void> openDoodFuran(WidgetTester tester) async {
      await pump(tester, const ProgramsPage());
      await tester.tap(find.text('Open Debate'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();
    }

    testWidgets('publish is disabled on every blocked episode', (tester) async {
      await openDoodFuran(tester);

      final buttons = tester
          .widgetList<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Publish'),
          )
          .toList();

      expect(buttons, hasLength(3), reason: 'all three are blocked');
      expect(buttons.every((b) => b.onPressed == null), isTrue);
    });

    testWidgets('each blocker names its own reason', (tester) async {
      await openDoodFuran(tester);

      expect(find.text('Still transcoding'), findsWidgets);
      expect(
        find.text('Transcode failed — retry it in the media library'),
        findsWidgets,
      );
      expect(find.text('No video attached'), findsWidgets);
    });

    testWidgets('the blocked count is stated before anyone reads a row', (
      tester,
    ) async {
      await openDoodFuran(tester);

      expect(find.text('3 episodes cannot be published yet'), findsOneWidget);
    });

    testWidgets('an unblocked episode can be published', (tester) async {
      await pump(tester, const ProgramsPage());
      await tester.tap(find.text('Poetry and Culture'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      final publish = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Publish'),
      );
      expect(publish.onPressed, isNotNull);
    });
  });

  group('users and roles', () {
    testWidgets('lists every account and its role', (tester) async {
      await pump(tester, const UsersPage());

      expect(find.text('S. Warsame'), findsOneWidget);
      expect(find.text('Z. Faarax'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);
      expect(find.text('Invited'), findsOneWidget);
    });

    testWidgets('counts admins who can actually sign in', (tester) async {
      await pump(tester, const UsersPage());

      expect(
        find.text('1 admin can sign in'),
        findsOneWidget,
        reason: 'the invited admin is not a way back in',
      );
    });

    testWidgets('flags accounts with no second factor', (tester) async {
      await pump(tester, const UsersPage());

      expect(find.text('No second factor'), findsWidgets);
      expect(
        find.textContaining('accounts have no second factor'),
        findsOneWidget,
      );
    });

    testWidgets('the panel shows granted and absent capabilities alike', (
      tester,
    ) async {
      await pump(tester, const MemberPanel(memberId: 'u-ops'));

      expect(
        find.text('Streams, schedule, and the on-air toggle'),
        findsOneWidget,
      );
      expect(
        find.text("Edit anyone's article, and publish"),
        findsOneWidget,
        reason: 'the absent rows answer "will this change take something away"',
      );
    });

    testWidgets('you cannot demote yourself out of admin', (tester) async {
      await pump(tester, const MemberPanel(memberId: 'u-admin'));

      expect(
        find.textContaining('cannot revoke your own access'),
        findsWidgets,
      );

      final suspend = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Suspend'),
      );
      expect(suspend.onPressed, isNull);
    });

    testWidgets('a suspended account offers reinstatement', (tester) async {
      await pump(tester, const MemberPanel(memberId: 'u-former'));

      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Reinstate'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('a role change lands', (tester) async {
      await pump(tester, const MemberPanel(memberId: 'u-journalist'));

      await tester.tap(find.text('Editor'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      final directory = await container.read(staffDirectoryProvider.future);
      expect(directory.byId('u-journalist')?.role, ConsoleRole.editor);
    });
  });

  group('app config', () {
    testWidgets('renders every section', (tester) async {
      await pump(tester, const AppConfigPage());

      expect(find.text('MINIMUM SUPPORTED BUILD'), findsOneWidget);
      expect(find.text('LANGUAGES'), findsOneWidget);
      expect(find.text('FEATURE FLAGS'), findsOneWidget);
      expect(find.text('radio_tab'), findsOneWidget);
    });

    testWidgets('save is inert until something changes', (tester) async {
      await pump(tester, const AppConfigPage());

      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNull,
      );
      expect(find.text('Unsaved changes'), findsNothing);
    });

    testWidgets('flipping a flag marks the form dirty and enables save', (
      tester,
    ) async {
      await pump(tester, const AppConfigPage());

      container
          .read(configDraftProvider.notifier)
          .setFlag('vod_downloads', true);
      await tester.pump();

      expect(container.read(configIsDirtyProvider), isTrue);
      expect(find.text('Unsaved changes'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('a floor above the release blocks save and says why', (
      tester,
    ) async {
      await pump(tester, const AppConfigPage());

      container.read(configDraftProvider.notifier).setMinimumBuild(999);
      await tester.pump();

      expect(
        find.textContaining('No released build satisfies this floor'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNull,
        reason: 'only a store release could undo it',
      );
    });

    testWidgets('the language switch states what turning it off costs', (
      tester,
    ) async {
      await pump(tester, const AppConfigPage());

      expect(find.textContaining('only in this language'), findsWidgets);
    });

    testWidgets('the last enabled language cannot be switched off', (
      tester,
    ) async {
      await pump(tester, const AppConfigPage());

      container
          .read(configDraftProvider.notifier)
          .setLocaleEnabled('en', false);
      await tester.pump();

      final somali = tester.widget<Switch>(find.byKey(const Key('locale-so')));
      expect(somali.onChanged, isNull);
      expect(
        find.text('The last language cannot be switched off.'),
        findsOneWidget,
      );
    });

    testWidgets('discard returns the form to what is stored', (tester) async {
      await pump(tester, const AppConfigPage());

      container.read(configDraftProvider.notifier).setMinimumBuild(999);
      await tester.pump();
      expect(container.read(configIsDirtyProvider), isTrue);

      await tester.tap(find.text('Discard'));
      await tester.pump();

      expect(container.read(configIsDirtyProvider), isFalse);
    });

    testWidgets('saving persists and clears the dirty marker', (tester) async {
      await pump(tester, const AppConfigPage());

      container
          .read(configDraftProvider.notifier)
          .setFlag('vod_downloads', true);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      final stored = await container.read(storedConfigProvider.future);
      expect(
        stored.flags.firstWhere((f) => f.key == 'vod_downloads').enabled,
        isTrue,
      );
    });
  });

  group('locale uniformity', () {
    testWidgets('programmes re-hydrate in Somali', (tester) async {
      await pump(tester, const ProgramsPage(), locale: const Locale('so'));

      expect(find.text('Barnaamijyada'), findsOneWidget);
      expect(find.text('Toddobaadle'), findsWidgets);
      expect(find.textContaining('Programmes'), findsNothing);
    });

    testWidgets('users re-hydrate in Somali', (tester) async {
      await pump(tester, const UsersPage(), locale: const Locale('so'));

      expect(find.text('Isticmaalayaasha iyo doorarka'), findsOneWidget);
      expect(find.text('La joojiyay'), findsOneWidget);
      expect(find.textContaining('Users and roles'), findsNothing);
    });

    testWidgets('app config re-hydrates in Somali', (tester) async {
      await pump(tester, const AppConfigPage(), locale: const Locale('so'));

      expect(find.text('Habaynta abka'), findsOneWidget);
      expect(find.text('LUQADAHA'), findsOneWidget);
      expect(find.textContaining('App configuration'), findsNothing);
    });
  });

  group('layout', () {
    for (final (label, size) in const [
      ('compact', Size(390, 844)),
      ('medium', Size(760, 1024)),
      ('expanded', Size(1100, 800)),
      ('large', Size(1440, 900)),
    ]) {
      testWidgets('programmes lay out with no overflow at $label', (
        tester,
      ) async {
        await pump(tester, const ProgramsPage(), size: size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('users lay out with no overflow at $label', (tester) async {
        await pump(tester, const UsersPage(), size: size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('app config lays out with no overflow at $label', (
        tester,
      ) async {
        await pump(tester, const AppConfigPage(), size: size);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
