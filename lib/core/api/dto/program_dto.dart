import 'package:json_annotation/json_annotation.dart';

part 'program_dto.g.dart';

@JsonSerializable()
class ProgramDto {
  const ProgramDto({
    required this.id,
    required this.title,
    required this.episodeCount,
    this.artworkUrl,
    this.cadence,
    this.genre,
  });

  factory ProgramDto.fromJson(Map<String, dynamic> json) =>
      _$ProgramDtoFromJson(json);

  final String id;
  final String title;

  @JsonKey(name: 'episode_count')
  final int episodeCount;

  @JsonKey(name: 'artwork_url')
  final String? artworkUrl;

  /// "Daily", "Weekly" — already localised.
  final String? cadence;

  /// "News", "Debate", "Culture" — already localised.
  final String? genre;

  Map<String, dynamic> toJson() => _$ProgramDtoToJson(this);
}

@JsonSerializable()
class EpisodeDto {
  const EpisodeDto({
    required this.id,
    required this.programId,
    required this.title,
    required this.airedAt,
    required this.durationSeconds,
    required this.playbackUrl,
    this.thumbnailUrl,
  });

  factory EpisodeDto.fromJson(Map<String, dynamic> json) =>
      _$EpisodeDtoFromJson(json);

  final String id;

  @JsonKey(name: 'program_id')
  final String programId;

  final String title;

  @JsonKey(name: 'aired_at')
  final DateTime airedAt;

  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;

  /// HLS manifest or progressive MP4.
  @JsonKey(name: 'playback_url')
  final String playbackUrl;

  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;

  Map<String, dynamic> toJson() => _$EpisodeDtoToJson(this);
}
