import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers/preferences_providers.dart';

/// Shared entrypoint for every flavour.
///
/// Preferences are loaded *before* the first frame so the app opens in the
/// user's language and theme directly. Reading them asynchronously after
/// `runApp` produces a visible flash of English on every cold start, which is
/// exactly the kind of detail that makes a bilingual app feel like an
/// afterthought.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // Crashlytics goes here once the Firebase project exists. Until then,
      // failing loudly in debug is more useful than a silent swallow.
    }
  };

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PuntlandTvApp(),
    ),
  );
}
