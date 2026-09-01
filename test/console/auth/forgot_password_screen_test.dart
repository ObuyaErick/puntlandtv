import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/auth/presentation/pages/sign_in_page.dart';
import 'package:puntland/console/features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The forgotten-password flow as an operator meets it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester, {
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

  /// Fields *inside* the dialog.
  ///
  /// The sign-in form stays in the tree behind it, so an unscoped finder reaches
  /// its email and password fields first — which is how an earlier version of
  /// this test typed the address into the wrong form and got a confusing
  /// failure rather than a useful one.
  Finder dialogFields() => find.descendant(
    of: find.byType(ForgotPasswordForm),
    matching: find.byType(TextField),
  );

  Future<void> openDialog(WidgetTester tester, {String? email}) async {
    if (email != null) {
      await tester.enterText(find.byType(TextField).first, email);
    }
    await tester.tap(find.text('Forgot password'));
    await tester.pumpAndSettle();
  }

  /// Step one, through to the code screen.
  Future<void> requestCode(WidgetTester tester, String email) async {
    await openDialog(tester);
    await tester.enterText(dialogFields().first, email);
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
  }

  testWidgets('the forgot-password link opens the flow', (tester) async {
    await pump(tester);

    expect(find.text('Forgot password'), findsOneWidget);
    await tester.tap(find.text('Forgot password'));
    await tester.pumpAndSettle();

    // The regression this test exists for: the link was wired to an empty
    // callback, so pressing it did nothing at all.
    expect(find.text('Reset your password'), findsOneWidget);
  });

  testWidgets('the address already typed travels into the dialog', (
    tester,
  ) async {
    await pump(tester);

    await openDialog(tester, email: 'a.yuusuf@pltv.so');

    // Someone who has just failed to sign in has already typed their address.
    // Asserted on the controller rather than on rendered text: both forms hint
    // with the same example address, so matching text proves nothing.
    expect(
      tester.widget<TextField>(dialogFields().first).controller?.text,
      'a.yuusuf@pltv.so',
    );
  });

  testWidgets('sends a code, then sets a password', (tester) async {
    await pump(tester);

    await requestCode(tester, 'a.yuusuf@pltv.so');

    expect(find.text('Enter the code'), findsOneWidget);
    // The development build has no gateway, so the code is shown rather than
    // sent. Its presence here is what makes the flow demonstrable.
    expect(
      find.textContaining(FixtureAdminApi.validResetCode),
      findsOneWidget,
    );

    final fields = dialogFields();
    await tester.enterText(fields.at(0), FixtureAdminApi.validResetCode);
    await tester.enterText(fields.at(1), 'a-long-enough-passphrase');
    await tester.enterText(fields.at(2), 'a-long-enough-passphrase');
    await tester.tap(find.text('Set password'));
    await tester.pumpAndSettle();

    expect(find.text('Password changed'), findsOneWidget);
    // Someone resetting a password they believe was stolen needs to be told
    // this happened.
    expect(
      find.textContaining('signed out'),
      findsOneWidget,
      reason: 'the reset ended every other session and must say so',
    );
  });

  testWidgets('mismatched passwords are caught in the dialog', (tester) async {
    await pump(tester);

    await requestCode(tester, 'a.yuusuf@pltv.so');

    final fields = dialogFields();
    await tester.enterText(fields.at(0), FixtureAdminApi.validResetCode);
    await tester.enterText(fields.at(1), 'a-long-enough-passphrase');
    await tester.enterText(fields.at(2), 'a-different-passphrase');
    await tester.tap(find.text('Set password'));
    await tester.pumpAndSettle();

    // The backend cannot answer this — it never sees what was typed twice.
    expect(find.text('Those passwords do not match.'), findsOneWidget);
    expect(find.text('Password changed'), findsNothing);
  });

  testWidgets('a wrong code reports the attempt and stays open', (
    tester,
  ) async {
    await pump(tester);

    await requestCode(tester, 'a.yuusuf@pltv.so');

    final fields = dialogFields();
    await tester.enterText(fields.at(0), '000000');
    await tester.enterText(fields.at(1), 'a-long-enough-passphrase');
    await tester.enterText(fields.at(2), 'a-long-enough-passphrase');
    await tester.tap(find.text('Set password'));
    await tester.pumpAndSettle();

    expect(find.text('That code is not correct.'), findsOneWidget);
    expect(find.text('Enter the code'), findsOneWidget);
  });
}
