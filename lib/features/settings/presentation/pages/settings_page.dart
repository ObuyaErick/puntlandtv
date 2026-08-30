import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/providers/preferences_providers.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/pltv_logo.dart';
import '../../domain/entities/app_preferences.dart';
import '../widgets/language_sheet.dart';
import '../widgets/settings_group.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final controller = ref.read(preferencesProvider.notifier);
    final textScale = MediaQuery.textScalerOf(context).scale(100).round();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.emptyState),
        children: [
          SettingsSectionHeader(label: l10n.sectionGeneral),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.language_rounded,
                title: l10n.settingLanguage,
                value: switch (prefs.locale) {
                  LocalePreference.system => l10n.followSystem,
                  LocalePreference.english => l10n.languageEnglish,
                  LocalePreference.somali => l10n.languageSomali,
                },
                onTap: () => showLanguageSheet(context),
              ),
              SettingsRow(
                icon: Icons.brightness_6_outlined,
                title: l10n.settingTheme,
                value: switch (prefs.theme) {
                  ThemePreference.system => l10n.followSystem,
                  ThemePreference.light => l10n.themeLight,
                  ThemePreference.dark => l10n.themeDark,
                },
                onTap: () => _showThemeSheet(context, ref),
              ),
              // Text size follows the OS rather than offering an in-app
              // slider: one place to change it beats two that can disagree.
              // The row still opens, to say where that place is.
              SettingsRow(
                icon: Icons.format_size_rounded,
                title: l10n.settingTextSize,
                value: l10n.followSystemWithScale('$textScale%'),
                onTap: () => _showTextSizeSheet(context),
              ),
            ],
          ),

          SettingsSectionHeader(label: l10n.sectionDataPlayback),
          SettingsGroup(
            children: [
              SettingsSwitchRow(
                icon: Icons.speed_rounded,
                title: l10n.settingDataSaver,
                subtitle: l10n.settingDataSaverSub,
                value: prefs.dataSaver,
                onChanged: (v) => controller.setDataSaver(value: v),
              ),
              SettingsSwitchRow(
                icon: Icons.download_rounded,
                title: l10n.settingWifiOnlyDownloads,
                value: prefs.wifiOnlyDownloads,
                onChanged: (v) => controller.setWifiOnlyDownloads(value: v),
              ),
              SettingsSwitchRow(
                icon: Icons.notifications_outlined,
                title: l10n.settingBreakingAlerts,
                value: prefs.breakingAlerts,
                onChanged: (v) => controller.setBreakingAlerts(value: v),
              ),
            ],
          ),

          SettingsSectionHeader(label: l10n.sectionAbout),
          const _AboutCard(),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (pref, label, icon) in [
              (
                ThemePreference.system,
                l10n.followSystem,
                Icons.brightness_auto_outlined,
              ),
              (
                ThemePreference.light,
                l10n.themeLight,
                Icons.light_mode_outlined,
              ),
              (ThemePreference.dark, l10n.themeDark, Icons.dark_mode_outlined),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: ref.read(preferencesProvider).theme == pref
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: sheetContext.colors.accent,
                      )
                    : null,
                onTap: () {
                  ref.read(preferencesProvider.notifier).setTheme(pref);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showTextSizeSheet(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingTextSize,
                style: sheetContext.text.title.copyWith(
                  color: sheetContext.scheme.primary,
                ),
              ),
              const SizedBox(height: Spacing.cardInternal),
              Text(
                l10n.textSizeSheetBody,
                style: sheetContext.text.body.copyWith(
                  color: sheetContext.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The About card: the mark, the app name with its version, and the tagline.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          const PltvMark(height: 26),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.versionLine('1.0.0'),
                  style: context.text.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.scheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  BrandLockup.tagline,
                  style: context.text.meta.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
