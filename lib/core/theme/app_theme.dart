import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'tokens.dart';

/// Assembles [ThemeData] from the tokens.
///
/// Elevation is capped at 0 and 1 throughout, per the canvas note: "no stacked
/// shadows, no blur layers". That is a performance decision as much as a
/// visual one — the target device is a low-end Android phone.
abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    colors: AppColors.light,
    scheme: const ColorScheme.light(
      primary: LightTokens.primary,
      onPrimary: LightTokens.onPrimary,
      secondary: LightTokens.accent,
      onSecondary: Color(0xFFFFFFFF),
      surface: LightTokens.surface,
      onSurface: LightTokens.onSurface,
      surfaceContainerLowest: LightTokens.surface,
      surfaceContainerLow: LightTokens.background,
      surfaceContainer: LightTokens.background,
      onSurfaceVariant: LightTokens.onSurfaceVariant,
      outline: LightTokens.outline,
      outlineVariant: LightTokens.outlineSubtle,
      error: LightTokens.error,
      onError: Color(0xFFFFFFFF),
      errorContainer: LightTokens.errorContainer,
      onErrorContainer: LightTokens.error,
    ),
    scaffoldBackground: LightTokens.background,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    colors: AppColors.dark,
    scheme: const ColorScheme.dark(
      primary: Color(0xFFFFFFFF),
      onPrimary: DarkTokens.surface,
      secondary: DarkTokens.accent,
      onSecondary: Color(0xFF06210F),
      surface: DarkTokens.surface,
      onSurface: DarkTokens.onSurface,
      surfaceContainerLowest: DarkTokens.background,
      surfaceContainerLow: DarkTokens.background,
      surfaceContainer: DarkTokens.surfaceRaised,
      onSurfaceVariant: DarkTokens.onSurfaceVariant,
      outline: DarkTokens.outline,
      outlineVariant: DarkTokens.outline,
      error: DarkTokens.error,
      onError: Color(0xFF3A1714),
      errorContainer: DarkTokens.errorContainer,
      onErrorContainer: DarkTokens.error,
    ),
    scaffoldBackground: DarkTokens.background,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required ColorScheme scheme,
    required Color scaffoldBackground,
  }) {
    const type = AppTypography.base;

    final textTheme = TextTheme(
      displaySmall: type.display.copyWith(color: scheme.primary),
      headlineMedium: type.headline.copyWith(color: scheme.primary),
      titleLarge: type.title.copyWith(color: scheme.primary),
      titleMedium: type.cardTitle.copyWith(color: scheme.primary),
      bodyLarge: type.bodyLarge.copyWith(color: scheme.onSurface),
      bodyMedium: type.body.copyWith(color: scheme.onSurface),
      bodySmall: type.meta.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: type.label.copyWith(color: scheme.onSurface),
      labelSmall: type.overline.copyWith(color: colors.accent),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: FontFamily.sans,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[colors, type],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: type.title.copyWith(color: scheme.primary),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineSubtle,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardBorder,
          side: BorderSide(color: colors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, kMinTapTarget),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: type.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, kMinTapTarget),
          foregroundColor: scheme.primary,
          textStyle: type.label,
          side: BorderSide(color: scheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, kMinTapTarget),
          foregroundColor: colors.linkText,
          textStyle: type.label,
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.primary,
        contentTextStyle: type.label.copyWith(color: scheme.onPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return type.overline.copyWith(
            letterSpacing: 0.2,
            fontSize: 11,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        // The canvas colours the "on" track with the accent green, not the
        // navy primary that Material 3 would pick by default.
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.accent
              : colors.outline;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackOutlineWidth: const WidgetStatePropertyAll(0),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: type.body.copyWith(color: scheme.primary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.skeleton,
      ),
    );
  }
}
