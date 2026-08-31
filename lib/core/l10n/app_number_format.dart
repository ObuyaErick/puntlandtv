import 'package:intl/intl.dart';

/// Locale-aware number formatting that does not assume `intl` has the locale.
///
/// The same gap as dates: `intl` ships no Somali data, so
/// `NumberFormat.decimalPattern('so')` cannot be relied on. Somali groups
/// thousands with a comma like English, so the fallback is a straightforward
/// manual grouping rather than an approximation.
abstract final class AppNumberFormat {
  static bool _isSomali(String? languageCode) => languageCode == 'so';

  /// `38410` → `38,410`.
  static String decimal(int value, String languageCode) {
    if (_isSomali(languageCode)) return _group(value);
    return NumberFormat.decimalPattern(languageCode).format(value);
  }

  static String _group(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }
}
