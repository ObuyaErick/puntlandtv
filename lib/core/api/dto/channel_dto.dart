import 'package:json_annotation/json_annotation.dart';

part 'channel_dto.g.dart';

/// One row of `GET /v1/channels`: a published channel and enough status to
/// draw its card, so the list is one request rather than one per channel.
@JsonSerializable()
class ChannelSummaryDto {
  const ChannelSummaryDto({
    required this.key,
    required this.name,
    this.hasTv = true,
    this.hasRadio = false,
    this.isLive = false,
    this.radioOnAir = false,
    this.nowPlayingTitle,
  });

  factory ChannelSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ChannelSummaryDtoFromJson(json);

  /// Permanent machine identifier, and the path segment of every per-channel
  /// route. The app keys off this, never off [name].
  final String key;

  /// A proper noun, so not localised.
  final String name;

  @JsonKey(name: 'has_tv')
  final bool hasTv;

  @JsonKey(name: 'has_radio')
  final bool hasRadio;

  /// The same fact `is_live` reports on the channel's own live route: on air
  /// *and* a signal arriving.
  @JsonKey(name: 'is_live')
  final bool isLive;

  @JsonKey(name: 'radio_on_air')
  final bool radioOnAir;

  /// From today's schedule. Null when nothing is scheduled now.
  @JsonKey(name: 'now_playing_title')
  final String? nowPlayingTitle;

  Map<String, dynamic> toJson() => _$ChannelSummaryDtoToJson(this);
}
