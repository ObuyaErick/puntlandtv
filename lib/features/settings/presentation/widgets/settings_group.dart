import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';

/// A card of related settings rows.
///
/// The canvas groups settings into bordered white cards rather than running
/// them as a flat list: `background:#fff · 1px solid #E3E8F0 · radius 10 ·
/// overflow:hidden`. The grouping is what makes a settings screen scannable —
/// a flat list of rows reads as undifferentiated text.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.outline),
      ),
      // Clips the row ink splashes to the card's corners.
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const _RowDivider(),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Hairline between rows, inset to start under the text rather than the icon.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  /// gutter(16) + icon(20) + gap(13)
  static const _inset = 49.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: _inset),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.colors.outlineSubtle,
      ),
    );
  }
}

/// A row with an icon, a title, an optional subtitle, and a trailing value.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;

  /// Explanatory line under the title, as on "Data saver".
  final String? subtitle;

  /// Current setting, shown under the title. Mutually exclusive with
  /// [subtitle] in practice — the canvas uses one or the other.
  final String? value;

  final VoidCallback? onTap;

  /// Replaces the chevron; a [Switch] for toggle rows.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final secondary = value ?? subtitle;

    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          // 48dp minimum target; rows with a second line grow past it.
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: context.scheme.onSurfaceVariant),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: context.scheme.primary,
                        ),
                      ),
                      if (secondary != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          secondary,
                          style: context.text.meta.copyWith(
                            color: context.scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.cardInternal),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: context.scheme.onSurfaceVariant,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A toggle row. Tapping anywhere on the row flips it, not just the switch —
/// the switch alone is a 46dp target inside a 62dp row.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: SettingsRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
        trailing: ExcludeSemantics(
          child: Switch(value: value, onChanged: onChanged),
        ),
      ),
    );
  }
}

/// Uppercase section label above a group.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.gutter + 4,
        Spacing.sectionBreak,
        Spacing.gutter,
        10,
      ),
      child: Text(
        label,
        style: context.text.overline.copyWith(
          color: context.scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
