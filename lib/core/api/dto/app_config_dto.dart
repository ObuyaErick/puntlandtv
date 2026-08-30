import 'package:json_annotation/json_annotation.dart';

part 'app_config_dto.g.dart';

/// Startup configuration.
///
/// Stream URLs live here rather than in the binary so that a CDN change does
/// not require a store release — which is the difference between a two-hour
/// fix and a two-week one during an outage.
@JsonSerializable()
class AppConfigDto {
  const AppConfigDto({
    required this.minimumSupportedBuild,
    this.availableLocales = const ['en', 'so'],
    this.dataSaverDefault = true,
    this.featureFlags = const {},
  });

  factory AppConfigDto.fromJson(Map<String, dynamic> json) =>
      _$AppConfigDtoFromJson(json);

  /// Builds below this are asked to update before continuing.
  @JsonKey(name: 'minimum_supported_build')
  final int minimumSupportedBuild;

  @JsonKey(name: 'available_locales')
  final List<String> availableLocales;

  /// Defaults to true: most of the audience is on metered mobile data.
  @JsonKey(name: 'data_saver_default')
  final bool dataSaverDefault;

  @JsonKey(name: 'feature_flags')
  final Map<String, bool> featureFlags;

  Map<String, dynamic> toJson() => _$AppConfigDtoToJson(this);
}
