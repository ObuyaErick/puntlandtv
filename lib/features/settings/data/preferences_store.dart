import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_preferences.dart';

/// Reads and writes [AppPreferences]. Synchronous reads, because the app needs
/// the locale and theme before the first frame — an async read here would mean
/// a flash of the wrong language on every cold start.
class PreferencesStore {
  const PreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const _localeKey = 'prefs.locale';
  static const _themeKey = 'prefs.theme';
  static const _dataSaverKey = 'prefs.dataSaver';
  static const _wifiOnlyKey = 'prefs.wifiOnlyDownloads';
  static const _alertsKey = 'prefs.breakingAlerts';

  AppPreferences read() => AppPreferences(
    locale: _enum(_localeKey, LocalePreference.values, LocalePreference.system),
    theme: _enum(_themeKey, ThemePreference.values, ThemePreference.system),
    dataSaver: _prefs.getBool(_dataSaverKey) ?? true,
    wifiOnlyDownloads: _prefs.getBool(_wifiOnlyKey) ?? true,
    breakingAlerts: _prefs.getBool(_alertsKey) ?? true,
  );

  Future<void> write(AppPreferences value) async {
    await _prefs.setString(_localeKey, value.locale.name);
    await _prefs.setString(_themeKey, value.theme.name);
    await _prefs.setBool(_dataSaverKey, value.dataSaver);
    await _prefs.setBool(_wifiOnlyKey, value.wifiOnlyDownloads);
    await _prefs.setBool(_alertsKey, value.breakingAlerts);
  }

  T _enum<T extends Enum>(String key, List<T> values, T fallback) {
    final raw = _prefs.getString(key);
    if (raw == null) return fallback;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }
}
