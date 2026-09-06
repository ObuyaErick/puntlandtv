import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/auth/presentation/pages/sign_in_page.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The sign-in form as an operator meets it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1440 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          adminApiProvider.overrideWithValue(
            FixtureAdminApi(latency: Duration.zero),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en', 'US'),
          theme: AppTheme.light(),
          supportedLocales: const [Locale('en', 'US'), Locale('so')],
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppL10n.delegate,
            SoMaterialLocalizations.delegate,
            SoCupertinoLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const SignInPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The password field is the second one on the form; the first is the email.
  TextField passwordField(WidgetTester tester) =>
      tester.widgetList<TextField>(find.byType(TextField)).elementAt(1);

  testWidgets('the password is masked until the reveal is pressed', (
    tester,
  ) async {
    await pump(tester);

    expect(passwordField(tester).obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(passwordField(tester).obscureText, isFalse);

    // And back: the toggle is not one-way.
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    expect(passwordField(tester).obscureText, isTrue);
  });

  testWidgets('the reveal names what pressing it will do', (tester) async {
    await pump(tester);

    expect(find.byTooltip('Show password'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('revealing the password keeps what was typed', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField).at(1), 'ku-soo-dhawoow');
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(passwordField(tester).controller?.text, 'ku-soo-dhawoow');
  });
}
