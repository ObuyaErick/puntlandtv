/// One entry in the broadcast schedule.
class ScheduleEntry {
  const ScheduleEntry({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.subtitle,
    this.genre,
  });

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? subtitle;
  final String? genre;

  Duration get duration => endsAt.difference(startsAt);

  bool isOnAirAt(DateTime moment) =>
      !moment.isBefore(startsAt) && moment.isBefore(endsAt);
}

/// The state of one live television channel.
///
/// Modelled so that "off air" is a first-class value rather than an error:
/// when the broadcaster stops transmitting, the app shows a branded slate,
/// never a failed player.
class LiveChannel {
  const LiveChannel({
    required this.key,
    required this.name,
    required this.isLive,
    this.streamUrl,
    this.offlineMessage,
    this.resumesAt,
    this.nowPlaying,
    this.upNext = const [],
  });

  /// Permanent — the route segment, and part of the playback source's id.
  final String key;

  /// A proper noun, the same in every locale.
  final String name;

  final bool isLive;

  /// HLS manifest. Null while off air.
  final String? streamUrl;

  /// Localised by the backend — the app has no copy of its own for this.
  final String? offlineMessage;

  final DateTime? resumesAt;
  final ScheduleEntry? nowPlaying;
  final List<ScheduleEntry> upNext;

  bool get isPlayable => isLive && (streamUrl?.isNotEmpty ?? false);

  /// A copy with the fields a `live.changed` event can carry.
  ///
  /// Only the two: going on air is the one transition whose whole payload fits
  /// in an event. Everything else about the channel — the slate, the schedule,
  /// the resume time — is localised, so it is refetched rather than pushed,
  /// and there is deliberately nothing here to set it with.
  ///
  /// `streamUrl` cannot be cleared through this, which is the right shape:
  /// going off air is a refetch, not an inline edit.
  LiveChannel copyWith({bool? isLive, String? streamUrl}) => LiveChannel(
    key: key,
    name: name,
    isLive: isLive ?? this.isLive,
    streamUrl: streamUrl ?? this.streamUrl,
    offlineMessage: offlineMessage,
    resumesAt: resumesAt,
    nowPlaying: nowPlaying,
    upNext: upNext,
  );
}
