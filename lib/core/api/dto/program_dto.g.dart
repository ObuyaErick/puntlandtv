// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgramDto _$ProgramDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ProgramDto',
  json,
  ($checkedConvert) {
    final val = ProgramDto(
      id: $checkedConvert('id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      episodeCount: $checkedConvert('episode_count', (v) => (v as num).toInt()),
      artworkUrl: $checkedConvert('artwork_url', (v) => v as String?),
      cadence: $checkedConvert('cadence', (v) => v as String?),
      genre: $checkedConvert('genre', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'episodeCount': 'episode_count',
    'artworkUrl': 'artwork_url',
  },
);

Map<String, dynamic> _$ProgramDtoToJson(ProgramDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'episode_count': instance.episodeCount,
      'artwork_url': instance.artworkUrl,
      'cadence': instance.cadence,
      'genre': instance.genre,
    };

EpisodeDto _$EpisodeDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'EpisodeDto',
  json,
  ($checkedConvert) {
    final val = EpisodeDto(
      id: $checkedConvert('id', (v) => v as String),
      programId: $checkedConvert('program_id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      airedAt: $checkedConvert('aired_at', (v) => DateTime.parse(v as String)),
      durationSeconds: $checkedConvert(
        'duration_seconds',
        (v) => (v as num).toInt(),
      ),
      playbackUrl: $checkedConvert('playback_url', (v) => v as String),
      thumbnailUrl: $checkedConvert('thumbnail_url', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'programId': 'program_id',
    'airedAt': 'aired_at',
    'durationSeconds': 'duration_seconds',
    'playbackUrl': 'playback_url',
    'thumbnailUrl': 'thumbnail_url',
  },
);

Map<String, dynamic> _$EpisodeDtoToJson(EpisodeDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'program_id': instance.programId,
      'title': instance.title,
      'aired_at': instance.airedAt.toIso8601String(),
      'duration_seconds': instance.durationSeconds,
      'playback_url': instance.playbackUrl,
      'thumbnail_url': instance.thumbnailUrl,
    };
