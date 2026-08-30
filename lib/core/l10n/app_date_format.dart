import 'package:intl/intl.dart';

/// Somali month and weekday names.
///
/// `intl` 0.20 ships CLDR date symbols for 119 locales and Somali is not among
/// them — `DateFormat(..., 'so')` throws `LocaleDataException`. Rather than
/// let that surface at runtime, every date in the app goes through
/// [AppDateFormat], which routes `so` to this table and everything else to
/// `intl`.
abstract final class SomaliCalendar {
  /// Indexed 1–12 by [DateTime.month]; index 0 is unused.
  static const months = <String>[
    '',
    'Jannaayo',
    'Febraayo',
    'Maarso',
    'Abriil',
    'May',
    'Juun',
    'Luuliyo',
    'Ogosto',
    'Sebtembar',
    'Oktoobar',
    'Nofembar',
    'Diseembar',
  ];

  /// Indexed 1–12 by [DateTime.month]; index 0 is unused.
  static const shortMonths = <String>[
    '',
    'Jan',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Lul',
    'Ogo',
    'Seb',
    'Okt',
    'Nof',
    'Dis',
  ];

  /// Indexed 1–7 by [DateTime.weekday] (Monday = 1); index 0 is unused.
  static const weekdays = <String>[
    '',
    'Isniin',
    'Talaado',
    'Arbaco',
    'Khamiis',
    'Jimco',
    'Sabti',
    'Axad',
  ];

  /// Sunday-first, to match the framework's indexing of `narrowWeekdays`.
  static const narrowWeekdays = <String>['A', 'I', 'T', 'A', 'K', 'J', 'S'];
}

/// Locale-aware date formatting that does not assume `intl` has the locale.
abstract final class AppDateFormat {
  static bool _isSomali(String? languageCode) => languageCode == 'so';

  /// "30 Ogosto 2026, 08:12" / "30 Aug 2026, 08:12" — article bylines.
  static String byline(DateTime date, String languageCode) {
    final local = date.toLocal();
    if (_isSomali(languageCode)) {
      final d = local.day;
      final m = SomaliCalendar.months[local.month];
      final t = _twoDigitTime(local);
      return '$d $m ${local.year}, $t';
    }
    return DateFormat('d MMM yyyy, HH:mm', languageCode).format(local);
  }

  /// "29 Ogosto" / "29 Aug" — episode rows and schedule lines.
  static String dayMonth(DateTime date, String languageCode) {
    final local = date.toLocal();
    if (_isSomali(languageCode)) {
      return '${local.day} ${SomaliCalendar.shortMonths[local.month]}';
    }
    return DateFormat('d MMM', languageCode).format(local);
  }

  /// "Sabti, 30 Ogosto" — the lock-screen date in the canvas.
  static String weekdayDayMonth(DateTime date, String languageCode) {
    final local = date.toLocal();
    if (_isSomali(languageCode)) {
      final w = SomaliCalendar.weekdays[local.weekday];
      final m = SomaliCalendar.months[local.month];
      return '$w, ${local.day} $m';
    }
    return DateFormat('EEEE, d MMMM', languageCode).format(local);
  }

  /// 24-hour clock — used for schedule rows ("21:00 – 22:00").
  static String time(DateTime date, String languageCode) {
    final local = date.toLocal();
    if (_isSomali(languageCode)) return _twoDigitTime(local);
    return DateFormat('HH:mm', languageCode).format(local);
  }

  static String somaliMonthYear(DateTime date) =>
      '${SomaliCalendar.months[date.month]} ${date.year}';

  static String somaliMediumDate(DateTime date) =>
      '${SomaliCalendar.weekdays[date.weekday]}, '
      '${SomaliCalendar.shortMonths[date.month]} ${date.day}';

  static String somaliFullDate(DateTime date) =>
      '${SomaliCalendar.weekdays[date.weekday]}, '
      '${SomaliCalendar.months[date.month]} ${date.day}, ${date.year}';

  static String _twoDigitTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
