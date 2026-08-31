import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_number_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/newsroom_summary_dto.dart';

/// Broadcast health. Navy card, radius 12, padding 22, gap 18 — per the
/// artboard, the one dark card on a light page, because it is the thing an
/// operator looks at first.
class OnAirCard extends StatelessWidget {
  const OnAirCard({super.key, required this.onAir, required this.stacked});

  final OnAirDto onAir;

  /// Preview above the text rather than beside it.
  ///
  /// Passed in rather than measured here: this card sits inside an
  /// `IntrinsicHeight` on wide layouts, and `LayoutBuilder` has no intrinsic
  /// dimensions — nesting one would break the row it lives in.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final elapsed =
        '${onAir.elapsed.inHours}h '
        '${(onAir.elapsed.inMinutes % 60).toString().padLeft(2, '0')}m';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DarkTokens.surface,
        borderRadius: BorderRadius.circular(Radii.sheet),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.onAirNow,
                  style: context.text.overline.copyWith(
                    fontSize: 11.5,
                    letterSpacing: 1.27,
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
              ),
              // Uptime lives inside the LIVE pill rather than floating at the
              // far edge: "how long have we been up" is part of "are we up".
              if (onAir.isLive) _LivePill(label: l10n.liveFor(elapsed)),
            ],
          ),
          const SizedBox(height: 18),
          // Preview beside the text where there is room, above it where there
          // is not: at 390dp a 150dp thumbnail leaves ~140dp for the column,
          // which is narrower than the buttons in it.
          Builder(
            builder: (context) {
              final preview = Container(
                width: stacked ? double.infinity : 150,
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFF04101F),
                  borderRadius: BorderRadius.circular(Radii.button),
                ),
                child: const Center(
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 22,
                    color: DarkTokens.onSurfaceVariant,
                  ),
                ),
              );

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    onAir.programmeTitle,
                    style: context.text.cardTitle.copyWith(
                      fontSize: 20,
                      height: 26 / 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: Spacing.chip),
                  Text(
                    'TV · ${onAir.renditions.map((r) => r.label).join(' / ')} '
                    '${onAir.allHealthy ? l10n.allRenditionsHealthy : l10n.renditionsDegraded}'
                    ' · ${l10n.concurrentViewers(AppNumberFormat.decimal(onAir.concurrentViewers, context.languageCode))}',
                    style: context.text.meta.copyWith(
                      fontSize: 13,
                      height: 19 / 13,
                      color: DarkTokens.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: Spacing.chip,
                    runSpacing: Spacing.chip,
                    children: [
                      _DarkButton(label: l10n.openLiveControl),
                      _DarkButton(
                        label: onAir.radioOnAir
                            ? l10n.radioOnAir
                            : l10n.radioOffAir,
                        dot: onAir.radioOnAir,
                      ),
                    ],
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [preview, const SizedBox(height: 18), details],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  preview,
                  const SizedBox(width: 18),
                  Expanded(child: details),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: LightTokens.accent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.text.overline.copyWith(
              fontSize: 10.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, this.dot = false});

  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: Colors.white,
        side: const BorderSide(color: DarkTokens.outlineStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: DarkTokens.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// A counter. The number and its detail share a baseline rather than stacking
/// — per the artboard's `align-items: baseline` row.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.listRhythm),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.text.overline.copyWith(
              fontSize: 11.5,
              letterSpacing: 1.27,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.chip),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: context.text.label.copyWith(
                  fontSize: 32,
                  height: 1,
                  color: context.scheme.primary,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    detail!,
                    style: context.text.meta.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A counter for something broken. The *card* is tinted; the number stays
/// navy, so the emphasis reads once rather than twice.
class FailureCard extends StatelessWidget {
  const FailureCard({
    super.key,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onAction,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.listRhythm),
      decoration: BoxDecoration(
        color: LightTokens.errorContainer,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: LightTokens.errorContainerOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: LightTokens.error,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: context.text.overline.copyWith(
                    fontSize: 11.5,
                    letterSpacing: 1.27,
                    color: LightTokens.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: context.text.label.copyWith(
              fontSize: 32,
              height: 1,
              color: context.scheme.primary,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 10),
            Text(
              detail!,
              style: context.text.meta.copyWith(
                height: 18 / 12.5,
                color: context.scheme.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: LightTokens.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// A white card with a 52dp titled header and a bordered body.
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.padded = true,
  });

  final String title;
  final Widget child;
  final Widget? action;

  /// False when the body draws its own rows edge to edge, as the queue does.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.outline),
      ),
      child: ClipRRect(
        borderRadius: Radii.cardBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.colors.outlineSubtle),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: context.text.label.copyWith(
                        fontSize: 14,
                        color: context.scheme.primary,
                      ),
                    ),
                  ),
                  ?action,
                ],
              ),
            ),
            Padding(
              padding: padded
                  ? const EdgeInsets.symmetric(horizontal: 18, vertical: 16)
                  : EdgeInsets.zero,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
