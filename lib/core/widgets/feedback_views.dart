import 'package:material_ui/material_ui.dart';

import '../error/failure.dart';
import '../l10n/l10n.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.dart';

/// Error state with a retry and a secondary escape hatch.
///
/// The canvas pairs "Try again" with "Open saved" deliberately: when the
/// network is down, retrying may not work, and offering the user something
/// they can actually read is better than a dead end.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.title,
    this.secondaryLabel,
    this.onSecondary,
  });

  final Failure failure;
  final VoidCallback onRetry;
  final String? title;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.emptyState),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.scheme.errorContainer,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.errorContainerOutline),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: context.scheme.error,
                size: 26,
              ),
            ),
            const SizedBox(height: Spacing.listRhythm),
            Text(
              title ?? l10n.feedErrorTitle,
              textAlign: TextAlign.center,
              style: context.text.title.copyWith(color: context.scheme.primary),
            ),
            const SizedBox(height: Spacing.chip),
            Text(
              l10n.errorCodeLine(failure.code),
              style: context.text.meta.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sectionBreak),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
                if (onSecondary != null) ...[
                  const SizedBox(width: Spacing.cardInternal),
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel ?? l10n.openSaved),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state. Says what will fill the space and why it is empty now.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_rounded,
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.emptyState),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.colors.skeleton,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: context.scheme.onSurfaceVariant,
                size: 26,
              ),
            ),
            const SizedBox(height: Spacing.listRhythm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.title.copyWith(color: context.scheme.primary),
            ),
            if (body != null) ...[
              const SizedBox(height: Spacing.chip),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: context.text.body.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: Spacing.sectionBreak),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? ''),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin banner pinned under the app bar while offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.gutter,
        vertical: 10,
      ),
      color: context.scheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: context.scheme.error),
          const SizedBox(width: Spacing.chip),
          Expanded(
            child: Text(
              message ?? context.l10n.offlineBanner,
              style: context.text.label.copyWith(color: context.scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
