import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/media_dto.dart';
import '../../../../core/localised.dart';

/// One field per required locale, plus the state of the rule across them.
///
/// The two languages are stacked rather than tabbed. A tab hides the empty one,
/// and an empty field nobody can see is the exact failure the library exists to
/// prevent — the alt text that was never written because the editor only ever
/// looked at the language they were working in.
class AltTextEditor extends StatelessWidget {
  const AltTextEditor({
    super.key,
    required this.controllers,
    required this.missingLocales,
    required this.onChanged,
  });

  /// Keyed by language code, one per [MediaAssetDto.requiredAltLocales].
  final Map<String, TextEditingController> controllers;

  /// Locales still empty, recomputed by the caller as the user types so the
  /// summary below the fields is never a frame behind the fields themselves.
  final List<String> missingLocales;

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final complete = missingLocales.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final locale in MediaAssetDto.requiredAltLocales) ...[
          _AltField(
            // The language name in the *active* UI language, not the code:
            // a form label is prose like everything else in this console.
            label: l10n.altTextFor(context.languageNameOf(locale)),
            controller: controllers[locale]!,
            missing: missingLocales.contains(locale),
            onChanged: onChanged,
          ),
          const SizedBox(height: Spacing.cardInternal),
        ],
        Text(
          l10n.altTextHint,
          style: context.text.meta.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.cardInternal),
        Row(
          children: [
            Icon(
              complete
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              size: 16,
              color: complete
                  ? context.colors.onAccentContainer
                  : context.scheme.error,
            ),
            const SizedBox(width: Spacing.chip),
            Expanded(
              child: Text(
                complete
                    ? l10n.altComplete
                    : l10n.altMissingInCount(missingLocales.length),
                style: context.text.meta.copyWith(
                  color: complete
                      ? context.colors.onAccentContainer
                      : context.scheme.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A multi-line alt field.
///
/// Two lines tall rather than one: alt text that describes a picture properly
/// does not fit on one line, and a single-line box teaches people to write
/// "photo" and move on.
class _AltField extends StatelessWidget {
  const _AltField({
    required this.label,
    required this.controller,
    required this.missing,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool missing;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.text.label.copyWith(
                  color: context.scheme.primary,
                ),
              ),
            ),
            // A dot rather than the word "required": the word repeats on every
            // field and stops being read, while a mark that appears only on
            // the empty one is information.
            if (missing)
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: context.scheme.error,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          style: context.text.body.copyWith(color: context.scheme.primary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: context.scheme.surface,
            enabledBorder: border(
              missing ? context.scheme.error : colors.outline,
            ),
            focusedBorder: border(
              missing ? context.scheme.error : colors.link,
              2,
            ),
          ),
        ),
      ],
    );
  }
}
