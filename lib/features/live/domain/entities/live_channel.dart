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

/// The state of the live television channel.
///
/// Modelled so that "off air" is a first-class value rather than an error:
/// when the broadcaster stops transmitting, the app shows a branded slate,
/// never a failed player.
class LiveChannel {
  const LiveChannel({
    required this.isLive,
    this.streamUrl,
    this.offlineMessage,
    this.resumesAt,
    this.nowPlaying,
    this.upNext = const [],
  });

  final bool isLive;

  /// HLS manifest. Null while off air.
  final String? streamUrl;

  /// Localised by the backend — the app has no copy of its own for this.
  final String? offlineMessage;

  final DateTime? resumesAt;
  final ScheduleEntry? nowPlaying;
  final List<ScheduleEntry> upNext;

  bool get isPlayable => isLive && (streamUrl?.isNotEmpty ?? false);
}
