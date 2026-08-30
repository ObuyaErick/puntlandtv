/// The live radio service.
class RadioStation {
  const RadioStation({
    required this.streamUrl,
    required this.name,
    this.nowPlaying,
    this.frequencyLabel,
  });

  final String streamUrl;
  final String name;
  final String? nowPlaying;

  /// "Raadiyo Puntland · 88.5 FM · Garoowe"
  final String? frequencyLabel;
}
