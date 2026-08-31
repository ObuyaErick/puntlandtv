import 'package:material_ui/material_ui.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/theme/tokens.dart';

enum ToastKind { info, success, error }

/// Transient confirmation, anchored bottom-left so it never covers the
/// primary action in the toolbar at top-right.
void showConsoleToast(
  BuildContext context, {
  required String message,
  ToastKind kind = ToastKind.info,
  SnackBarAction? action,
}) {
  final colors = context.colors;
  final (background, foreground, icon) = switch (kind) {
    ToastKind.info => (
      context.scheme.primary,
      Colors.white,
      Icons.info_outline_rounded,
    ),
    ToastKind.success => (
      colors.accent,
      colors.onAccent,
      Icons.check_circle_outline_rounded,
    ),
    ToastKind.error => (
      context.scheme.error,
      Colors.white,
      Icons.error_outline_rounded,
    ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        width: 420,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
        content: Row(
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: Spacing.cardInternal),
            Expanded(
              child: Text(
                message,
                style: context.text.label.copyWith(color: foreground),
              ),
            ),
          ],
        ),
        action: action,
      ),
    );
}
