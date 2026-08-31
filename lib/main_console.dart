import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'console/app/console_app.dart';
import 'core/providers/preferences_providers.dart';

/// Entrypoint for the internal content console.
///
/// A second entrypoint in the same package rather than a second package: the
/// console shares `core/` — theme, localisation, responsive primitives — and
/// splitting into a melos workspace is a large change to make before either
/// side has settled. Run it with:
///
/// ```
/// fvm flutter run -d chrome -t lib/main_console.dart
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PuntlandConsoleApp(),
    ),
  );
}
