import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Semantic colours the Material [ColorScheme] has no slot for.
///
/// `ColorScheme` covers primary/surface/error well enough, but it has nothing
/// for "the LIVE badge", "a skeleton block", or "the tint behind an offline
/// chip" — and those are exactly the colours that must stay consistent across
/// the app. They live here so a screen never hard-codes a hex value.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.accentContainerOutline,
    required this.onAccentContainer,
    required this.link,
    required this.linkText,
    required this.outline,
    required this.outlineSubtle,
    required this.skeleton,
    required this.imagePlaceholder,
    required this.errorContainerOutline,
    required this.playerSurface,
    required this.onPlayerSurface,
    required this.onPlayerSurfaceVariant,
    required this.playerControlTrack,
  });

  /// The LIVE badge, category overlines, "downloaded" affordances.
  /// Contrast-corrected per theme — never [BrandPalette.green] directly.
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color accentContainerOutline;
  final Color onAccentContainer;

  /// Blue: [link] for fills, [linkText] for anything with text on top of the
  /// page background (the raw blue is short of 4.5:1 on white).
  final Color link;
  final Color linkText;

  final Color outline;
  final Color outlineSubtle;

  /// Flat block used by loading placeholders. Deliberately un-animated: the
  /// canvas specifies "NO SHIMMER — CHEAP TO PAINT", because a shimmer on
  /// every card is a real cost on the low-end devices this app targets.
  final Color skeleton;
  final Color imagePlaceholder;
  final Color errorContainerOutline;

  /// Player chrome stays dark in both themes — video and radio surfaces are
  /// always navy, so these do not flip with the theme brightness.
  final Color playerSurface;
  final Color onPlayerSurface;
  final Color onPlayerSurfaceVariant;
  final Color playerControlTrack;

  static const light = AppColors(
    accent: LightTokens.accent,
    onAccent: Color(0xFFFFFFFF),
    accentContainer: LightTokens.accentContainer,
    accentContainerOutline: LightTokens.accentContainerOutline,
    onAccentContainer: LightTokens.onAccentContainer,
    link: LightTokens.link,
    linkText: LightTokens.linkText,
    outline: LightTokens.outline,
    outlineSubtle: LightTokens.outlineSubtle,
    skeleton: LightTokens.skeleton,
    imagePlaceholder: LightTokens.imagePlaceholder,
    errorContainerOutline: LightTokens.errorContainerOutline,
    playerSurface: DarkTokens.background,
    onPlayerSurface: Color(0xFFFFFFFF),
    onPlayerSurfaceVariant: DarkTokens.onSurfaceVariant,
    playerControlTrack: DarkTokens.outlineStrong,
  );

  static const dark = AppColors(
    accent: DarkTokens.accent,
    onAccent: Color(0xFF06210F),
    accentContainer: DarkTokens.accentContainer,
    accentContainerOutline: DarkTokens.accentContainerOutline,
    onAccentContainer: DarkTokens.onAccentContainer,
    link: DarkTokens.link,
    linkText: DarkTokens.linkText,
    outline: DarkTokens.outline,
    outlineSubtle: DarkTokens.outline,
    skeleton: DarkTokens.skeleton,
    imagePlaceholder: DarkTokens.imagePlaceholder,
    errorContainerOutline: DarkTokens.errorContainerOutline,
    playerSurface: DarkTokens.background,
    onPlayerSurface: Color(0xFFFFFFFF),
    onPlayerSurfaceVariant: DarkTokens.onSurfaceVariant,
    playerControlTrack: DarkTokens.outlineStrong,
  );

  @override
  AppColors copyWith({
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? accentContainerOutline,
    Color? onAccentContainer,
    Color? link,
    Color? linkText,
    Color? outline,
    Color? outlineSubtle,
    Color? skeleton,
    Color? imagePlaceholder,
    Color? errorContainerOutline,
    Color? playerSurface,
    Color? onPlayerSurface,
    Color? onPlayerSurfaceVariant,
    Color? playerControlTrack,
  }) {
    return AppColors(
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      accentContainerOutline:
          accentContainerOutline ?? this.accentContainerOutline,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      link: link ?? this.link,
      linkText: linkText ?? this.linkText,
      outline: outline ?? this.outline,
      outlineSubtle: outlineSubtle ?? this.outlineSubtle,
      skeleton: skeleton ?? this.skeleton,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      errorContainerOutline:
          errorContainerOutline ?? this.errorContainerOutline,
      playerSurface: playerSurface ?? this.playerSurface,
      onPlayerSurface: onPlayerSurface ?? this.onPlayerSurface,
      onPlayerSurfaceVariant:
          onPlayerSurfaceVariant ?? this.onPlayerSurfaceVariant,
      playerControlTrack: playerControlTrack ?? this.playerControlTrack,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      accentContainerOutline: Color.lerp(
        accentContainerOutline,
        other.accentContainerOutline,
        t,
      )!,
      onAccentContainer: Color.lerp(
        onAccentContainer,
        other.onAccentContainer,
        t,
      )!,
      link: Color.lerp(link, other.link, t)!,
      linkText: Color.lerp(linkText, other.linkText, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineSubtle: Color.lerp(outlineSubtle, other.outlineSubtle, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
      imagePlaceholder: Color.lerp(
        imagePlaceholder,
        other.imagePlaceholder,
        t,
      )!,
      errorContainerOutline: Color.lerp(
        errorContainerOutline,
        other.errorContainerOutline,
        t,
      )!,
      playerSurface: Color.lerp(playerSurface, other.playerSurface, t)!,
      onPlayerSurface: Color.lerp(onPlayerSurface, other.onPlayerSurface, t)!,
      onPlayerSurfaceVariant: Color.lerp(
        onPlayerSurfaceVariant,
        other.onPlayerSurfaceVariant,
        t,
      )!,
      playerControlTrack: Color.lerp(
        playerControlTrack,
        other.playerControlTrack,
        t,
      )!,
    );
  }
}
