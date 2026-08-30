// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveStatusDto _$LiveStatusDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LiveStatusDto',
      json,
      ($checkedConvert) {
        final val = LiveStatusDto(
          isLive: $checkedConvert('is_live', (v) => v as bool),
          streamUrl: $checkedConvert('stream_url', (v) => v as String?),
          offlineMessage: $checkedConvert(
            'offline_message',
            (v) => v as String?,
          ),
          resumesAt: $checkedConvert(
            'resumes_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          nowPlaying: $checkedConvert(
            'now_playing',
            (v) => v == null
                ? null
                : ScheduleEntryDto.fromJson(v as Map<String, dynamic>),
          ),
          upNext: $checkedConvert(
            'up_next',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) =>
                          ScheduleEntryDto.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'isLive': 'is_live',
        'streamUrl': 'stream_url',
        'offlineMessage': 'offline_message',
        'resumesAt': 'resumes_at',
        'nowPlaying': 'now_playing',
        'upNext': 'up_next',
      },
    );

Map<String, dynamic> _$LiveStatusDtoToJson(LiveStatusDto instance) =>
    <String, dynamic>{
      'is_live': instance.isLive,
      'stream_url': instance.streamUrl,
      'offline_message': instance.offlineMessage,
      'resumes_at': instance.resumesAt?.toIso8601String(),
      'now_playing': instance.nowPlaying,
      'up_next': instance.upNext,
    };

ScheduleEntryDto _$ScheduleEntryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ScheduleEntryDto', json, ($checkedConvert) {
      final val = ScheduleEntryDto(
        title: $checkedConvert('title', (v) => v as String),
        startsAt: $checkedConvert(
          'starts_at',
          (v) => DateTime.parse(v as String),
        ),
        endsAt: $checkedConvert('ends_at', (v) => DateTime.parse(v as String)),
        subtitle: $checkedConvert('subtitle', (v) => v as String?),
        genre: $checkedConvert('genre', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'startsAt': 'starts_at', 'endsAt': 'ends_at'});

Map<String, dynamic> _$ScheduleEntryDtoToJson(ScheduleEntryDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'starts_at': instance.startsAt.toIso8601String(),
      'ends_at': instance.endsAt.toIso8601String(),
      'subtitle': instance.subtitle,
      'genre': instance.genre,
    };

RadioStatusDto _$RadioStatusDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RadioStatusDto',
      json,
      ($checkedConvert) {
        final val = RadioStatusDto(
          streamUrl: $checkedConvert('stream_url', (v) => v as String),
          stationName: $checkedConvert('station_name', (v) => v as String),
          nowPlaying: $checkedConvert('now_playing', (v) => v as String?),
          frequencyLabel: $checkedConvert(
            'frequency_label',
            (v) => v as String?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'streamUrl': 'stream_url',
        'stationName': 'station_name',
        'nowPlaying': 'now_playing',
        'frequencyLabel': 'frequency_label',
      },
    );

Map<String, dynamic> _$RadioStatusDtoToJson(RadioStatusDto instance) =>
    <String, dynamic>{
      'stream_url': instance.streamUrl,
      'station_name': instance.stationName,
      'now_playing': instance.nowPlaying,
      'frequency_label': instance.frequencyLabel,
    };
