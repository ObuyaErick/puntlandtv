/// The overview screen's numbers.
class NewsroomSummaryDto {
  const NewsroomSummaryDto({
    required this.onAir,
    required this.publishedToday,
    required this.publishedTodayByLocale,
    required this.awaitingReview,
    required this.breakingFlagged,
    required this.failedIngests,
    this.failedIngestDetail,
  });

  factory NewsroomSummaryDto.fromJson(Map<String, dynamic> json) =>
      NewsroomSummaryDto(
        onAir: OnAirDto.fromJson(json['on_air'] as Map<String, dynamic>),
        publishedToday: json['published_today'] as int,
        publishedTodayByLocale:
            (json['published_today_by_locale'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v as int),
            ),
        awaitingReview: json['awaiting_review'] as int,
        breakingFlagged: json['breaking_flagged'] as int,
        failedIngests: json['failed_ingests'] as int,
        failedIngestDetail: json['failed_ingest_detail'] as String?,
      );

  final OnAirDto onAir;
  final int publishedToday;

  /// e.g. `{so: 9, en: 5}` — the split matters, because an all-English day is
  /// a problem the count alone would hide.
  final Map<String, int> publishedTodayByLocale;

  final int awaitingReview;
  final int breakingFlagged;
  final int failedIngests;
  final String? failedIngestDetail;
}

/// Broadcast health, as shown in the overview's on-air panel.
class OnAirDto {
  const OnAirDto({
    required this.isLive,
    required this.programmeTitle,
    required this.elapsed,
    required this.renditions,
    required this.concurrentViewers,
    required this.radioOnAir,
  });

  factory OnAirDto.fromJson(Map<String, dynamic> json) => OnAirDto(
    isLive: json['is_live'] as bool,
    programmeTitle: json['programme_title'] as String,
    elapsed: Duration(seconds: json['elapsed_seconds'] as int),
    renditions: (json['renditions'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(RenditionDto.fromJson)
        .toList(growable: false),
    concurrentViewers: json['concurrent_viewers'] as int,
    radioOnAir: json['radio_on_air'] as bool,
  );

  final bool isLive;
  final String programmeTitle;
  final Duration elapsed;
  final List<RenditionDto> renditions;
  final int concurrentViewers;
  final bool radioOnAir;

  bool get allHealthy => renditions.every((r) => r.healthy);
}

class RenditionDto {
  const RenditionDto({required this.label, required this.healthy});

  factory RenditionDto.fromJson(Map<String, dynamic> json) => RenditionDto(
    label: json['label'] as String,
    healthy: json['healthy'] as bool,
  );

  /// "1080p", "720p", "240p".
  final String label;
  final bool healthy;
}
