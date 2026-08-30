import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// The type ramp from the canvas, verbatim.
///
/// Material's own `TextTheme` slots do not map cleanly onto an editorial ramp
/// (there is no "card title in a serif" slot), so the ramp lives here as a
/// theme extension and `TextTheme` is populated from it for the widgets that
/// read it implicitly — buttons, dialogs, snackbars.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.display,
    required this.headline,
    required this.title,
    required this.cardTitle,
    required this.body,
    required this.bodyLarge,
    required this.label,
    required this.overline,
    required this.wordmark,
    required this.meta,
  });

  /// 34/38 · 600 serif — section openers ("Wararka maanta").
  final TextStyle display;

  /// 26/31 · 600 serif — the lead story and article titles.
  final TextStyle headline;

  /// 19/25 · 600 serif — section and sheet titles.
  final TextStyle title;

  /// 17/23 · 600 serif — article card headlines.
  final TextStyle cardTitle;

  /// 15.5/24 · 400 sans — body copy.
  final TextStyle body;

  /// Article reading size, one step up from [body].
  final TextStyle bodyLarge;

  /// 13/16 · 600 sans — buttons, chips, tabs.
  final TextStyle label;

  /// 11.5/14 · 600 sans, +.10em — "SIYAASADDA · 14 MIN".
  final TextStyle overline;

  /// The app-bar wordmark: 12.5 · 600, +.22em.
  final TextStyle wordmark;

  /// Timestamps and bylines.
  final TextStyle meta;

  static const _serif = FontFamily.serif;
  static const _sans = FontFamily.sans;

  static const base = AppTypography(
    display: TextStyle(
      fontFamily: _serif,
      fontSize: 34,
      height: 38 / 34,
      fontWeight: FontWeight.w600,
    ),
    headline: TextStyle(
      fontFamily: _serif,
      fontSize: 26,
      height: 31 / 26,
      fontWeight: FontWeight.w600,
    ),
    title: TextStyle(
      fontFamily: _serif,
      fontSize: 19,
      height: 25 / 19,
      fontWeight: FontWeight.w600,
    ),
    cardTitle: TextStyle(
      fontFamily: _serif,
      fontSize: 17,
      height: 23 / 17,
      fontWeight: FontWeight.w600,
    ),
    body: TextStyle(
      fontFamily: _sans,
      fontSize: 15.5,
      height: 24 / 15.5,
      fontWeight: FontWeight.w400,
    ),
    bodyLarge: TextStyle(
      fontFamily: _sans,
      fontSize: 17,
      height: 28 / 17,
      fontWeight: FontWeight.w400,
    ),
    label: TextStyle(
      fontFamily: _sans,
      fontSize: 13,
      height: 16 / 13,
      fontWeight: FontWeight.w600,
    ),
    overline: TextStyle(
      fontFamily: _sans,
      fontSize: 11.5,
      height: 14 / 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.15,
    ),
    wordmark: TextStyle(
      fontFamily: _sans,
      fontSize: 12.5,
      height: 1,
      fontWeight: FontWeight.w600,
      letterSpacing: 2.75,
    ),
    meta: TextStyle(
      fontFamily: _sans,
      fontSize: 12.5,
      height: 16 / 12.5,
      fontWeight: FontWeight.w400,
    ),
  );

  @override
  AppTypography copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? bodyLarge,
    TextStyle? label,
    TextStyle? overline,
    TextStyle? wordmark,
    TextStyle? meta,
  }) {
    return AppTypography(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      label: label ?? this.label,
      overline: overline ?? this.overline,
      wordmark: wordmark ?? this.wordmark,
      meta: meta ?? this.meta,
    );
  }

  @override
  AppTypography lerp(covariant AppTypography? other, double t) {
    if (other == null) return this;
    return AppTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      overline: TextStyle.lerp(overline, other.overline, t)!,
      wordmark: TextStyle.lerp(wordmark, other.wordmark, t)!,
      meta: TextStyle.lerp(meta, other.meta, t)!,
    );
  }
}
