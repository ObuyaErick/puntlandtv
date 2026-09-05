import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/app/console_router.dart';
import 'package:puntland/console/app/console_routes.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/features/auth/presentation/pages/sign_in_page.dart';
import 'package:puntland/console/features/programs/presentation/pages/episode_list_page.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An auth state the test can move, so the guard can be watched reacting to a
/// sign-out rather than only to how it started.
class _Auth extends AuthController {
  _Auth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void enter(AuthState next) => state = next;
}

ConsoleUser _user(ConsoleRole role) => ConsoleUser(
  id: 'u-${role.name}',
  name: 'A. Yuusuf',
  email: 'a@pltv.so',
  role: role,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late GoRouter router;

  Future<void> pumpConsole(
    WidgetTester tester, {
    required AuthState auth,
    String? at,
    Size size = const Size(1440, 900),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(() => _Auth(auth)),
        adminApiProvider.overrideWithValue(
          FixtureAdminApi(
            latency: Duration.zero,
            now: DateTime(2026, 8, 30, 21, 12),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    router = container.read(consoleRouterProvider);
    if (at != null) router.go(at);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          supportedLocales: const [Locale('en', 'US'), Locale('so')],
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppL10n.delegate,
            SoMaterialLocalizations.delegate,
            SoCupertinoLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          routerConfig: router,
        ),
      ),
    );
    // Settle rather than pump a fixed number of frames: a redirect mounts a
    // second screen, whose own fixture reads schedule timers of their own.
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  group('the guard', () {
    testWidgets('sends an unauthenticated request to the sign-in page', (
      tester,
    ) async {
      await pumpConsole(
        tester,
        auth: const SignedOut(),
        at: ConsoleRoutes.users,
      );

      expect(location(), ConsoleRoutes.signIn);
      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('refuses a destination the role cannot open', (tester) async {
      // The rail hides Users from a journalist, but hiding is presentation:
      // typing the URL is the case that matters.
      await pumpConsole(
        tester,
        auth: SignedIn(_user(ConsoleRole.journalist)),
        at: ConsoleRoutes.users,
      );

      expect(location(), ConsoleRoutes.overview);
      expect(find.text('Users & roles'), findsNothing);
    });

    testWidgets('lets a role through to its own destinations', (tester) async {
      await pumpConsole(
        tester,
        auth: SignedIn(_user(ConsoleRole.admin)),
        at: ConsoleRoutes.users,
      );

      expect(location(), ConsoleRoutes.users);
    });

    testWidgets('keeps a signed-in operator off the sign-in page', (
      tester,
    ) async {
      await pumpConsole(
        tester,
        auth: SignedIn(_user(ConsoleRole.admin)),
        at: ConsoleRoutes.signIn,
      );

      expect(location(), ConsoleRoutes.overview);
    });

    testWidgets('follows a sign-out that happens mid-session', (tester) async {
      await pumpConsole(tester, auth: SignedIn(_user(ConsoleRole.admin)));
      expect(location(), ConsoleRoutes.overview);

      (container.read(authControllerProvider.notifier) as _Auth).enter(
        const SignedOut(),
      );
      await tester.pumpAndSettle();

      expect(location(), ConsoleRoutes.signIn);
    });
  });

  group('destinations', () {
    testWidgets('a rail tap changes the URL', (tester) async {
      await pumpConsole(tester, auth: SignedIn(_user(ConsoleRole.admin)));

      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();

      expect(location(), ConsoleRoutes.media);
    });

    testWidgets('a programme deep-link opens inside the shell', (tester) async {
      // The whole reason this is a route: a link to one programme's episodes is
      // something an editor can paste to a colleague.
      await pumpConsole(
        tester,
        auth: SignedIn(_user(ConsoleRole.admin)),
        at: ConsoleRoutes.program('dood-furan'),
      );

      expect(location(), '/programs/dood-furan');
      expect(find.byType(EpisodeListPage), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget, reason: 'the rail is up');
    });

    testWidgets('the rail keeps a branch where it was left', (tester) async {
      await pumpConsole(
        tester,
        auth: SignedIn(_user(ConsoleRole.admin)),
        at: ConsoleRoutes.program('dood-furan'),
      );

      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();

      expect(
        location(),
        '/programs/dood-furan',
        reason: 'each branch keeps its own navigator, as the app shell does',
      );
    });
  });
}
