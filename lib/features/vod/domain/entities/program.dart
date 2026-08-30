/// A recurring show.
class Program {
  const Program({
    required this.id,
    required this.title,
    required this.episodeCount,
    this.artworkUrl,
    this.cadence,
    this.genre,
  });

  final String id;
  final String title;
  final int episodeCount;
  final String? artworkUrl;

  /// "Daily" / "Maalinle" — localised upstream.
  final String? cadence;

  /// "News" / "Wararka" — localised upstream.
  final String? genre;

  @override
  bool operator ==(Object other) => other is Program && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A single broadcast of a [Program], available on demand.
class Episode {
  const Episode({
    required this.id,
    required this.programId,
    required this.title,
    required this.airedAt,
    required this.duration,
    required this.playbackUrl,
    this.thumbnailUrl,
  });

  final String id;
  final String programId;
  final String title;
  final DateTime airedAt;
  final Duration duration;
  final String playbackUrl;
  final String? thumbnailUrl;

  @override
  bool operator ==(Object other) => other is Episode && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
