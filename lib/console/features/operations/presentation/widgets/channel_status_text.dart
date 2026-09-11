import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../core/admin_api/dto/channel_dto.dart';

/// What a channel card is drawing, which decides its colour, its preview tile
/// and every sentence on it.
///
/// Ordered by how loud the card is, not alphabetically: [noSignal] is the one
/// alarm on the page, [live] and [radioOnAir] are the reassuring states, and
/// [offAir] and [hidden] are deliberately quiet — off air is a normal state,
/// and nothing about it is red.
enum ChannelCardState {
  /// On air, and nothing is arriving: readers are looking at a spinner.
  noSignal,

  /// On air with a signal: what readers are watching.
  live,

  /// A radio-only station that is on air.
  radioOnAir,

  /// Not published: being set up, invisible to readers.
  hidden,

  /// Published, and not on air.
  offAir;

  static ChannelCardState of(ChannelDto channel) {
    if (channel.hasTv && channel.tvOnAir && !channel.ingestPublishing) {
      return noSignal;
    }
    if (channel.hasTv && channel.isLiveToReaders) return live;
    if (!channel.hasTv && channel.radioOnAir) return radioOnAir;
    if (!channel.isPublished) return hidden;
    return offAir;
  }
}

/// The words a channel card says about time, in the operator's language.
///
/// One place for the arithmetic, so the navy band's "on air for 12m", the
/// card's "no frames for 3m 12s" and the pill's "2h 04m" are the same clock
/// read the same way.
class ChannelStatusText {
  const ChannelStatusText(this.l10n, this.languageCode, this.now);

  final AppL10n l10n;
  final String languageCode;
  final DateTime now;

  /// Uptime-style: "2h 04m" from an hour up, "3m 12s" below it.
  String duration(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    if (safe.inHours >= 1) {
      return l10n.durationHoursMinutes(
        safe.inHours,
        (safe.inMinutes % 60).toString().padLeft(2, '0'),
      );
    }
    return l10n.durationMinutesSeconds(
      safe.inMinutes,
      (safe.inSeconds % 60).toString().padLeft(2, '0'),
    );
  }

  /// "12m": how long something has been going on, to the minute.
  String minutes(Duration value) =>
      l10n.durationMinutesCompact(value.isNegative ? 0 : value.inMinutes);

  /// "8 minutes", "3 hours", "2 days": how long ago something happened.
  String age(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    if (safe.inDays >= 1) return l10n.ageDays(safe.inDays);
    if (safe.inHours >= 1) return l10n.ageHours(safe.inHours);
    return l10n.ageMinutes(safe.inMinutes < 1 ? 1 : safe.inMinutes);
  }

  /// Time since [from], or null when [from] is not known.
  Duration? since(DateTime? from) => from == null ? null : now.difference(from);

  /// "19:04" today, "yesterday 23:40", or a date and time further back.
  String when(DateTime at) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final time = AppDateFormat.time(at, languageCode);
    if (day == today) return time;
    if (day == today.subtract(const Duration(days: 1))) {
      return l10n.yesterdayAt(time);
    }
    return '${AppDateFormat.dayMonth(at, languageCode)} $time';
  }

  /// "19:13:48": a clock time to the second, for "last frame".
  String clock(DateTime at) =>
      '${AppDateFormat.time(at, languageCode)}:'
      '${at.second.toString().padLeft(2, '0')}';
}
