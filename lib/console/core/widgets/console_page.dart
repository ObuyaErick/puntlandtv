import 'package:material_ui/material_ui.dart';

import '../../../core/responsive/window_size.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/tokens.dart';

/// Standard console page chrome: a title bar with a count and actions, then
/// content.
///
/// The actions sit top-right and the toasts bottom-left, so a confirmation
/// never covers the button that produced it.
class ConsolePage extends StatelessWidget {
  const ConsolePage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.notice,
    this.filters,
    this.onDark = false,
    this.inlineSubtitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  /// An explanatory strip under the title — used to tell a Journalist which
  /// actions are Editor-only, rather than leaving them to discover it by
  /// finding buttons missing.
  final Widget? notice;

  final Widget? filters;

  /// Renders the header on the dark ground used by live control.
  final bool onDark;

  /// Places the subtitle beside the title rather than beneath it. The overview
  /// carries a timestamp, which reads as part of the heading line.
  final bool inlineSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          title: title,
          subtitle: subtitle,
          actions: actions,
          onDark: onDark,
          inlineSubtitle: inlineSubtitle,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (notice != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.sectionBreak,
                    Spacing.gutter,
                    Spacing.sectionBreak,
                    8,
                  ),
                  child: notice,
                ),
              ?filters,
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

/// The console's fixed 68dp header.
///
/// A separate bar rather than a heading inside the scroll: the primary action
/// sits here, and an action that scrolls away is one people stop finding.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.onDark,
    required this.inlineSubtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool onDark;
  final bool inlineSubtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sectionBreak,
        vertical: Spacing.cardInternal,
      ),
      decoration: BoxDecoration(
        color: onDark ? DarkTokens.surface : context.scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: onDark ? DarkTokens.outline : context.colors.outline,
          ),
        ),
      ),
      child: WindowSizeScope(
        builder: (context, size) {
          final titleText = Text(
            title,
            style: context.text.headline.copyWith(
              fontSize: 20,
              color: onDark ? Colors.white : context.scheme.primary,
            ),
          );
          final subtitleText = subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: context.text.meta.copyWith(
                    color: onDark
                        ? DarkTokens.onSurfaceVariant
                        : context.scheme.onSurfaceVariant,
                  ),
                );

          final heading = inlineSubtitle
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleText,
                    if (subtitleText != null) ...[
                      const SizedBox(width: Spacing.listRhythm),
                      Flexible(child: subtitleText),
                    ],
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleText,
                    if (subtitleText != null) ...[
                      const SizedBox(height: 2),
                      subtitleText,
                    ],
                  ],
                );

          // Actions wrap under the title on narrow windows rather than being
          // squeezed beside it.
          if (!size.isAtLeastMedium) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: Spacing.cardInternal),
                  Wrap(spacing: Spacing.chip, children: actions),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: heading),
              for (final action in actions) ...[
                const SizedBox(width: Spacing.chip),
                action,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The strip that explains a role's limits.
class ConsoleNotice extends StatelessWidget {
  const ConsoleNotice({
    super.key,
    required this.message,
    this.icon,
    this.warning = false,
  });

  final String message;
  final IconData? icon;

  /// Amber rather than blue, for a state someone has to resolve.
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.listRhythm,
        vertical: Spacing.cardInternal,
      ),
      decoration: BoxDecoration(
        // Informational blue, per artboard 11C — a notice that explains a rule
        // should not look like the disabled-grey of something switched off.
        color: warning ? const Color(0xFFFDF6EC) : const Color(0xFFF0F7FC),
        borderRadius: Radii.cardBorder,
        border: Border.all(
          color: warning ? const Color(0xFFEEDCC0) : const Color(0xFFCBDDEC),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.info_outline_rounded,
            size: 17,
            color: warning ? const Color(0xFF8A5A00) : context.colors.linkText,
          ),
          const SizedBox(width: Spacing.cardInternal),
          Expanded(
            child: Text(
              message,
              style: context.text.meta.copyWith(
                color: warning
                    ? const Color(0xFF8A5A00)
                    : context.scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip row.
class ConsoleFilterChip extends StatelessWidget {
  const ConsoleFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? context.scheme.primary : context.scheme.surface,
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(
              color: selected ? context.scheme.primary : context.colors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.text.label.copyWith(
                  color: selected ? Colors.white : context.scheme.onSurface,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$count',
                style: context.text.label.copyWith(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.75)
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
