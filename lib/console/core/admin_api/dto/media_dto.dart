/// What kind of file an asset is.
///
/// The distinction is not cosmetic: it decides which rules apply. An image
/// needs alt text and nothing else; a video has to finish transcoding before
/// anyone can attach it; audio needs neither but still occupies the library.
enum MediaKind {
  image,
  video,
  audio;

  static MediaKind fromJson(String value) => MediaKind.values.firstWhere(
    (k) => k.name == value,
    orElse: () => MediaKind.image,
  );

  String toJson() => name;
}

/// Where an upload is in the ingest pipeline.
///
/// Images are [ready] the moment they land. Video is not: it is transcoded
/// into the same rungs the live stream uses, and until that finishes there is
/// nothing playable behind the thumbnail.
enum MediaProcessingState {
  ready,
  processing,
  failed;

  static MediaProcessingState fromJson(String value) =>
      MediaProcessingState.values.firstWhere(
        (s) => s.name == value,
        orElse: () => MediaProcessingState.ready,
      );

  String toJson() => name;
}

/// Which filter the library is showing.
enum MediaKindFilter {
  all,
  image,
  video,
  audio,

  /// Images missing alt text in at least one required locale. The only filter
  /// that names a problem rather than a type, and the one the screen leads
  /// with — it is the single actionable state in the library.
  needsAlt;

  /// The kind this filter narrows to, or null when it is not a kind filter.
  MediaKind? get kind => switch (this) {
    MediaKindFilter.image => MediaKind.image,
    MediaKindFilter.video => MediaKind.video,
    MediaKindFilter.audio => MediaKind.audio,
    _ => null,
  };
}

/// One place an asset is used.
///
/// Carried on the asset rather than looked up on demand because it exists to
/// answer a question asked at the moment of deletion, when a second round trip
/// is a second chance to get it wrong.
class MediaUsageDto {
  const MediaUsageDto({
    required this.articleId,
    required this.title,
    required this.isPublished,
  });

  factory MediaUsageDto.fromJson(Map<String, dynamic> json) => MediaUsageDto(
    articleId: json['article_id'] as String,
    title: json['title'] as String,
    isPublished: json['is_published'] as bool? ?? false,
  );

  final String articleId;
  final String title;

  /// A published use is the expensive one: deleting behind it breaks a page a
  /// reader can already open.
  final bool isPublished;

  Map<String, dynamic> toJson() => {
    'article_id': articleId,
    'title': title,
    'is_published': isPublished,
  };
}

/// A file in the media library.
///
/// The library carries three rules the rest of the console cannot:
///
/// 1. **Alt text is required in every locale, not once.** The article editor
///    gates publishing on an alt string existing; that is presence, not
///    completeness. An image described only in Somali reaches an English
///    reader's screen reader as Somali or as nothing, and both are the
///    bilingual promise broken at the one point where the reader cannot work
///    around it. Alt text is authored here, per language, like every other
///    piece of localised content in this product.
/// 2. **An asset in use cannot be deleted.** Removing a file three published
///    articles point at replaces three hero images with a broken box, and
///    nobody finds out until a reader does. [usedIn] is what makes the refusal
///    explainable rather than mysterious.
/// 3. **An asset that has not finished ingesting is not attachable.**
///    Attaching a video mid-transcode publishes a programme that will not
///    play.
class MediaAssetDto {
  const MediaAssetDto({
    required this.id,
    required this.kind,
    required this.filename,
    required this.url,
    required this.byteSize,
    required this.uploadedAt,
    required this.uploadedBy,
    this.thumbnailUrl,
    this.alt = const {},
    this.credit,
    this.width,
    this.height,
    this.duration,
    this.processing = MediaProcessingState.ready,
    this.transcodeProgress = 1,
    this.failureReason,
    this.usedIn = const [],
  });

  factory MediaAssetDto.fromJson(Map<String, dynamic> json) => MediaAssetDto(
    id: json['id'] as String,
    kind: MediaKind.fromJson(json['kind'] as String),
    filename: json['filename'] as String,
    url: json['url'] as String,
    byteSize: json['byte_size'] as int,
    uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    uploadedBy: json['uploaded_by'] as String,
    thumbnailUrl: json['thumbnail_url'] as String?,
    alt: {
      for (final entry
          in (json['alt'] as Map<String, dynamic>? ?? const {}).entries)
        entry.key: entry.value as String,
    },
    credit: json['credit'] as String?,
    width: json['width'] as int?,
    height: json['height'] as int?,
    duration: json['duration_seconds'] == null
        ? null
        : Duration(seconds: json['duration_seconds'] as int),
    processing: MediaProcessingState.fromJson(
      json['processing'] as String? ?? 'ready',
    ),
    transcodeProgress: (json['transcode_progress'] as num?)?.toDouble() ?? 1,
    failureReason: json['failure_reason'] as String?,
    usedIn: [
      for (final use in (json['used_in'] as List<dynamic>? ?? const []))
        MediaUsageDto.fromJson(use as Map<String, dynamic>),
    ],
  );

  final String id;
  final MediaKind kind;
  final String filename;
  final String url;

  /// Bytes on disk, shown so someone notices a 12MB hero before it ships to a
  /// reader on a metered connection.
  final int byteSize;

  final DateTime uploadedAt;
  final String uploadedBy;
  final String? thumbnailUrl;

  /// Alt text keyed by language code. Empty for a freshly uploaded image,
  /// which is exactly why an upload lands in the "needs alt text" filter.
  final Map<String, String> alt;

  /// Photographer or agency. A proper noun, so it is **not** translated —
  /// the one string on this screen that stays the same in both languages.
  final String? credit;

  final int? width;
  final int? height;
  final Duration? duration;

  final MediaProcessingState processing;

  /// 0–1. Meaningless unless [processing] is
  /// [MediaProcessingState.processing].
  final double transcodeProgress;

  final String? failureReason;
  final List<MediaUsageDto> usedIn;

  /// Locales an image must be described in before it can be published.
  ///
  /// Mirrors `PushDraftDto.requiredLocales`: the same bilingual rule, applied
  /// at the other end of the pipeline.
  static const requiredAltLocales = ['so', 'en'];

  /// Locales this image has no alt text in.
  ///
  /// Always empty for video and audio: alt text describes a still image. The
  /// equivalent for a video is a caption track, which is a Phase 6 concern.
  List<String> get missingAltLocales {
    if (kind != MediaKind.image) return const [];
    return requiredAltLocales
        .where((locale) => (alt[locale] ?? '').trim().isEmpty)
        .toList(growable: false);
  }

  bool get hasCompleteAlt => missingAltLocales.isEmpty;

  /// True when this image cannot go out with an article yet.
  ///
  /// Named for the consequence rather than the field, because that is what an
  /// editor is deciding about.
  bool get blocksPublishing => !hasCompleteAlt;

  bool get isReady => processing == MediaProcessingState.ready;

  bool get hasFailed => processing == MediaProcessingState.failed;

  /// The gate on attaching an asset to anything.
  bool get canAttach => isReady;

  int get usageCount => usedIn.length;

  bool get isInUse => usedIn.isNotEmpty;

  /// The gate on deletion. See rule 2 in the class doc.
  bool get canDelete => !isInUse;

  /// Published articles this asset appears in. Deleting behind one of these
  /// breaks a page a reader can already open, which is why the panel counts
  /// them separately from drafts.
  int get publishedUsageCount => usedIn.where((use) => use.isPublished).length;

  /// Alt text for [locale], falling back to any language that has one.
  ///
  /// A fallback is legitimate data — better than an empty announcement — but
  /// it is never treated as *the* translation: [missingAltLocales] still names
  /// the gap.
  String? altFor(String locale) {
    final exact = alt[locale];
    if (exact != null && exact.trim().isNotEmpty) return exact;
    for (final value in alt.values) {
      if (value.trim().isNotEmpty) return value;
    }
    return null;
  }

  /// Pixel dimensions, or null when the asset has none.
  String? get dimensionLabel =>
      width == null || height == null ? null : '$width × $height';

  MediaAssetDto copyWith({
    Map<String, String>? alt,
    String? credit,
    MediaProcessingState? processing,
    double? transcodeProgress,
    String? failureReason,
    List<MediaUsageDto>? usedIn,
  }) => MediaAssetDto(
    id: id,
    kind: kind,
    filename: filename,
    url: url,
    byteSize: byteSize,
    uploadedAt: uploadedAt,
    uploadedBy: uploadedBy,
    thumbnailUrl: thumbnailUrl,
    alt: alt ?? this.alt,
    credit: credit ?? this.credit,
    width: width,
    height: height,
    duration: duration,
    processing: processing ?? this.processing,
    transcodeProgress: transcodeProgress ?? this.transcodeProgress,
    // Explicitly cleared when a retry succeeds, so a stale reason cannot
    // outlive the failure it described.
    failureReason: processing == MediaProcessingState.ready
        ? null
        : (failureReason ?? this.failureReason),
    usedIn: usedIn ?? this.usedIn,
  );

  /// Sets one locale's alt text, dropping the key when it is cleared rather
  /// than storing an empty string — an empty alt is absence, not a value.
  MediaAssetDto withAlt(String locale, String text) {
    final next = {...alt};
    if (text.trim().isEmpty) {
      next.remove(locale);
    } else {
      next[locale] = text;
    }
    return copyWith(alt: next);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.toJson(),
    'filename': filename,
    'url': url,
    'byte_size': byteSize,
    'uploaded_at': uploadedAt.toIso8601String(),
    'uploaded_by': uploadedBy,
    'thumbnail_url': thumbnailUrl,
    'alt': alt,
    'credit': credit,
    'width': width,
    'height': height,
    'duration_seconds': duration?.inSeconds,
    'processing': processing.toJson(),
    'transcode_progress': transcodeProgress,
    'failure_reason': failureReason,
    'used_in': [for (final use in usedIn) use.toJson()],
  };
}

/// Counts behind the library's filter chips.
///
/// Computed from the whole library rather than the filtered view: the chips
/// have to keep showing the other totals while one of them is selected.
class MediaCounts {
  const MediaCounts({
    required this.all,
    required this.images,
    required this.videos,
    required this.audio,
    required this.needsAlt,
  });

  const MediaCounts.empty()
    : all = 0,
      images = 0,
      videos = 0,
      audio = 0,
      needsAlt = 0;

  factory MediaCounts.from(Iterable<MediaAssetDto> assets) {
    var images = 0;
    var videos = 0;
    var audio = 0;
    var needsAlt = 0;
    var all = 0;

    for (final asset in assets) {
      all++;
      switch (asset.kind) {
        case MediaKind.image:
          images++;
        case MediaKind.video:
          videos++;
        case MediaKind.audio:
          audio++;
      }
      if (asset.blocksPublishing) needsAlt++;
    }

    return MediaCounts(
      all: all,
      images: images,
      videos: videos,
      audio: audio,
      needsAlt: needsAlt,
    );
  }

  final int all;
  final int images;
  final int videos;
  final int audio;
  final int needsAlt;

  int forFilter(MediaKindFilter filter) => switch (filter) {
    MediaKindFilter.all => all,
    MediaKindFilter.image => images,
    MediaKindFilter.video => videos,
    MediaKindFilter.audio => audio,
    MediaKindFilter.needsAlt => needsAlt,
  };
}

/// Refusal reasons the admin API raises, so the UI and the boundary agree on
/// what went wrong rather than each inventing a message.
abstract final class MediaFailureCode {
  /// Deletion attempted on an asset an article still points at.
  static const inUse = 'MEDIA_ASSET_IN_USE';

  /// Attach attempted on an asset that has not finished ingesting.
  static const notReady = 'MEDIA_ASSET_NOT_READY';
}
