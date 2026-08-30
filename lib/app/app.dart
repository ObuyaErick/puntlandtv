import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/l10n/l10n.dart';
import '../core/l10n/so_material_localizations.dart';
import '../core/providers/preferences_providers.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/domain/entities/app_preferences.dart';
import 'router/app_router.dart';

class PuntlandTvApp extends ConsumerWidget {
  const PuntlandTvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themePref = ref.watch(preferencesProvider).theme;

    return MaterialApp.router(
      title: 'Puntland TV',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (themePref) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },

      locale: locale,
      supportedLocales: const [Locale('en', 'US'), Locale('so')],

      // Order matters. Somali is not among the 116 locales Flutter bundles, so
      // our delegates must be offered *before* the global ones — otherwise the
      // framework silently serves English dialog buttons and tooltips inside a
      // Somali UI. See `core/l10n/so_material_localizations.dart`.
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        AppL10n.delegate,
        SoMaterialLocalizations.delegate,
        SoCupertinoLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
    );
  }
}
