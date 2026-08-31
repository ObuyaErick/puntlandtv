import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Riverpod 3 moved `Override` out of the default export surface.
import 'package:riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/theme/app_theme.dart';

/// Shared widget-test harness.
///
/// The localisation setup here MUST match `app/app.dart` exactly — same
/// delegates, same order. A harness that drifts from the app is how you get
/// "passes in CI, wrong language on device", and with Somali riding on our own
/// delegate rather than the framework's, the ordering is load-bearing.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en', 'US'),
  List<Override> overrides = const [],
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
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
        // `copyWith`, not a fresh `MediaQueryData`. Constructing a new one
        // discards everything else the binding provides — including `size`,
        // which silently becomes `Size.zero`. Anything under test that asks
        // about the window then gets a nonsense answer and the test still
        // passes, which is the worst kind of green.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
}
