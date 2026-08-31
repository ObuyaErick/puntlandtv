import 'package:material_ui/material_ui.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/theme/tokens.dart';

/// Labelled text field with the console's focus and error treatment.
///
/// Error text sits below the field, never as a tooltip: a tooltip disappears
/// the moment the pointer moves, and a keyboard user never sees it at all.
class ConsoleTextField extends StatelessWidget {
  const ConsoleTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = errorText != null;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.label.copyWith(color: context.scheme.primary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          autofocus: autofocus,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          enabled: enabled,
          style: context.text.body.copyWith(color: context.scheme.primary),
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            filled: true,
            fillColor: enabled
                ? context.scheme.surface
                : context.scheme.surfaceContainerLow,
            enabledBorder: border(
              hasError ? context.scheme.error : colors.outline,
            ),
            // 2px, always visible on keyboard focus — staff live on the
            // keyboard in this product.
            focusedBorder: border(
              hasError ? context.scheme.error : colors.link,
              2,
            ),
            errorBorder: border(context.scheme.error),
            focusedErrorBorder: border(context.scheme.error, 2),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: context.scheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText!,
                  style: context.text.meta.copyWith(
                    color: context.scheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A labelled row of controls, used across the console's forms.
class ConsoleField extends StatelessWidget {
  const ConsoleField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.label.copyWith(color: context.scheme.primary),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
