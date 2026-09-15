// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelSummaryDto _$ChannelSummaryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ChannelSummaryDto',
      json,
      ($checkedConvert) {
        final val = ChannelSummaryDto(
          key: $checkedConvert('key', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          hasTv: $checkedConvert('has_tv', (v) => v as bool? ?? true),
          hasRadio: $checkedConvert('has_radio', (v) => v as bool? ?? false),
          isLive: $checkedConvert('is_live', (v) => v as bool? ?? false),
          radioOnAir: $checkedConvert(
            'radio_on_air',
            (v) => v as bool? ?? false,
          ),
          nowPlayingTitle: $checkedConvert(
            'now_playing_title',
            (v) => v as String?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'hasTv': 'has_tv',
        'hasRadio': 'has_radio',
        'isLive': 'is_live',
        'radioOnAir': 'radio_on_air',
        'nowPlayingTitle': 'now_playing_title',
      },
    );

Map<String, dynamic> _$ChannelSummaryDtoToJson(ChannelSummaryDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'has_tv': instance.hasTv,
      'has_radio': instance.hasRadio,
      'is_live': instance.isLive,
      'radio_on_air': instance.radioOnAir,
      'now_playing_title': instance.nowPlayingTitle,
    };
