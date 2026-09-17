/// One channel's live radio service.
class RadioStation {
  const RadioStation({
    required this.key,
    required this.isOnAir,
    required this.streamUrl,
    required this.name,
    this.nowPlaying,
    this.frequencyLabel,
  });

  /// The channel's permanent key.
  final String key;

  /// The operator's radio switch. Off means the station is not broadcasting,
  /// whatever [streamUrl] says.
  final bool isOnAir;

  final String streamUrl;
  final String name;
  final String? nowPlaying;

  /// "Raadiyo Puntland · 88.5 FM · Garoowe"
  final String? frequencyLabel;

  /// A copy with the fields a `radio.changed` event can carry. See
  /// [LiveChannel.copyWith] — the station name and frequency label are
  /// localised chrome and are refetched, never pushed.
  RadioStation copyWith({bool? isOnAir, String? streamUrl}) => RadioStation(
    key: key,
    isOnAir: isOnAir ?? this.isOnAir,
    streamUrl: streamUrl ?? this.streamUrl,
    name: name,
    nowPlaying: nowPlaying,
    frequencyLabel: frequencyLabel,
  );
}
