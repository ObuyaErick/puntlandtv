import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/providers/preferences_providers.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/app_preferences.dart';

/// The language picker.
///
/// Its title is bilingual on purpose ("Luqadda · Language"): a user who has
/// the app in the language they cannot read needs to recognise this sheet
/// without being able to read the UI around it. That is the one screen where
/// showing both languages at once is right rather than sloppy.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(preferencesProvider).locale;
    final device = ref.watch(deviceLanguageCodeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.gutter,
          Spacing.gutter,
          Spacing.gutter,
          Spacing.listRhythm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.languageSheetTitle,
              style: context.text.title.copyWith(color: context.scheme.primary),
            ),
            const SizedBox(height: Spacing.gutter),
            _Option(
              label: l10n.languageSystemDefault,
              sublabel: device == 'so'
                  ? l10n.languageSomali
                  : l10n.languageEnglish,
              selected: current == LocalePreference.system,
              onTap: () => _select(context, ref, LocalePreference.system),
            ),
            _Option(
              label: l10n.languageEnglish,
              sublabel: l10n.languageEnglishSub,
              selected: current == LocalePreference.english,
              onTap: () => _select(context, ref, LocalePreference.english),
            ),
            _Option(
              label: l10n.languageSomali,
              sublabel: l10n.languageSomaliSub,
              selected: current == LocalePreference.somali,
              onTap: () => _select(context, ref, LocalePreference.somali),
            ),
            const SizedBox(height: Spacing.listRhythm),
            Text(
              l10n.languageSwitchNote,
              style: context.text.meta.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Applies immediately and closes. No confirm step: the change is instantly
  /// visible and trivially reversible, so a "Choose" button would only add a
  /// tap.
  void _select(BuildContext context, WidgetRef ref, LocalePreference value) {
    ref.read(preferencesProvider.notifier).setLocale(value);
    Navigator.of(context).pop();
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardBorder,
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.chip),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.listRhythm,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: selected ? context.colors.accentContainer : null,
            borderRadius: Radii.cardBorder,
            border: Border.all(
              color: selected
                  ? context.colors.accentContainerOutline
                  : context.colors.outline,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: context.text.meta.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: context.colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
