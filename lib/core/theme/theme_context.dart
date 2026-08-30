import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Terse accessors so widgets read `context.colors.accent` rather than
/// `Theme.of(context).extension<AppColors>()!.accent`.
extension ThemeContextX on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;

  /// Semantic colours beyond the Material scheme.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// The editorial type ramp.
  AppTypography get text => Theme.of(this).extension<AppTypography>()!;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
