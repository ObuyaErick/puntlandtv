import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/app/console_shell.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/core/widgets/console_compact_bar.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
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

  Future<void> pumpShell(
    WidgetTester tester, {
    required ConsoleRole role,
    Size size = const Size(1280, 800),
    // A page that draws the phone bar, as every console page does: at compact
    // width the menu button that opens the rail is in it.
    Widget child = const Column(
      children: [
        ConsoleCompactBar(title: 'Page'),
        Expanded(child: SizedBox.expand()),
      ],
    ),
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
          home: ConsoleShell(
            currentRoute: '/overview',
            onNavigate: (_) {},
            child: child,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('rail gating', () {
    testWidgets('a journalist sees no broadcast or admin destinations', (
      tester,
    ) async {
      await pumpShell(tester, role: ConsoleRole.journalist);

      expect(find.text('Articles'), findsOneWidget);
      expect(find.text('Live control'), findsNothing);
      expect(find.text('Push'), findsNothing);
      expect(find.text('Users & roles'), findsNothing);
    });

    testWidgets('operations sees broadcast but not articles or push', (
      tester,
    ) async {
      await pumpShell(tester, role: ConsoleRole.operations);

      expect(find.text('Live control'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Articles'), findsNothing);
      expect(find.text('Push'), findsNothing);
    });

    testWidgets('every role reaches the overview', (tester) async {
      // The landing page is ungated on purpose: it leads with on-air status,
      // which is exactly what Operations needs, and gating it on an article
      // capability hid it from them.
      for (final role in ConsoleRole.values) {
        await pumpShell(tester, role: role);
        expect(
          find.text('Overview'),
          findsOneWidget,
          reason: '${role.name} cannot see the overview',
        );
      }
    });

    testWidgets('an admin sees every destination', (tester) async {
      await pumpShell(tester, role: ConsoleRole.admin);

      for (final destination in consoleDestinations()) {
        final label = destination.label(
          await AppL10n.delegate.load(const Locale('en', 'US')),
        );
        expect(find.text(label), findsOneWidget, reason: '$label missing');
      }
    });
  });

  group('shape', () {
    testWidgets('uses a persistent rail at expanded and up', (tester) async {
      await pumpShell(tester, role: ConsoleRole.admin);

      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Overview'), findsOneWidget);
    });

    /// Tablet width has no room for names but room for a rail: icons over
    /// one short word each, per the design review's tablet artboard.
    testWidgets('collapses the rail to icons and short labels at medium', (
      tester,
    ) async {
      await pumpShell(
        tester,
        role: ConsoleRole.admin,
        size: const Size(768, 1024),
      );

      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Overview'), findsNothing);
      expect(
        find.byTooltip('Collapse sidebar'),
        findsNothing,
        reason: 'collapsed for want of room, so there is nothing to toggle',
      );
    });

    testWidgets('moves the rail into a drawer at compact', (tester) async {
      await pumpShell(
        tester,
        role: ConsoleRole.admin,
        size: const Size(390, 844),
      );

      // The destinations live behind the drawer, so they are not on screen —
      // the way to them is the menu button in the page's navy bar.
      expect(find.text('Overview'), findsNothing);
      expect(find.byKey(const Key('open-navigation')), findsOneWidget);

      await tester.tap(find.byKey(const Key('open-navigation')));
      await tester.pumpAndSettle();
      expect(find.text('Overview'), findsOneWidget);
    });
  });
}
