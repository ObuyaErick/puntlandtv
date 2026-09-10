import 'package:material_ui/material_ui.dart';

import '../../../core/domain/parity.dart';
import '../../../core/responsive/adaptive_layout.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/tokens.dart';

/// One column of a console table.
class ConsoleColumn {
  const ConsoleColumn({
    required this.label,
    this.width,
    this.flex = 1,
    this.alignEnd = false,
  });

  final String label;

  /// Fixed width. When null the column takes [flex] of the remaining space.
  final double? width;
  final int flex;
  final bool alignEnd;
}

/// Header strip for a [ConsoleTableRow] list.
class ConsoleTableHeader extends StatelessWidget {
  const ConsoleTableHeader({super.key, required this.columns, this.leading});

  final List<ConsoleColumn> columns;

  /// Occupies the same space as a row's leading control, so the header labels
  /// line up with the cells beneath them.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.listRhythm),
      height: 40,
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(
          top: BorderSide(color: context.colors.outline),
          left: BorderSide(color: context.colors.outline),
          right: BorderSide(color: context.colors.outline),
          bottom: BorderSide(color: context.colors.outline),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: Spacing.cardInternal),
          ],
          for (final column in columns) ...[
            _sized(
              column,
              Text(
                column.label,
                textAlign: column.alignEnd ? TextAlign.end : TextAlign.start,
                style: context.text.overline.copyWith(
                  fontSize: 10.5,
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Spacing.cardInternal),
          ],
        ],
      ),
    );
  }
}

Widget _sized(ConsoleColumn column, Widget child) => column.width != null
    ? SizedBox(width: column.width, child: child)
    : Expanded(flex: column.flex, child: child);

/// A table row with the five states from artboard 12A: default, hover,
/// selected, keyboard focus, and skeleton.
///
/// The whole row is one tab stop — tabbing through six cells per row to reach
/// the next headline makes keyboard navigation unusable in a list of 200.
class ConsoleTableRow extends StatelessWidget {
  const ConsoleTableRow({
    super.key,
    required this.columns,
    required this.cells,
    this.onTap,
    this.selected = false,
    this.leading,
    this.isLast = false,
    this.parity = Parity.even,
  });

  final List<ConsoleColumn> columns;
  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? leading;

  /// Drops the bottom divider: the card the table sits in draws that edge, and
  /// a divider on top of it reads as a doubled border.
  final bool isLast;

  /// Odd rows are striped, so an eye tracking a row across six columns does
  /// not slip onto the one below.
  final Parity parity;

  @override
  Widget build(BuildContext context) {
    assert(
      cells.length == columns.length,
      'a row must supply exactly one cell per column',
    );

    // Half a step towards the hover tint rather than the tint itself, so
    // hovering an odd row still visibly changes it.
    final stripe = switch (parity) {
      Parity.even => context.scheme.surface,
      Parity.odd => Color.lerp(
        context.scheme.surface,
        context.scheme.surfaceContainerLow,
        0.5,
      )!,
    };

    // The fill sits beneath the affordance rather than inside it: painted on
    // the row itself, it covered the hover, selected and focus states the
    // affordance draws behind its child.
    return ColoredBox(
      color: stripe,
      child: PointerAffordance(
        onTap: onTap,
        selected: selected,
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.listRhythm,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            // borderRadius: Radii.cardBorder,
            border: Border(
              left: BorderSide(color: context.colors.outline),
              right: BorderSide(color: context.colors.outline),
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: context.colors.outline),
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: Spacing.cardInternal),
              ],
              for (var i = 0; i < columns.length; i++) ...[
                _sized(
                  columns[i],
                  Align(
                    alignment: columns[i].alignEnd
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: cells[i],
                  ),
                ),
                const SizedBox(width: Spacing.cardInternal),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder shaped like a row, so the table does not jump when data
/// lands.
class ConsoleTableRowSkeleton extends StatelessWidget {
  const ConsoleTableRowSkeleton({
    super.key,
    required this.columns,
    this.parity = Parity.even,
  });

  final List<ConsoleColumn> columns;

  /// Striped like the rows it stands in for, for the same reason it is shaped
  /// like them.
  final Parity parity;

  @override
  Widget build(BuildContext context) {
    return ConsoleTableRow(
      columns: columns,
      parity: parity,
      cells: [
        for (var i = 0; i < columns.length; i++)
          Container(
            height: 12,
            width: i == 0 ? null : 60,
            decoration: BoxDecoration(
              color: context.colors.skeleton,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
