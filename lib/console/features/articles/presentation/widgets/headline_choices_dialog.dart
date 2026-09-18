import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';

/// Offers the suggested headlines and answers the one that was picked.
///
/// Null when the editor closed it without choosing, which is a normal outcome
/// and not an error: "none of these is better than mine" is the answer this
/// dialog most often gets, and it should cost one press to give.
Future<String?> showHeadlineChoices(
  BuildContext context, {
  required List<String> headlines,
  required String current,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _HeadlineChoicesDialog(headlines: headlines, current: current),
);

/// A list of alternatives, with the headline already written shown first for
/// comparison.
///
/// Plural by design. A single suggestion is a replacement an editor either
/// takes or does not, which turns a writing decision into a yes/no about
/// someone else's sentence; several are a choice, which is what a person
/// actually wants when they ask for help with a headline. Showing the current
/// one alongside them is part of the same idea — the real question is "is any
/// of these better than what I have", and that is unanswerable if what you have
/// is off-screen.
class _HeadlineChoicesDialog extends StatelessWidget {
  const _HeadlineChoicesDialog({
    required this.headlines,
    required this.current,
  });

  final List<String> headlines;
  final String current;

  static const _limit = 120;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.aiHeadlinesTitle),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (current.trim().isNotEmpty) ...[
              _Current(text: current),
              const SizedBox(height: Spacing.cardInternal),
            ],
            for (final headline in headlines) ...[
              _Choice(
                text: headline,
                overLimit: headline.length > _limit,
                onPressed: () => Navigator.of(context).pop(headline),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.aiDiscard),
        ),
      ],
    );
  }
}

class _Current extends StatelessWidget {
  const _Current({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Spacing.cardInternal),
    decoration: BoxDecoration(
      color: context.scheme.surfaceContainerHighest,
      borderRadius: Radii.cardBorder,
    ),
    child: Text(
      text,
      style: context.text.body.copyWith(color: context.scheme.onSurfaceVariant),
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.text,
    required this.overLimit,
    required this.onPressed,
  });

  final String text;

  /// The 120-character guidance the composer's counter uses. Shown, never
  /// enforced — a good 124-character headline beats a bad 118-character one,
  /// which is why the composer does not block publishing on it either.
  final bool overLimit;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.all(Spacing.cardInternal),
      side: BorderSide(color: context.colors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: context.text.body.copyWith(color: context.scheme.primary),
        ),
        if (overLimit) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.charCount(text.length, 120),
            style: context.text.meta.copyWith(color: context.scheme.error),
          ),
        ],
      ],
    ),
  );
}
