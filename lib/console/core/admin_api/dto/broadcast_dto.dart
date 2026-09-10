/// One quality rung of the live stream.
class RenditionConfigDto {
  const RenditionConfigDto({
    required this.rung,
    required this.url,
    required this.bitrateKbps,
    required this.healthy,
    required this.enabled,
    this.isProtected = false,
  });

  factory RenditionConfigDto.fromJson(Map<String, dynamic> json) =>
      RenditionConfigDto(
        rung: json['rung'] as String,
        url: json['url'] as String,
        bitrateKbps: json['bitrate_kbps'] as int,
        healthy: json['healthy'] as bool,
        enabled: json['enabled'] as bool,
        isProtected: json['protected'] as bool? ?? false,
      );

  final String rung;
  final String url;
  final int bitrateKbps;
  final bool healthy;
  final bool enabled;

  /// The rung most of the audience actually receives, as decided by the server.
  ///
  /// Disabling it is the single most damaging thing an operator can do from
  /// this screen: it does not break the stream, it just makes it unwatchable
  /// for everyone on a slow connection — silently, and to the people least
  /// able to report it. Refused outright rather than warned about.
  ///
  /// This was a `rung == '240p'` comparison against a constant here. The
  /// server now says which rung it is, because *which* rung deserves
  /// protecting depends on the ladder: the passthrough setup publishes one
  /// rung called `source`, so a client hard-coding `240p` protected a row that
  /// does not exist and would happily offer to disable the only stream there
  /// is. Deriving it server-side also means the console cannot disagree with
  /// the refusal it is about to receive.
  final bool isProtected;

  /// `4500` → `4.5 Mbps`, `420` → `420 kbps`. Operators read the high rungs in
  /// megabits and the low one in kilobits, which is how the artboard shows it.
  String get bitrateLabel => bitrateKbps >= 1000
      ? '${(bitrateKbps / 1000).toStringAsFixed(1)} Mbps'
      : '$bitrateKbps kbps';

  RenditionConfigDto copyWith({bool? enabled}) => RenditionConfigDto(
    rung: rung,
    url: url,
    bitrateKbps: bitrateKbps,
    healthy: healthy,
    enabled: enabled ?? this.enabled,
    isProtected: isProtected,
  );

  Map<String, dynamic> toJson() => {
    'rung': rung,
    'url': url,
    'bitrate_kbps': bitrateKbps,
    'healthy': healthy,
    'enabled': enabled,
    'protected': isProtected,
  };
}

/// The off-air message, per locale.
class SlateMessageDto {
  const SlateMessageDto({this.title = '', this.detail = ''});

  factory SlateMessageDto.fromJson(Map<String, dynamic> json) =>
      SlateMessageDto(
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );

  final String title;
  final String detail;

  bool get isComplete => title.trim().isNotEmpty && detail.trim().isNotEmpty;

  SlateMessageDto copyWith({String? title, String? detail}) => SlateMessageDto(
    title: title ?? this.title,
    detail: detail ?? this.detail,
  );

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};
}

/// What the packager is doing, as distinct from what the operator wants.
///
/// The live screen shows both, because "on air but nothing arriving" and
/// "arriving but not on air" are different problems with different people to
/// call. `is_live` for a reader is the conjunction of the two.
class IngestStatusDto {
  const IngestStatusDto({
    required this.isPublishing,
    this.since,
    this.protocol,
    this.publisher,
    this.videoLabel,
    this.rtmpUrl = '',
    this.srtUrl = '',
    this.path = 'main',
  });

  factory IngestStatusDto.fromJson(Map<String, dynamic> json) =>
      IngestStatusDto(
        isPublishing: json['state'] == 'publishing',
        since: json['since'] == null
            ? null
            : DateTime.parse(json['since'] as String),
        protocol: json['protocol'] as String?,
        publisher: json['publisher'] as String?,
        videoLabel: json['video_label'] as String?,
        rtmpUrl: json['rtmp_url'] as String? ?? '',
        srtUrl: json['srt_url'] as String? ?? '',
        path: json['path'] as String? ?? 'main',
      );

  /// Whether bytes are arriving at the packager right now.
  final bool isPublishing;

  /// When the current publisher connected. Null while idle.
  final DateTime? since;

  /// `rtmp` or `srt` — which door the feed came in through. The studio has
  /// both, and the answer to "why does it look like that" often starts here.
  final String? protocol;

  /// The publisher's address, for telling the studio's encoder apart from
  /// someone's laptop.
  final String? publisher;

  /// What the source actually is, measured rather than configured: `720p
  /// H264`. Shown because an encoder quietly dropping to 360p looks identical
  /// to a healthy stream in every other indicator.
  final String? videoLabel;

  /// The endpoints to hand the studio. The stream key is deliberately not part
  /// of either: the path is public and the credential is separate.
  final String rtmpUrl;
  final String srtUrl;
  final String path;
}

/// One credential an encoder publishes with.
///
/// A list rather than a single key so a handover can overlap: the new
/// credential works before the old one is revoked, and the studio never has a
/// window with nothing valid.
class IngestKeyDto {
  const IngestKeyDto({
    required this.id,
    required this.label,
    required this.username,
    required this.createdAt,
    this.lastUsedAt,
    this.rtmpPublishUrl = '',
    this.srtPublishUrl = '',
    this.streamKey = '',
  });

  factory IngestKeyDto.fromJson(Map<String, dynamic> json) => IngestKeyDto(
    id: json['id'] as String,
    label: json['label'] as String,
    username: json['username'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    lastUsedAt: json['last_used_at'] == null
        ? null
        : DateTime.parse(json['last_used_at'] as String),
    rtmpPublishUrl: json['rtmp_publish_url'] as String? ?? '',
    srtPublishUrl: json['srt_publish_url'] as String? ?? '',
    streamKey: json['stream_key'] as String? ?? '',
  );

  final String id;

  /// Which encoder this belongs to — "Studio OBS", "Backup encoder". The whole
  /// point of a list is being able to revoke the right one, and "key 3" is not
  /// something anyone can act on at 21:40.
  final String label;

  final String username;
  final DateTime createdAt;

  /// Stamped when an encoder last authenticated with it. Null means never
  /// used, which is the fastest way to spot a studio still configured with the
  /// previous credential.
  final DateTime? lastUsedAt;

  /// Complete and ready to paste, credential included. Empty when the server
  /// has no endpoint configured for that protocol.
  ///
  /// Assembled server-side, and present on every read rather than only on the
  /// mint: the credential inside them is a signed token the server can derive
  /// again from the row, so there is nothing to show once and nothing to lose.
  final String rtmpPublishUrl;
  final String srtPublishUrl;

  /// The Stream Key half of OBS's RTMP form, which takes two fields and will
  /// not accept a whole URL in either.
  final String streamKey;

  bool get hasNeverBeenUsed => lastUsedAt == null;
}

/// Everything the live control screen governs.
class BroadcastControlDto {
  const BroadcastControlDto({
    required this.tvOnAir,
    required this.radioOnAir,
    required this.channelName,
    required this.uptime,
    required this.concurrentViewers,
    required this.radioListeners,
    required this.renditions,
    required this.slate,
    this.ingest = const IngestStatusDto(isPublishing: false),
    this.ingestKeys = const [],
  });

  factory BroadcastControlDto.fromJson(Map<String, dynamic> json) =>
      BroadcastControlDto(
        tvOnAir: json['tv_on_air'] as bool,
        radioOnAir: json['radio_on_air'] as bool,
        channelName: json['channel_name'] as String,
        uptime: Duration(seconds: json['uptime_seconds'] as int),
        concurrentViewers: json['concurrent_viewers'] as int,
        radioListeners: json['radio_listeners'] as int,
        renditions: (json['renditions'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(RenditionConfigDto.fromJson)
            .toList(growable: false),
        slate: {
          for (final entry in (json['slate'] as Map<String, dynamic>).entries)
            entry.key: SlateMessageDto.fromJson(
              entry.value as Map<String, dynamic>,
            ),
        },
        ingest: json['ingest'] == null
            ? const IngestStatusDto(isPublishing: false)
            : IngestStatusDto.fromJson(json['ingest'] as Map<String, dynamic>),
        ingestKeys: ((json['ingest_keys'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(IngestKeyDto.fromJson)
            .toList(growable: false),
      );

  final bool tvOnAir;
  final bool radioOnAir;
  final String channelName;
  final Duration uptime;
  final int concurrentViewers;
  final int radioListeners;
  final List<RenditionConfigDto> renditions;

  /// Keyed by locale. Both are required before the channel may go off air.
  final Map<String, SlateMessageDto> slate;

  final IngestStatusDto ingest;
  final List<IngestKeyDto> ingestKeys;

  static const requiredSlateLocales = ['so', 'en'];

  /// What a reader actually sees, which is the conjunction of the two facts.
  ///
  /// The operator's switch alone is not enough and never was — it just used to
  /// be the only thing the console could observe.
  bool get isLiveToReaders => tvOnAir && ingest.isPublishing;

  /// The channel is armed but no signal is arriving. Worth calling the studio
  /// about; not worth calling anyone about if the operator meant it.
  bool get isArmedWithoutSignal => tvOnAir && !ingest.isPublishing;

  /// The playlist a console preview plays.
  ///
  /// The highest-bitrate rung that is enabled and healthy — the same choice
  /// `GET /v1/live` makes for a reader, so the operator is watching what the
  /// audience is watching rather than a stream picked by different rules.
  String? get previewUrl {
    final playable =
        renditions
            .where((rendition) => rendition.enabled && rendition.healthy)
            .toList(growable: false)
          ..sort((a, b) => b.bitrateKbps.compareTo(a.bitrateKbps));
    return playable.isEmpty ? null : playable.first.url;
  }

  List<String> get incompleteSlateLocales => requiredSlateLocales
      .where((locale) => !(slate[locale]?.isComplete ?? false))
      .toList(growable: false);

  /// The slate for [locale], falling back to any other completed one.
  SlateMessageDto slateFor(String locale) {
    final own = slate[locale];
    if (own != null && own.isComplete) return own;
    for (final value in slate.values) {
      if (value.isComplete) return value;
    }
    return const SlateMessageDto();
  }

  /// The gate on the on-air switch, in **both** directions.
  ///
  /// Going off air without a slate leaves a reader staring at a dead player;
  /// going off air with only a Somali slate does the same to everyone reading
  /// in English. Both locales, or the toggle does not move.
  ///
  /// Going *on* air is gated too, which is new. While `tvOnAir` was the only
  /// thing that could take the channel down, an operator was always present at
  /// the moment the slate was needed. Now a dropped feed shows it with nobody
  /// watching, so an incomplete slate is a latent outage — and the only moment
  /// to refuse it is while somebody is still at the desk.
  bool get canToggleOnAir => incompleteSlateLocales.isEmpty;

  @Deprecated('Renamed to canToggleOnAir — the slate now gates both directions')
  bool get canGoOffAir => canToggleOnAir;

  BroadcastControlDto copyWith({
    bool? tvOnAir,
    bool? radioOnAir,
    List<RenditionConfigDto>? renditions,
    Map<String, SlateMessageDto>? slate,
    IngestStatusDto? ingest,
    List<IngestKeyDto>? ingestKeys,
  }) => BroadcastControlDto(
    tvOnAir: tvOnAir ?? this.tvOnAir,
    radioOnAir: radioOnAir ?? this.radioOnAir,
    channelName: channelName,
    uptime: uptime,
    concurrentViewers: concurrentViewers,
    radioListeners: radioListeners,
    renditions: renditions ?? this.renditions,
    slate: slate ?? this.slate,
    ingest: ingest ?? this.ingest,
    ingestKeys: ingestKeys ?? this.ingestKeys,
  );

  /// Enabling and disabling rungs, with the protected one — whichever the
  /// server says that is — refused outright rather than warned about.
  BroadcastControlDto setRenditionEnabled(
    String rung, {
    required bool enabled,
  }) {
    if (!enabled) {
      final target = renditions.firstWhere((r) => r.rung == rung);
      if (target.isProtected) return this;
    }
    return copyWith(
      renditions: [
        for (final rendition in renditions)
          rendition.rung == rung
              ? rendition.copyWith(enabled: enabled)
              : rendition,
      ],
    );
  }
}

/// A news category. The slug is permanent; the names are not.
class CategoryConfigDto {
  const CategoryConfigDto({
    required this.slug,
    required this.names,
    required this.articleCount,
    required this.order,
  });

  factory CategoryConfigDto.fromJson(Map<String, dynamic> json) =>
      CategoryConfigDto(
        slug: json['slug'] as String,
        names: (json['names'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String),
        ),
        articleCount: json['article_count'] as int,
        order: json['order'] as int,
      );

  /// Baked into app deep links and push topics, so it can never change.
  final String slug;

  /// Display name per locale. Safe to change at any time.
  final Map<String, String> names;

  final int articleCount;
  final int order;

  /// The display name for [locale], falling back to any other translation and
  /// finally to the slug.
  String nameFor(String locale) {
    final own = names[locale];
    if (own != null && own.trim().isNotEmpty) return own;
    for (final value in names.values) {
      if (value.trim().isNotEmpty) return value;
    }
    return slug;
  }

  /// Whether this category appears in a given locale's tab bar.
  ///
  /// An untranslated category is **hidden from that locale**, not shown in the
  /// other language. A Somali name in an English tab bar looks like a bug to
  /// the reader and like an oversight to the newsroom; hiding it is the honest
  /// state until someone translates it.
  bool isVisibleIn(String locale) => (names[locale] ?? '').trim().isNotEmpty;

  List<String> get untranslatedLocales =>
      locales.where((locale) => !isVisibleIn(locale)).toList(growable: false);

  /// The locales a category is named in, in the order the editor shows them.
  static const locales = ['so', 'en'];

  /// Lower-case, hyphenated, no leading/trailing hyphen — the same rule the
  /// backend enforces, checked here so the form can say so while typing.
  static final slugPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  /// Only an empty category can go. One with articles filed in it would take
  /// their share links with it — see [CategoryFailureCode.inUse].
  bool get canDelete => articleCount == 0;

  CategoryConfigDto copyWith({Map<String, String>? names, int? order}) =>
      CategoryConfigDto(
        slug: slug,
        names: names ?? this.names,
        articleCount: articleCount,
        order: order ?? this.order,
      );

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'names': names,
    'article_count': articleCount,
    'order': order,
  };
}

/// Refusal codes for category writes.
abstract final class CategoryFailureCode {
  /// Deletion attempted on a category that still has articles filed in it.
  static const inUse = 'CATEGORY_IN_USE';
}
