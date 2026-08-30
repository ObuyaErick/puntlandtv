import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/data/preferences_store.dart';
import '../../features/settings/domain/entities/app_preferences.dart';

/// Overridden in `bootstrap.dart` once preferences have loaded, so every read
/// below this point is synchronous.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('sharedPreferencesProvider must be overridden in main()');
});

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => PreferencesStore(ref.watch(sharedPreferencesProvider)),
);

/// The single source of truth for user settings.
class PreferencesController extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => ref.read(preferencesStoreProvider).read();

  Future<void> _update(AppPreferences next) async {
    state = next;
    await ref.read(preferencesStoreProvider).write(next);
  }

  Future<void> setLocale(LocalePreference value) =>
      _update(state.copyWith(locale: value));

  Future<void> setTheme(ThemePreference value) =>
      _update(state.copyWith(theme: value));

  Future<void> setDataSaver({required bool value}) =>
      _update(state.copyWith(dataSaver: value));

  Future<void> setWifiOnlyDownloads({required bool value}) =>
      _update(state.copyWith(wifiOnlyDownloads: value));

  Future<void> setBreakingAlerts({required bool value}) =>
      _update(state.copyWith(breakingAlerts: value));
}

final preferencesProvider =
    NotifierProvider<PreferencesController, AppPreferences>(
      PreferencesController.new,
    );

/// The device's own language, read once. Used to resolve
/// [LocalePreference.system].
final deviceLanguageCodeProvider = Provider<String>(
  (ref) => PlatformDispatcher.instance.locale.languageCode,
);

/// The locale the UI actually renders in.
///
/// Resolution order, per the MVP plan: explicit user choice → device locale
/// (if we support it) → `en-US`.
final localeProvider = Provider<Locale>((ref) {
  final pref = ref.watch(preferencesProvider).locale;
  final device = ref.watch(deviceLanguageCodeProvider);
  return switch (pref) {
    LocalePreference.english => const Locale('en', 'US'),
    LocalePreference.somali => const Locale('so'),
    LocalePreference.system =>
      device == 'so' ? const Locale('so') : const Locale('en', 'US'),
  };
});

/// What goes in the `Accept-Language` header.
final localeTagProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}-${locale.countryCode}';
});
