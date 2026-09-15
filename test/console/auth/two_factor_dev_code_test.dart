import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/features/auth/presentation/widgets/two_factor_dialog.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/theme/app_theme.dart';

/// TEMPORARY: the second factor's dev code pre-fills the form until the
/// backend sends codes by SMS. Delete with the pre-fill.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, {String? devCode}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _Awaiting(devCode)),
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
          home: const Scaffold(body: TwoFactorForm()),
        ),
      ),
    );
    // Not pumpAndSettle: the resend countdown ticks forever.
    await tester.pump();
  }

  String codeText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('a dev code fills the boxes without verifying', (tester) async {
    await pump(tester, devCode: '482913');

    expect(codeText(tester), '482913');
    for (final digit in '482913'.split('')) {
      expect(find.text(digit), findsOneWidget);
    }

    // Filling is not submitting: the attempt is still the operator's to make.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TwoFactorForm)),
    );
    expect(container.read(authControllerProvider), isA<AwaitingSecondFactor>());
    expect(_Awaiting.verified, isEmpty);
  });

  testWidgets('without a dev code the boxes start empty', (tester) async {
    await pump(tester);

    expect(codeText(tester), isEmpty);
  });
}

class _Awaiting extends AuthController {
  _Awaiting(this.devCode) {
    verified.clear();
  }

  final String? devCode;

  static final verified = <String>[];

  @override
  AuthState build() =>
      AwaitingSecondFactor(email: 'a.yuusuf@pltv.so', devCode: devCode);

  @override
  Future<void> verify(String code) async => verified.add(code);
}
