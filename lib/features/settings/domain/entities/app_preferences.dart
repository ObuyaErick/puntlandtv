/// Which language the UI is rendered in.
enum LocalePreference {
  /// Follow the device. Resolves to Somali when the phone is Somali, English
  /// otherwise.
  system,
  english,
  somali;

  /// The BCP-47 tag to send as `Accept-Language`, given the device locale.
  String tag(String deviceLanguageCode) => switch (this) {
    LocalePreference.system => deviceLanguageCode == 'so' ? 'so' : 'en-US',
    LocalePreference.english => 'en-US',
    LocalePreference.somali => 'so',
  };
}

enum ThemePreference { system, light, dark }

/// Everything the settings screen owns, in one immutable value.
class AppPreferences {
  const AppPreferences({
    this.locale = LocalePreference.system,
    this.theme = ThemePreference.system,
    this.dataSaver = true,
    this.wifiOnlyDownloads = true,
    this.breakingAlerts = true,
  });

  final LocalePreference locale;
  final ThemePreference theme;

  /// Defaults on: most of the audience is on metered mobile data, and the
  /// setting that protects them should not be one they have to discover.
  final bool dataSaver;

  final bool wifiOnlyDownloads;
  final bool breakingAlerts;

  AppPreferences copyWith({
    LocalePreference? locale,
    ThemePreference? theme,
    bool? dataSaver,
    bool? wifiOnlyDownloads,
    bool? breakingAlerts,
  }) => AppPreferences(
    locale: locale ?? this.locale,
    theme: theme ?? this.theme,
    dataSaver: dataSaver ?? this.dataSaver,
    wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
    breakingAlerts: breakingAlerts ?? this.breakingAlerts,
  );
}
