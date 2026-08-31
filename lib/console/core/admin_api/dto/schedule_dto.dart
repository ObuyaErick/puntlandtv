/// One programme in a day's schedule.
class ScheduleSlotDto {
  const ScheduleSlotDto({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.duration,
    this.genre,
    this.isLive = false,
    this.isRepeat = false,
  });

  factory ScheduleSlotDto.fromJson(Map<String, dynamic> json) =>
      ScheduleSlotDto(
        id: json['id'] as String,
        title: json['title'] as String,
        startsAt: DateTime.parse(json['starts_at'] as String),
        duration: Duration(minutes: json['duration_minutes'] as int),
        genre: json['genre'] as String?,
        isLive: json['is_live'] as bool? ?? false,
        isRepeat: json['is_repeat'] as bool? ?? false,
      );

  final String id;
  final String title;
  final DateTime startsAt;
  final Duration duration;
  final String? genre;
  final bool isLive;
  final bool isRepeat;

  DateTime get endsAt => startsAt.add(duration);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'starts_at': startsAt.toIso8601String(),
    'duration_minutes': duration.inMinutes,
    'genre': genre,
    'is_live': isLive,
    'is_repeat': isRepeat,
  };
}

/// What is wrong with a day's schedule.
enum ScheduleIssueKind {
  /// Dead air between two programmes. Filled by a continuity slate, so it is
  /// a warning rather than an error — but an unplanned one is usually a
  /// mistake.
  gap,

  /// Two programmes claiming the same minutes. Always an error: something
  /// will be cut and nobody has decided which.
  overlap,
}

class ScheduleIssue {
  const ScheduleIssue({
    required this.kind,
    required this.from,
    required this.to,
    required this.slotIds,
  });

  final ScheduleIssueKind kind;
  final DateTime from;
  final DateTime to;

  /// The slots involved. A gap names the two either side; an overlap names
  /// the pair that collide.
  final List<String> slotIds;

  Duration get length => to.difference(from);
}

/// A day's programming, with its problems computed rather than flagged by
/// hand.
class DayScheduleDto {
  const DayScheduleDto({required this.day, required this.slots});

  final DateTime day;
  final List<ScheduleSlotDto> slots;

  /// Slots in broadcast order.
  List<ScheduleSlotDto> get ordered =>
      [...slots]..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  /// Gaps and overlaps across the whole day.
  ///
  /// Computed from the slots every time rather than stored: a stored flag goes
  /// stale the moment someone drags a programme, and a schedule that says it
  /// is clean when it is not is worse than no check at all.
  List<ScheduleIssue> get issues {
    final rows = ordered;
    final found = <ScheduleIssue>[];

    for (var i = 0; i < rows.length - 1; i++) {
      final current = rows[i];
      final next = rows[i + 1];

      if (next.startsAt.isAfter(current.endsAt)) {
        found.add(
          ScheduleIssue(
            kind: ScheduleIssueKind.gap,
            from: current.endsAt,
            to: next.startsAt,
            slotIds: [current.id, next.id],
          ),
        );
      } else if (next.startsAt.isBefore(current.endsAt)) {
        found.add(
          ScheduleIssue(
            kind: ScheduleIssueKind.overlap,
            from: next.startsAt,
            to: current.endsAt,
            slotIds: [current.id, next.id],
          ),
        );
      }
    }

    return found;
  }

  List<ScheduleIssue> get gaps =>
      issues.where((i) => i.kind == ScheduleIssueKind.gap).toList();

  List<ScheduleIssue> get overlaps =>
      issues.where((i) => i.kind == ScheduleIssueKind.overlap).toList();

  bool get isPublishable => overlaps.isEmpty;

  Duration get programmedTime =>
      slots.fold(Duration.zero, (total, slot) => total + slot.duration);

  /// Pushes each colliding slot later until nothing overlaps.
  ///
  /// Deliberately only moves *start times* and never shortens a programme: a
  /// schedule tool that silently truncates content is one nobody trusts twice.
  DayScheduleDto resolveOverlaps() {
    final rows = ordered;
    final fixed = <ScheduleSlotDto>[];

    for (final slot in rows) {
      if (fixed.isEmpty) {
        fixed.add(slot);
        continue;
      }
      final previousEnd = fixed.last.endsAt;
      fixed.add(
        slot.startsAt.isBefore(previousEnd)
            ? ScheduleSlotDto(
                id: slot.id,
                title: slot.title,
                startsAt: previousEnd,
                duration: slot.duration,
                genre: slot.genre,
                isLive: slot.isLive,
                isRepeat: slot.isRepeat,
              )
            : slot,
      );
    }

    return DayScheduleDto(day: day, slots: fixed);
  }
}
