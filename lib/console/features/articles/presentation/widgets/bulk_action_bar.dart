import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';

/// Appears when rows are ticked, and says how many.
///
/// Bulk actions are the easiest place in the console to do something large by
/// accident, so the count is stated in words rather than left to the ticks the
/// user may have scrolled past.
class BulkActionBar extends StatelessWidget {
  const BulkActionBar({
    super.key,
    required this.count,
    required this.onPublish,
    required this.onUnpublish,
    required this.onDeselect,
    required this.onSchedule,
    required this.onChangeCategory,
  });

  final int count;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onDeselect;
  final VoidCallback onSchedule;
  final VoidCallback onChangeCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      // A full-width 52dp strip directly under the filters, per artboard 11B
      // — not a floating pill. Bulk actions apply to the table below it, and
      // the bar should read as that table's header, not as a toast.
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sectionBreak),
      color: BrandPalette.navy,
      child: Row(
        children: [
          Text(
            l10n.selectedCount(count),
            style: context.text.label.copyWith(color: Colors.white),
          ),
          const SizedBox(width: Spacing.listRhythm),
          _BarAction(
            label: l10n.bulkPublish,
            icon: Icons.check_rounded,
            onPressed: onPublish,
          ),
          _BarAction(label: l10n.bulkSchedule, onPressed: onSchedule),
          _BarAction(
            label: l10n.bulkChangeCategory,
            onPressed: onChangeCategory,
          ),
          _BarAction(
            label: l10n.bulkUnpublish,
            onPressed: onUnpublish,
            destructive: true,
          ),
          const Spacer(),
          _BarAction(label: l10n.deselectAll, onPressed: onDeselect),
        ],
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// Unpublish reads amber rather than white: it is the one action here that
  /// takes something away from readers.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive ? const Color(0xFFF0B67A) : Colors.white;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 7),
          ],
          Text(label),
        ],
      ),
    );
  }
}
