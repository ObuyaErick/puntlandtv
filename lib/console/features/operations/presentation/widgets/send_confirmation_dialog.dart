import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_number_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/push_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/widgets/console_fields.dart';

/// The last thing between a draft and 38,000 lock screens.
///
/// Type-to-confirm rather than a plain button: this is irreversible, reaches
/// everyone at once, and the cost of an accidental click is a retraction the
/// product has no way to send. Both payloads are shown in full, because the
/// English one is the half most likely to be wrong.
Future<bool> showSendConfirmation(
  BuildContext context, {
  required PushDraftDto draft,
  required PushReachDto? reach,
  required String senderName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _SendConfirmationDialog(
      draft: draft,
      reach: reach,
      senderName: senderName,
    ),
  );
  return result ?? false;
}

class _SendConfirmationDialog extends StatefulWidget {
  const _SendConfirmationDialog({
    required this.draft,
    required this.reach,
    required this.senderName,
  });

  final PushDraftDto draft;
  final PushReachDto? reach;
  final String senderName;

  @override
  State<_SendConfirmationDialog> createState() =>
      _SendConfirmationDialogState();
}

class _SendConfirmationDialogState extends State<_SendConfirmationDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final confirmWord = l10n.confirmWord;
    final matches = _controller.text.trim().toUpperCase() == confirmWord;
    final total = widget.reach?.total ?? 0;

    return AlertDialog(
      title: Text(
        l10n.confirmSendTitle(
          AppNumberFormat.decimal(total, context.languageCode),
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.confirmSendBody,
                style: context.text.body.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.gutter),
              for (final locale in PushDraftDto.requiredLocales) ...[
                _PayloadCard(
                  locale: locale,
                  message: widget.draft.message(locale),
                  count: widget.reach?.forLocale(locale) ?? 0,
                ),
                const SizedBox(height: Spacing.cardInternal),
              ],
              const SizedBox(height: Spacing.chip),
              ConsoleTextField(
                label: l10n.typeToConfirm(confirmWord),
                controller: _controller,
                autofocus: true,
                hintText: confirmWord,
              ),
              const SizedBox(height: Spacing.cardInternal),
              Text(
                l10n.sentAsAudit(widget.senderName),
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(backgroundColor: context.scheme.error),
          child: Text(l10n.sendNow),
        ),
      ],
    );
  }
}

class _PayloadCard extends StatelessWidget {
  const _PayloadCard({
    required this.locale,
    required this.message,
    required this.count,
  });

  final String locale;
  final PushMessageDto message;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.cardInternal),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerLow,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The payload's language is named, not coded: this card identifies
          // *which* message is about to go out, so it is prose.
          Text(
            '${context.languageNameOf(locale)} · $count',
            style: context.text.overline.copyWith(
              fontSize: 9.5,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.title,
            style: context.text.label.copyWith(color: context.scheme.primary),
          ),
          const SizedBox(height: 2),
          Text(
            message.body,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
