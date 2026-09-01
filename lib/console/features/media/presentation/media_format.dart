import '../../../../core/l10n/app_number_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../core/admin_api/dto/media_dto.dart';

/// Formatting the media library needs and nothing else does.
///
/// Kept out of `core/l10n` deliberately: these are two decisions about how a
/// newsroom reads a file listing, not general-purpose formatting the reader
/// app has any use for.
abstract final class MediaFormat {
  /// Bytes as kB or MB, grouped for the active language.
  ///
  /// Two units, not five. A newsroom deciding whether a hero is too heavy for
  /// a reader on a metered connection needs the difference between 800 kB and
  /// 8 MB; it does not need bytes, and it does not need a gigabyte rounded to
  /// one decimal place that hides a 400 MB difference.
  static String bytes(AppL10n l10n, int value, String languageCode) {
    const kb = 1024;
    const mb = kb * 1024;

    if (value < mb) {
      return l10n.kilobytes(
        AppNumberFormat.decimal((value / kb).round(), languageCode),
      );
    }
    return l10n.megabytes(
      AppNumberFormat.decimal((value / mb).round(), languageCode),
    );
  }

  /// Clock-style running time — `2:30`, `48:12`, `1:04:30`.
  ///
  /// Digits and colons only, so it needs no translation: this is the form a
  /// duration takes on every player either language's speakers use.
  static String duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes % 60;
    final seconds = value.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');

    return hours > 0
        ? '$hours:${two(minutes)}:${two(seconds)}'
        : '$minutes:${two(seconds)}';
  }

  /// The asset kind, in the active UI language.
  static String kind(AppL10n l10n, MediaKind kind) => switch (kind) {
    MediaKind.image => l10n.mediaKindImage,
    MediaKind.video => l10n.mediaKindVideo,
    MediaKind.audio => l10n.mediaKindAudio,
  };
}
