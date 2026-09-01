import 'media_dto.dart';

/// How often a programme goes out.
///
/// A machine value, not the localised string the reader app receives. The app
/// fixtures carry `"Daily"` and `"Maalinle"` as prose because the app only
/// displays them; the console has to *set* them, and a dropdown of translated
/// strings is a dropdown that means something different in each language.
/// Same lesson as the category slug: the identifier is stable, the words are
/// per-locale and resolved at render.
enum ProgramCadence {
  daily,
  weekly,
  monthly,

  /// Specials and one-offs — no fixed slot.
  occasional;

  static ProgramCadence fromJson(String value) => ProgramCadence.values
      .firstWhere((c) => c.name == value, orElse: () => ProgramCadence.weekly);

  String toJson() => name;
}

/// Programme genre, as a machine value for the same reason as [ProgramCadence].
///
/// Deliberately not the news category taxonomy: a category answers "where does
/// this article file", a genre answers "what kind of programme is this", and
/// the two lists diverge the moment anyone adds "Kids".
enum ProgramGenre {
  news,
  debate,
  culture,
  kids,
  sport,
  religion;

  static ProgramGenre fromJson(String value) => ProgramGenre.values.firstWhere(
    (g) => g.name == value,
    orElse: () => ProgramGenre.news,
  );

  String toJson() => name;
}

/// Where an episode is in its own lifecycle.
enum EpisodeStatus {
  draft,
  scheduled,
  published;

  static EpisodeStatus fromJson(String value) => EpisodeStatus.values
      .firstWhere((s) => s.name == value, orElse: () => EpisodeStatus.draft);

  String toJson() => name;
}

/// A VOD programme as the console sees it: every locale's title at once.
///
/// The reader app gets one locale per request and cannot tell a missing Somali
/// title from a programme that does not exist. The console can, and has to —
/// **an untitled locale hides the programme from that locale's audience**,
/// exactly as an untranslated category is hidden from its tab bar. Falling
/// back to English on a Somali shelf would put a language the majority of the
/// audience does not read in front of them and call it content.
class AdminProgramDto {
  const AdminProgramDto({
    required this.id,
    required this.titles,
    required this.cadence,
    required this.genre,
    required this.episodeCount,
    required this.updatedAt,
    this.artworkUrl,
    this.synopses = const {},
    this.isPublished = false,
  });

  factory AdminProgramDto.fromJson(Map<String, dynamic> json) =>
      AdminProgramDto(
        id: json['id'] as String,
        titles: (json['titles'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String),
        ),
        cadence: ProgramCadence.fromJson(json['cadence'] as String),
        genre: ProgramGenre.fromJson(json['genre'] as String),
        episodeCount: json['episode_count'] as int,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        artworkUrl: json['artwork_url'] as String?,
        synopses: (json['synopses'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, v as String),
        ),
        isPublished: json['is_published'] as bool? ?? false,
      );

  /// Also the app's programme slug, so it is baked into deep links and cannot
  /// change once anything has shipped.
  final String id;

  /// Show name per locale.
  final Map<String, String> titles;

  final ProgramCadence cadence;
  final ProgramGenre genre;

  /// Total episodes, published or not. The count the *app* shows is
  /// [publishedEpisodeCount], which is a different number and deliberately so.
  final int episodeCount;

  final DateTime updatedAt;
  final String? artworkUrl;
  final Map<String, String> synopses;
  final bool isPublished;

  /// Locales a programme must be titled in before its shelf is complete.
  static const requiredLocales = ['so', 'en'];

  String titleFor(String locale) {
    final own = titles[locale];
    if (own != null && own.trim().isNotEmpty) return own;
    for (final value in titles.values) {
      if (value.trim().isNotEmpty) return value;
    }
    return id;
  }

  String? synopsisFor(String locale) {
    final own = synopses[locale];
    return own == null || own.trim().isEmpty ? null : own;
  }

  /// Locales with no title.
  List<String> get untitledLocales => requiredLocales
      .where((locale) => (titles[locale] ?? '').trim().isEmpty)
      .toList(growable: false);

  /// Whether this programme appears on a given locale's shelf.
  ///
  /// See the class doc: an untitled locale hides the programme rather than
  /// showing it in the other language.
  bool isVisibleIn(String locale) => (titles[locale] ?? '').trim().isNotEmpty;

  /// True when the programme is live in at least one locale but not all of
  /// them — the state that needs someone's attention, as opposed to a draft
  /// nobody has finished yet.
  bool get isPartiallyVisible =>
      isPublished &&
      untitledLocales.isNotEmpty &&
      untitledLocales.length < requiredLocales.length;

  AdminProgramDto copyWith({
    Map<String, String>? titles,
    ProgramCadence? cadence,
    ProgramGenre? genre,
    int? episodeCount,
    String? artworkUrl,
    Map<String, String>? synopses,
    bool? isPublished,
  }) => AdminProgramDto(
    id: id,
    titles: titles ?? this.titles,
    cadence: cadence ?? this.cadence,
    genre: genre ?? this.genre,
    episodeCount: episodeCount ?? this.episodeCount,
    updatedAt: DateTime.now(),
    artworkUrl: artworkUrl ?? this.artworkUrl,
    synopses: synopses ?? this.synopses,
    isPublished: isPublished ?? this.isPublished,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titles': titles,
    'cadence': cadence.toJson(),
    'genre': genre.toJson(),
    'episode_count': episodeCount,
    'updated_at': updatedAt.toIso8601String(),
    'artwork_url': artworkUrl,
    'synopses': synopses,
    'is_published': isPublished,
  };
}

/// One episode.
///
/// The rule this type exists to carry: **an episode cannot be published on a
/// source that is not playable yet.** [source] is the media library asset the
/// episode plays, carried whole rather than as an id, so the ingest state that
/// decides publishability is the same object the library screen shows — one
/// asset, one truth about whether it is ready. Publishing an episode whose
/// transcode is at 62% ships a programme that opens to an error, and the
/// audience finds out before the newsroom does.
class AdminEpisodeDto {
  const AdminEpisodeDto({
    required this.id,
    required this.programId,
    required this.titles,
    required this.number,
    required this.status,
    required this.duration,
    this.source,
    this.airedAt,
    this.scheduledFor,
  });

  factory AdminEpisodeDto.fromJson(Map<String, dynamic> json) =>
      AdminEpisodeDto(
        id: json['id'] as String,
        programId: json['program_id'] as String,
        titles: (json['titles'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String),
        ),
        number: json['number'] as int,
        status: EpisodeStatus.fromJson(json['status'] as String),
        duration: Duration(seconds: json['duration_seconds'] as int),
        source: json['source'] == null
            ? null
            : MediaAssetDto.fromJson(json['source'] as Map<String, dynamic>),
        airedAt: json['aired_at'] == null
            ? null
            : DateTime.parse(json['aired_at'] as String),
        scheduledFor: json['scheduled_for'] == null
            ? null
            : DateTime.parse(json['scheduled_for'] as String),
      );

  final String id;
  final String programId;
  final Map<String, String> titles;

  /// Episode number within the programme. What the newsroom calls it.
  final int number;

  final EpisodeStatus status;
  final Duration duration;

  /// The media library asset this episode plays. Null means nothing has been
  /// attached yet, which is a different problem from an attached asset that is
  /// still transcoding — and the screen says which.
  final MediaAssetDto? source;

  final DateTime? airedAt;
  final DateTime? scheduledFor;

  static const requiredLocales = AdminProgramDto.requiredLocales;

  String titleFor(String locale) {
    final own = titles[locale];
    if (own != null && own.trim().isNotEmpty) return own;
    for (final value in titles.values) {
      if (value.trim().isNotEmpty) return value;
    }
    return '$number';
  }

  List<String> get untitledLocales => requiredLocales
      .where((locale) => (titles[locale] ?? '').trim().isEmpty)
      .toList(growable: false);

  /// True when no video is attached at all.
  bool get hasNoSource => source == null;

  /// True when a video is attached but the pipeline has not finished with it.
  bool get isSourceProcessing => source != null && !source!.isReady;

  bool get hasSourceFailed => source?.hasFailed ?? false;

  /// Everything standing between this episode and the app, in the order a
  /// person would fix them.
  ///
  /// A list rather than a bool because "cannot publish" is useless on its own:
  /// the screen has to say which of the three reasons applies, and there can
  /// be more than one.
  List<EpisodeBlocker> get blockers => [
    if (hasNoSource)
      EpisodeBlocker.noSource
    else if (hasSourceFailed)
      EpisodeBlocker.sourceFailed
    else if (isSourceProcessing)
      EpisodeBlocker.sourceProcessing,
    if (untitledLocales.isNotEmpty) EpisodeBlocker.untitled,
  ];

  /// The single gate on publishing an episode.
  bool get canPublish => blockers.isEmpty;

  bool get isPublished => status == EpisodeStatus.published;

  AdminEpisodeDto copyWith({
    Map<String, String>? titles,
    EpisodeStatus? status,
    MediaAssetDto? source,
    DateTime? airedAt,
    DateTime? scheduledFor,
  }) => AdminEpisodeDto(
    id: id,
    programId: programId,
    titles: titles ?? this.titles,
    number: number,
    status: status ?? this.status,
    duration: duration,
    source: source ?? this.source,
    airedAt: airedAt ?? this.airedAt,
    scheduledFor: scheduledFor ?? this.scheduledFor,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'program_id': programId,
    'titles': titles,
    'number': number,
    'status': status.toJson(),
    'duration_seconds': duration.inSeconds,
    'source': source?.toJson(),
    'aired_at': airedAt?.toIso8601String(),
    'scheduled_for': scheduledFor?.toIso8601String(),
  };
}

/// Why an episode cannot go out.
enum EpisodeBlocker {
  /// No video attached.
  noSource,

  /// Attached, but the transcode failed. Needs a retry in the media library.
  sourceFailed,

  /// Attached and still transcoding. Needs time, not a decision.
  sourceProcessing,

  /// Missing a title in at least one required locale.
  untitled,
}

/// Refusal codes the admin API raises for programmes and episodes.
abstract final class ProgramFailureCode {
  /// Publish attempted on an episode with an outstanding blocker.
  static const episodeBlocked = 'EPISODE_NOT_PUBLISHABLE';
}
