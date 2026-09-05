import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/l10n/so_material_localizations.dart';
import '../../core/providers/preferences_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pltv_logo.dart';
import '../../features/settings/domain/entities/app_preferences.dart';
import '../core/providers/console_providers.dart';
import 'console_router.dart';

/// The content console.
///
/// Shares the app's theme and localisation wholesale — same tokens, same
/// delegates, same Somali workaround. It is the same product seen from the
/// other side, not a separate one.
class PuntlandConsoleApp extends ConsumerWidget {
  const PuntlandConsoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themePref = ref.watch(preferencesProvider).theme;
    final themeMode = switch (themePref) {
      ThemePreference.system => ThemeMode.system,
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
    };

    // The stored session is read before the router exists, not after. The
    // router's guard sends anyone unauthenticated to the sign-in page, and
    // building it while the restore is still in flight would bounce a signed-in
    // editor off their own URL — losing the deep link they reloaded on, which
    // on a browser tool is most of the point of having URLs.
    final restored = ref.watch(consoleSessionProvider);
    if (restored.isLoading) {
      return MaterialApp(
        title: _title,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const _ConsoleSplash(),
      );
    }

    return MaterialApp.router(
      title: _title,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(consoleRouterProvider),

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,

      locale: locale,
      supportedLocales: const [Locale('en', 'US'), Locale('so')],

      // Order matters, for the reason spelled out in `app/app.dart`: Somali is
      // not among the locales Flutter bundles, so our delegates go first.
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        AppL10n.delegate,
        SoMaterialLocalizations.delegate,
        SoCupertinoLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
    );
  }
}

const _title = 'Puntland TV Console';

/// One frame or two on a cold start, longer on a slow connection.
///
/// Deliberately wordless: it is up before the localisations are, and a splash
/// that flashes English at a Somali operator would be the one place in the
/// console that does.
class _ConsoleSplash extends StatelessWidget {
  const _ConsoleSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PltvMark(height: 40),
            SizedBox(height: 24),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
