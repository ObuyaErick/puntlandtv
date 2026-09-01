/// One remotely toggled feature.
class FeatureFlagDto {
  const FeatureFlagDto({
    required this.key,
    required this.enabled,
    this.description,
  });

  factory FeatureFlagDto.fromJson(Map<String, dynamic> json) => FeatureFlagDto(
    key: json['key'] as String,
    enabled: json['enabled'] as bool,
    description: json['description'] as String?,
  );

  /// The identifier the app reads. Permanent, like a category slug: a released
  /// build looks for this exact string, so renaming it turns the flag off for
  /// everyone already installed.
  final String key;

  final bool enabled;

  /// Operator-facing note from the backend. Not translated — it is written by
  /// whoever added the flag, alongside the code that reads it, and has to stay
  /// greppable against that code.
  final String? description;

  FeatureFlagDto copyWith({bool? enabled}) => FeatureFlagDto(
    key: key,
    enabled: enabled ?? this.enabled,
    description: description,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'enabled': enabled,
    'description': description,
  };
}

/// A language the app can be used in.
class LocaleOptionDto {
  const LocaleOptionDto({
    required this.code,
    required this.enabled,
    required this.articlesOnlyInThisLocale,
  });

  factory LocaleOptionDto.fromJson(Map<String, dynamic> json) =>
      LocaleOptionDto(
        code: json['code'] as String,
        enabled: json['enabled'] as bool,
        articlesOnlyInThisLocale: json['articles_only_here'] as int,
      );

  final String code;
  final bool enabled;

  /// Published articles that exist in **no other** enabled language.
  ///
  /// This is the number that makes disabling a locale a decision rather than a
  /// switch: turning the language off does not just change some labels, it
  /// removes this many stories from the product with nothing behind them.
  final int articlesOnlyInThisLocale;

  LocaleOptionDto copyWith({bool? enabled}) => LocaleOptionDto(
    code: code,
    enabled: enabled ?? this.enabled,
    articlesOnlyInThisLocale: articlesOnlyInThisLocale,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'enabled': enabled,
    'articles_only_here': articlesOnlyInThisLocale,
  };
}

/// Everything `GET /v1/config` serves, from the writing side.
///
/// Two of these fields can take the product down for every reader at once, and
/// neither failure is visible from the form unless the model refuses:
///
/// 1. **A minimum build above what has actually shipped locks everyone out.**
///    The app asks readers below the floor to update, and if no build at or
///    above the floor exists in either store, there is nothing to update to.
///    Every reader hits a wall, and the fix requires a store release —
///    days, not minutes. So the floor is bounded by [currentReleasedBuild].
/// 2. **Disabling a locale removes content, not just labels.** An article that
///    exists only in Somali has nowhere to go when Somali is off; it does not
///    fall back, it disappears. [LocaleOptionDto.articlesOnlyInThisLocale]
///    is how many, and the last enabled locale cannot be turned off at all.
class ConsoleConfigDto {
  const ConsoleConfigDto({
    required this.minimumSupportedBuild,
    required this.currentReleasedBuild,
    required this.locales,
    required this.flags,
    this.dataSaverDefault = true,
    this.updatedAt,
    this.updatedBy,
  });

  factory ConsoleConfigDto.fromJson(Map<String, dynamic> json) =>
      ConsoleConfigDto(
        minimumSupportedBuild: json['minimum_supported_build'] as int,
        currentReleasedBuild: json['current_released_build'] as int,
        locales: [
          for (final locale in json['locales'] as List<dynamic>)
            LocaleOptionDto.fromJson(locale as Map<String, dynamic>),
        ],
        flags: [
          for (final flag in json['flags'] as List<dynamic>)
            FeatureFlagDto.fromJson(flag as Map<String, dynamic>),
        ],
        dataSaverDefault: json['data_saver_default'] as bool? ?? true,
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
        updatedBy: json['updated_by'] as String?,
      );

  /// Builds below this are asked to update before continuing.
  final int minimumSupportedBuild;

  /// The highest build actually available in the stores. Not editable here —
  /// it is a fact about what shipped, and the floor is measured against it.
  final int currentReleasedBuild;

  final List<LocaleOptionDto> locales;
  final List<FeatureFlagDto> flags;

  /// Defaults to true: most of the audience is on metered mobile data.
  final bool dataSaverDefault;

  final DateTime? updatedAt;
  final String? updatedBy;

  List<LocaleOptionDto> get enabledLocales =>
      locales.where((l) => l.enabled).toList(growable: false);

  LocaleOptionDto? locale(String code) =>
      locales.where((l) => l.code == code).firstOrNull;

  /// The highest floor that is safe to set. See rule 1 in the class doc.
  int get maximumSafeBuild => currentReleasedBuild;

  bool get isFloorValid => minimumSupportedBuild <= currentReleasedBuild;

  /// How far above the released build the floor has been pushed. Zero when the
  /// floor is safe.
  int get floorOvershoot =>
      isFloorValid ? 0 : minimumSupportedBuild - currentReleasedBuild;

  /// Whether every reader would be locked out by the current floor.
  ///
  /// Distinguished from [isFloorValid] because a floor one build above the
  /// release is the same catastrophe as one a hundred above, and the screen
  /// should not imply that a small overshoot is a small problem.
  bool get locksEveryoneOut => !isFloorValid;

  /// Whether [code] can be switched off.
  ///
  /// The last enabled language cannot: an app with no locales has no content
  /// in any language, which is not a configuration anyone means to reach.
  bool canDisableLocale(String code) {
    final target = locale(code);
    if (target == null || !target.enabled) return false;
    return enabledLocales.length > 1;
  }

  /// Published articles that would disappear if [code] were switched off.
  int articlesStrandedBy(String code) =>
      locale(code)?.articlesOnlyInThisLocale ?? 0;

  /// The single gate on saving.
  bool get canSave => isFloorValid && enabledLocales.isNotEmpty;

  ConsoleConfigDto copyWith({
    int? minimumSupportedBuild,
    List<LocaleOptionDto>? locales,
    List<FeatureFlagDto>? flags,
    bool? dataSaverDefault,
  }) => ConsoleConfigDto(
    minimumSupportedBuild: minimumSupportedBuild ?? this.minimumSupportedBuild,
    currentReleasedBuild: currentReleasedBuild,
    locales: locales ?? this.locales,
    flags: flags ?? this.flags,
    dataSaverDefault: dataSaverDefault ?? this.dataSaverDefault,
    updatedAt: updatedAt,
    updatedBy: updatedBy,
  );

  ConsoleConfigDto withLocaleEnabled(String code, bool enabled) => copyWith(
    locales: [
      for (final option in locales)
        if (option.code == code) option.copyWith(enabled: enabled) else option,
    ],
  );

  ConsoleConfigDto withFlag(String key, bool enabled) => copyWith(
    flags: [
      for (final flag in flags)
        if (flag.key == key) flag.copyWith(enabled: enabled) else flag,
    ],
  );

  Map<String, dynamic> toJson() => {
    'minimum_supported_build': minimumSupportedBuild,
    'current_released_build': currentReleasedBuild,
    'locales': [for (final locale in locales) locale.toJson()],
    'flags': [for (final flag in flags) flag.toJson()],
    'data_saver_default': dataSaverDefault,
    'updated_at': updatedAt?.toIso8601String(),
    'updated_by': updatedBy,
  };
}

/// Refusal codes the admin API raises for config writes.
abstract final class ConfigFailureCode {
  /// The floor was set above the highest released build.
  static const floorAboveRelease = 'CONFIG_FLOOR_ABOVE_RELEASE';

  /// The save would leave no enabled locales.
  static const noLocales = 'CONFIG_NO_LOCALES';
}
