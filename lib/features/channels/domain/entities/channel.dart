/// The two things a channel can carry. A channel list is always a list of one
/// of them: the Live TV tab lists television, the Radio tab lists radio.
enum ChannelMedium { tv, radio }

/// One published channel as the reader's channel list shows it.
///
/// A channel is a television feed, a radio station, or both, under one
/// permanent [key]. The list carries enough status to draw every card from one
/// request; opening a channel fetches the rest.
class Channel {
  const Channel({
    required this.key,
    required this.name,
    required this.hasTv,
    required this.hasRadio,
    this.isLive = false,
    this.radioOnAir = false,
    this.nowPlayingTitle,
  });

  /// Permanent. It is the route segment and the API path, so it never changes
  /// under a bookmark or a push deep-link.
  final String key;

  /// A proper noun — the same in every locale.
  final String name;

  final bool hasTv;
  final bool hasRadio;

  /// Television is on air and a signal is arriving.
  final bool isLive;

  final bool radioOnAir;

  /// The programme on television now, from today's schedule.
  final String? nowPlayingTitle;

  bool carries(ChannelMedium medium) => switch (medium) {
    ChannelMedium.tv => hasTv,
    ChannelMedium.radio => hasRadio,
  };

  /// Whether [medium] is on right now.
  bool isOnAir(ChannelMedium medium) => switch (medium) {
    ChannelMedium.tv => isLive,
    ChannelMedium.radio => radioOnAir,
  };
}
