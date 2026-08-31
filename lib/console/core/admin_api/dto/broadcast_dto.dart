/// One quality rung of the live stream.
class RenditionConfigDto {
  const RenditionConfigDto({
    required this.rung,
    required this.url,
    required this.bitrateKbps,
    required this.healthy,
    required this.enabled,
  });

  factory RenditionConfigDto.fromJson(Map<String, dynamic> json) =>
      RenditionConfigDto(
        rung: json['rung'] as String,
        url: json['url'] as String,
        bitrateKbps: json['bitrate_kbps'] as int,
        healthy: json['healthy'] as bool,
        enabled: json['enabled'] as bool,
      );

  final String rung;
  final String url;
  final int bitrateKbps;
  final bool healthy;
  final bool enabled;

  /// The rung most of the audience actually receives.
  ///
  /// Disabling it is the single most damaging thing an operator can do from
  /// this screen: it does not break the stream, it just makes it unwatchable
  /// for everyone on a slow connection — silently, and to the people least
  /// able to report it.
  static const protectedRung = '240p';

  bool get isProtected => rung == protectedRung;

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
  );

  Map<String, dynamic> toJson() => {
    'rung': rung,
    'url': url,
    'bitrate_kbps': bitrateKbps,
    'healthy': healthy,
    'enabled': enabled,
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

  static const requiredSlateLocales = ['so', 'en'];

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

  /// The gate on taking the channel down.
  ///
  /// Going off air without a slate leaves a reader staring at a dead player;
  /// going off air with only a Somali slate does the same to everyone reading
  /// in English. Both locales, or the toggle stays on.
  bool get canGoOffAir => incompleteSlateLocales.isEmpty;

  BroadcastControlDto copyWith({
    bool? tvOnAir,
    bool? radioOnAir,
    List<RenditionConfigDto>? renditions,
    Map<String, SlateMessageDto>? slate,
  }) => BroadcastControlDto(
    tvOnAir: tvOnAir ?? this.tvOnAir,
    radioOnAir: radioOnAir ?? this.radioOnAir,
    channelName: channelName,
    uptime: uptime,
    concurrentViewers: concurrentViewers,
    radioListeners: radioListeners,
    renditions: renditions ?? this.renditions,
    slate: slate ?? this.slate,
  );

  /// Enabling and disabling rungs, with [RenditionConfigDto.protectedRung]
  /// refused outright rather than warned about.
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

  List<String> get untranslatedLocales => [
    'so',
    'en',
  ].where((locale) => !isVisibleIn(locale)).toList(growable: false);

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
