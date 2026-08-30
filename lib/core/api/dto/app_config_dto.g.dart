// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfigDto _$AppConfigDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AppConfigDto',
      json,
      ($checkedConvert) {
        final val = AppConfigDto(
          minimumSupportedBuild: $checkedConvert(
            'minimum_supported_build',
            (v) => (v as num).toInt(),
          ),
          availableLocales: $checkedConvert(
            'available_locales',
            (v) =>
                (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                const ['en', 'so'],
          ),
          dataSaverDefault: $checkedConvert(
            'data_saver_default',
            (v) => v as bool? ?? true,
          ),
          featureFlags: $checkedConvert(
            'feature_flags',
            (v) =>
                (v as Map<String, dynamic>?)?.map(
                  (k, e) => MapEntry(k, e as bool),
                ) ??
                const {},
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'minimumSupportedBuild': 'minimum_supported_build',
        'availableLocales': 'available_locales',
        'dataSaverDefault': 'data_saver_default',
        'featureFlags': 'feature_flags',
      },
    );

Map<String, dynamic> _$AppConfigDtoToJson(AppConfigDto instance) =>
    <String, dynamic>{
      'minimum_supported_build': instance.minimumSupportedBuild,
      'available_locales': instance.availableLocales,
      'data_saver_default': instance.dataSaverDefault,
      'feature_flags': instance.featureFlags,
    };
