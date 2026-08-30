import 'package:json_annotation/json_annotation.dart';

part 'live_dto.g.dart';

@JsonSerializable()
class LiveStatusDto {
  const LiveStatusDto({
    required this.isLive,
    this.streamUrl,
    this.offlineMessage,
    this.resumesAt,
    this.nowPlaying,
    this.upNext = const [],
  });

  factory LiveStatusDto.fromJson(Map<String, dynamic> json) =>
      _$LiveStatusDtoFromJson(json);

  /// When false the app shows a branded slate, never a broken player.
  @JsonKey(name: 'is_live')
  final bool isLive;

  @JsonKey(name: 'stream_url')
  final String? streamUrl;

  /// Localised by the backend — the app has no copy of its own for this.
  @JsonKey(name: 'offline_message')
  final String? offlineMessage;

  @JsonKey(name: 'resumes_at')
  final DateTime? resumesAt;

  @JsonKey(name: 'now_playing')
  final ScheduleEntryDto? nowPlaying;

  @JsonKey(name: 'up_next')
  final List<ScheduleEntryDto> upNext;

  Map<String, dynamic> toJson() => _$LiveStatusDtoToJson(this);
}

@JsonSerializable()
class ScheduleEntryDto {
  const ScheduleEntryDto({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.subtitle,
    this.genre,
  });

  factory ScheduleEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduleEntryDtoFromJson(json);

  final String title;

  @JsonKey(name: 'starts_at')
  final DateTime startsAt;

  @JsonKey(name: 'ends_at')
  final DateTime endsAt;

  final String? subtitle;
  final String? genre;

  Map<String, dynamic> toJson() => _$ScheduleEntryDtoToJson(this);
}

@JsonSerializable()
class RadioStatusDto {
  const RadioStatusDto({
    required this.streamUrl,
    required this.stationName,
    this.nowPlaying,
    this.frequencyLabel,
  });

  factory RadioStatusDto.fromJson(Map<String, dynamic> json) =>
      _$RadioStatusDtoFromJson(json);

  @JsonKey(name: 'stream_url')
  final String streamUrl;

  @JsonKey(name: 'station_name')
  final String stationName;

  @JsonKey(name: 'now_playing')
  final String? nowPlaying;

  /// "88.5 FM · Garoowe"
  @JsonKey(name: 'frequency_label')
  final String? frequencyLabel;

  Map<String, dynamic> toJson() => _$RadioStatusDtoToJson(this);
}
