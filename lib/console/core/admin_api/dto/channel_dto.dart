import 'newsroom_summary_dto.dart' show RenditionDto;

/// One live channel, as the channel list shows it: what it is, and enough of
/// what it is doing to say whether a change to it is safe.
///
/// What it is broadcasting in detail — slate, renditions, ingest keys — is
/// `BroadcastControlDto`, read one channel at a time by the control room.
class ChannelDto {
  const ChannelDto({
    required this.key,
    required this.name,
    required this.position,
    required this.isPublished,
    required this.hasTv,
    required this.hasRadio,
    this.radioStreamUrl = '',
    this.radioStationName = '',
    this.radioFrequencyLabel,
    this.tvOnAir = false,
    this.radioOnAir = false,
    this.ingestPublishing = false,
    this.concurrentViewers = 0,
    this.radioListeners = 0,
    this.liveSince,
    this.onAirSince,
    this.lastFrameAt,
    this.offAirSince,
    this.radioOnAirSince,
    this.createdAt,
    this.nowPlayingTitle,
    this.nowPlayingEndsAt,
    this.hasSchedule,
    this.renditions = const [],
    this.radioStreamHealthy,
    this.neverOnAir = false,
    this.previewUrl,
  });

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  factory ChannelDto.fromJson(Map<String, dynamic> json) => ChannelDto(
    key: json['key'] as String,
    name: json['name'] as String,
    position: json['position'] as int? ?? 0,
    isPublished: json['is_published'] as bool? ?? false,
    hasTv: json['has_tv'] as bool? ?? true,
    hasRadio: json['has_radio'] as bool? ?? false,
    radioStreamUrl: json['radio_stream_url'] as String? ?? '',
    radioStationName: json['radio_station_name'] as String? ?? '',
    radioFrequencyLabel: json['radio_frequency_label'] as String?,
    tvOnAir: json['tv_on_air'] as bool? ?? false,
    radioOnAir: json['radio_on_air'] as bool? ?? false,
    ingestPublishing: json['ingest_state'] == 'publishing',
    concurrentViewers: json['concurrent_viewers'] as int? ?? 0,
    radioListeners: json['radio_listeners'] as int? ?? 0,
    liveSince: _date(json['live_since']),
    onAirSince: _date(json['on_air_since']),
    lastFrameAt: _date(json['last_frame_at']),
    offAirSince: _date(json['off_air_since']),
    radioOnAirSince: _date(json['radio_on_air_since']),
    createdAt: _date(json['created_at']),
    nowPlayingTitle: json['now_playing_title'] as String?,
    nowPlayingEndsAt: _date(json['now_playing_ends_at']),
    hasSchedule: json['has_schedule'] as bool?,
    renditions: ((json['renditions'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(RenditionDto.fromJson)
        .toList(growable: false),
    radioStreamHealthy: json['radio_stream_healthy'] as bool?,
    neverOnAir: json['never_on_air'] as bool? ?? false,
    previewUrl: json['preview_url'] as String?,
  );

  /// Permanent. It is the stream path the studio publishes to, the segment in
  /// every viewer's playlist URL, and part of every ingest credential's
  /// publish URL — so, like a category slug, it can never change.
  final String key;

  /// A proper noun, so one name rather than one per locale.
  final String name;

  final int position;

  /// Whether readers can see the channel. Off while ops set a new one up.
  final bool isPublished;

  final bool hasTv;

  /// Derived by the server from [radioStreamUrl] being set: there is no radio
  /// switch separate from the stream, so the two cannot disagree.
  final bool hasRadio;

  final String radioStreamUrl;
  final String radioStationName;

  /// "88.5 FM · Garoowe".
  final String? radioFrequencyLabel;

  final bool tvOnAir;
  final bool radioOnAir;

  /// Whether a signal is arriving at the packager right now.
  final bool ingestPublishing;

  final int concurrentViewers;
  final int radioListeners;

  // ---- What the channel list says in words ----
  //
  // Every field below is optional, and each sentence on a channel card that
  // reads one is left out while it is null rather than guessed at. They are
  // the facts the status cards describe a channel with — how long it has been
  // up, when the last frame arrived, what is on — and the server fills them
  // in as it learns to report them.

  /// When the channel went live to readers: the later of the operator's
  /// on-air switch and the signal arriving. The uptime is measured from it.
  final DateTime? liveSince;

  /// When the operator put the channel on air, signal or not. On a channel on
  /// air with no signal, this is how long it has been failing readers.
  final DateTime? onAirSince;

  /// When the last frame arrived from the encoder. On a channel on air with
  /// no signal, how long readers have been looking at a spinner.
  final DateTime? lastFrameAt;

  /// When the channel last went off air.
  final DateTime? offAirSince;

  /// When the radio went on air, for a radio station's uptime.
  final DateTime? radioOnAirSince;

  final DateTime? createdAt;

  /// The programme on now, from the channel's schedule.
  final String? nowPlayingTitle;
  final DateTime? nowPlayingEndsAt;

  /// Whether anything is programmed for the channel today. False is what
  /// "nothing scheduled" says; null says nothing.
  final bool? hasSchedule;

  /// The ladder's rungs and their health, for "all renditions healthy".
  final List<RenditionDto> renditions;

  /// Whether the radio stream is arriving at a steady bitrate.
  final bool? radioStreamHealthy;

  /// The channel has never been on air — what a new one is.
  final bool neverOnAir;

  /// A playlist the channel's preview tile can play while it is live.
  final String? previewUrl;

  /// Whether every rung is healthy. Null with no ladder to judge.
  bool? get renditionsHealthy =>
      renditions.isEmpty ? null : renditions.every((r) => r.healthy);

  /// What a reader sees: on air *and* a signal arriving.
  bool get isLiveToReaders => tvOnAir && ingestPublishing;

  /// On air, or receiving a signal — either is somebody depending on it.
  bool get tvInUse => tvOnAir || ingestPublishing;

  /// Only a channel nobody is watching or listening to can go. The server
  /// refuses the rest with [ChannelFailureCode.onAir]; this is the same rule,
  /// checked here so the button can say so before anyone presses it.
  ///
  /// It says nothing about being the last channel — that is a fact about the
  /// list, not the row, and the list checks it.
  bool get canDelete => !tvInUse && !radioOnAir;

  /// The settings half, for the edit form to start from.
  ChannelSettingsDto get settings => ChannelSettingsDto(
    name: name,
    isPublished: isPublished,
    hasTv: hasTv,
    radioStreamUrl: radioStreamUrl,
    radioStationName: radioStationName,
    radioFrequencyLabel: radioFrequencyLabel ?? '',
  );

  /// Lower-case, hyphenated, no leading or trailing hyphen — the backend's
  /// rule, which the packager's path pattern matches exactly.
  static final keyPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  static const keyMaxLength = 32;

  ChannelDto copyWith({
    int? position,
    ChannelSettingsDto? settings,
    bool? tvOnAir,
    bool? radioOnAir,
    bool? ingestPublishing,
    int? concurrentViewers,
    int? radioListeners,
  }) {
    final next = settings ?? this.settings;
    return ChannelDto(
      key: key,
      name: next.name,
      position: position ?? this.position,
      isPublished: next.isPublished,
      hasTv: next.hasTv,
      hasRadio: next.hasRadio,
      radioStreamUrl: next.radioStreamUrl,
      radioStationName: next.radioStationName,
      radioFrequencyLabel: next.radioFrequencyLabel.isEmpty
          ? null
          : next.radioFrequencyLabel,
      tvOnAir: tvOnAir ?? this.tvOnAir,
      radioOnAir: radioOnAir ?? this.radioOnAir,
      ingestPublishing: ingestPublishing ?? this.ingestPublishing,
      concurrentViewers: concurrentViewers ?? this.concurrentViewers,
      radioListeners: radioListeners ?? this.radioListeners,
      liveSince: liveSince,
      onAirSince: onAirSince,
      lastFrameAt: lastFrameAt,
      offAirSince: offAirSince,
      radioOnAirSince: radioOnAirSince,
      createdAt: createdAt,
      nowPlayingTitle: nowPlayingTitle,
      nowPlayingEndsAt: nowPlayingEndsAt,
      hasSchedule: hasSchedule,
      renditions: renditions,
      radioStreamHealthy: radioStreamHealthy,
      neverOnAir: neverOnAir,
      previewUrl: previewUrl,
    );
  }
}

/// What the channel form edits: everything about a channel except its key,
/// which is set once at creation and never again.
class ChannelSettingsDto {
  const ChannelSettingsDto({
    required this.name,
    this.isPublished = false,
    this.hasTv = true,
    this.radioStreamUrl = '',
    this.radioStationName = '',
    this.radioFrequencyLabel = '',
  });

  final String name;
  final bool isPublished;
  final bool hasTv;

  /// Set means the channel has radio; empty means it does not.
  final String radioStreamUrl;

  final String radioStationName;
  final String radioFrequencyLabel;

  bool get hasRadio => radioStreamUrl.trim().isNotEmpty;

  /// A channel with neither is nothing to show anyone — see
  /// [ChannelFailureCode.empty].
  bool get isEmpty => !hasTv && !hasRadio;

  /// The request body. Blank optional strings are left out rather than sent
  /// empty, except the two whose emptiness means something: a cleared stream
  /// URL takes radio away, and a cleared frequency removes the label.
  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'isPublished': isPublished,
    'hasTv': hasTv,
    'radioStreamUrl': radioStreamUrl.trim(),
    if (radioStationName.trim().isNotEmpty)
      'radioStationName': radioStationName.trim(),
    'radioFrequencyLabel': radioFrequencyLabel.trim(),
  };
}

/// Refusal codes for channel writes. Copied verbatim from the backend's
/// `FailureCode`.
abstract final class ChannelFailureCode {
  static const notFound = 'CHANNEL_NOT_FOUND';
  static const keyTaken = 'CHANNEL_KEY_TAKEN';

  /// Deleting, unpublishing, or taking the TV or radio away from a channel
  /// while that part is on air or still receiving a signal.
  static const onAir = 'CHANNEL_ON_AIR';

  /// Deleting the only channel.
  static const last = 'CHANNEL_LAST';

  /// A channel left with neither television nor radio.
  static const empty = 'CHANNEL_EMPTY';

  /// A reorder that did not name every channel exactly once — which means the
  /// list the console was looking at is out of date.
  static const orderMismatch = 'CHANNEL_ORDER_MISMATCH';
}
