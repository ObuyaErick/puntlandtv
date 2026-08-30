/// Raw design tokens, transcribed from the design canvas
/// (`mockups/Puntland TV App.dc.html`, artboard 0A "Design system").
///
/// Nothing outside `core/theme` should read these directly — widgets go through
/// [AppColors]/[AppTypography] via `context.colors` / `context.text` so that a
/// token change lands in one place.
library;

import 'package:material_ui/material_ui.dart';

/// Fixed brand strings — part of the lockup, not UI copy.
abstract final class BrandLockup {
  /// The institutional tagline beneath the wordmark.
  ///
  /// Deliberately **not** localised: the canvas renders it in Somali on the
  /// English settings screen too, the same way a masthead keeps its motto in
  /// the original language. Localise it only if the broadcaster asks.
  static const tagline = 'Codka Dawladda Puntland, Soomaaliya';

  /// Shown in the About row.
  static const name = 'Puntland TV';
}

/// Brand palette. The three logo colours plus the navy ground they sit on.
abstract final class BrandPalette {
  /// Logo navy — primary surface and the app's "ground" colour.
  static const navy = Color(0xFF0A2247);

  /// Logo green. Used as-is for fills only; see [greenText] for text/badges.
  static const green = Color(0xFF1EA83C);

  /// Logo blue. Fills only; see [blueText].
  static const blue = Color(0xFF1D7EC0);
}

/// Light-theme ramp (canvas: "COLOUR — LIGHT").
abstract final class LightTokens {
  static const primary = Color(0xFF0A2247);
  static const onPrimary = Color(0xFFFFFFFF);

  /// Darkened logo green. The raw `#1EA83C` fails 4.5:1 on white, so the
  /// design system specifies this "text-safe" variant for the LIVE badge and
  /// category overlines.
  static const accent = Color(0xFF16803C);
  static const accentContainer = Color(0xFFEAF4EC);
  static const accentContainerOutline = Color(0xFFCBE6D2);
  static const onAccentContainer = Color(0xFF12602D);

  /// Blue for fills; [linkText] is the contrast-corrected version for text.
  static const link = Color(0xFF1D7EC0);
  static const linkText = Color(0xFF16609A);

  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F6F9);

  static const error = Color(0xFFC0392B);
  static const errorContainer = Color(0xFFFDF1EF);
  static const errorContainerOutline = Color(0xFFF3D3CE);

  static const onSurface = Color(0xFF3C4A63);
  static const onSurfaceVariant = Color(0xFF5A6B85);
  static const outline = Color(0xFFDDE3EC);
  static const outlineSubtle = Color(0xFFEDF0F5);
  static const skeleton = Color(0xFFE9EDF3);
  static const imagePlaceholder = Color(0xFFD3DBE7);
}

/// Dark-theme ramp (canvas: "COLOUR — DARK — default for player & radio").
abstract final class DarkTokens {
  static const background = Color(0xFF061733);
  static const surface = Color(0xFF0A2247);
  static const surfaceRaised = Color(0xFF12305C);

  static const accent = Color(0xFF3FD065);
  static const accentContainer = Color(0xFF12305C);
  static const accentContainerOutline = Color(0xFF2A4B7C);
  static const onAccentContainer = Color(0xFF3FD065);

  static const link = Color(0xFF63B6EE);
  static const linkText = Color(0xFF63B6EE);

  static const error = Color(0xFFE8705F);
  static const errorContainer = Color(0xFF3A1714);
  static const errorContainerOutline = Color(0xFF6B2A22);

  static const onSurface = Color(0xFFE6ECF5);

  /// Documented at 7.1:1 on [background] in the canvas.
  static const onSurfaceVariant = Color(0xFF93A6C4);
  static const outline = Color(0xFF1B3055);
  static const outlineStrong = Color(0xFF2A4B7C);
  static const skeleton = Color(0xFF12305C);
  static const imagePlaceholder = Color(0xFF12305C);
}

/// 4dp base scale. The canvas names each step by its job, which is worth
/// preserving — `Spacing.gutter` says more at the call site than `20`.
abstract final class Spacing {
  static const double iconToLabel = 4;
  static const double chip = 8;
  static const double cardInternal = 12;
  static const double listRhythm = 16;

  /// Screen gutter. Every scrollable's horizontal padding.
  static const double gutter = 20;
  static const double sectionBreak = 28;
  static const double emptyState = 40;
}

/// "Radius: 10 cards / 12 sheets / 999 chips" — plus 8 for buttons, taken from
/// the controls row of the canvas.
abstract final class Radii {
  static const double card = 10;
  static const double sheet = 12;
  static const double button = 8;
  static const double thumbnail = 8;
  static const double chip = 999;
  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius sheetBorder = BorderRadius.all(
    Radius.circular(sheet),
  );
  static const BorderRadius thumbBorder = BorderRadius.all(
    Radius.circular(thumbnail),
  );
}

/// Font families bundled in `assets/fonts`.
abstract final class FontFamily {
  /// Headlines and card titles. The canvas sets every serif item at 600.
  static const serif = 'SourceSerif4';

  /// Body, labels, and all UI chrome — "Plex Sans for screen legibility at
  /// low DPI", which is the whole reason for the two-family split.
  static const sans = 'IBMPlexSans';
}

/// Minimum interactive target, per the canvas ("CONTROLS — 48dp MINIMUM").
const double kMinTapTarget = 48;

/// The app-bar logo lockup reserves 188×36dp and must never scale below it.
const Size kLogoLockupSize = Size(188, 36);
