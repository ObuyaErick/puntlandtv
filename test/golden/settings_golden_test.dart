@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:puntland/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/golden.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Future<void> pumpSettings(
    WidgetTester tester, {
    required Locale locale,
    required ThemeData theme,
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await pumpGolden(
      tester,
      const SettingsPage(),
      locale: locale,
      theme: theme,
      textScale: textScale,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  testWidgets('settings · light · en', (tester) async {
    await pumpSettings(
      tester,
      locale: const Locale('en', 'US'),
      theme: AppTheme.light(),
    );
    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('../goldens/settings_light_en.png'),
    );
  });

  testWidgets('settings · light · so', (tester) async {
    await pumpSettings(
      tester,
      locale: const Locale('so'),
      theme: AppTheme.light(),
    );
    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('../goldens/settings_light_so.png'),
    );
  });

  testWidgets('settings · dark · so · 130%', (tester) async {
    await pumpSettings(
      tester,
      locale: const Locale('so'),
      theme: AppTheme.dark(),
      textScale: 1.3,
    );
    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('../goldens/settings_dark_so_130.png'),
    );
  });
}
