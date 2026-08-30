/// What kind of stream is playing. Determines which platform player backs it
/// and how the mini-player renders.
enum PlaybackKind {
  /// The 24/7 television channel. No seeking, no duration.
  liveTv,

  /// A catch-up episode. Seekable.
  vod,

  /// The radio service. Audio only, and the one thing that keeps playing when
  /// the app is backgrounded.
  radio,
}

/// An immutable description of something playable.
///
/// The player layer knows only this — it never sees an `Episode`, a
/// `LiveChannel` or a DTO, which is what lets the same controller serve three
/// features without depending on any of them.
class PlaybackSource {
  const PlaybackSource({
    required this.id,
    required this.url,
    required this.kind,
    required this.title,
    this.subtitle,
    this.artworkUrl,
  });

  final String id;
  final String url;
  final PlaybackKind kind;
  final String title;
  final String? subtitle;
  final String? artworkUrl;

  bool get isAudioOnly => kind == PlaybackKind.radio;
  bool get isLive => kind == PlaybackKind.liveTv || kind == PlaybackKind.radio;

  @override
  bool operator ==(Object other) =>
      other is PlaybackSource && other.id == id && other.url == url;

  @override
  int get hashCode => Object.hash(id, url);
}
