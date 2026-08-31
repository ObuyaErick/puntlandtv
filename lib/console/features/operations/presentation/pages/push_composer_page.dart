import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_number_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/push_dto.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_fields.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_toast.dart';
import '../controllers/push_controller.dart';
import '../widgets/lock_screen_preview.dart';
import '../widgets/send_confirmation_dialog.dart';

/// Composes a breaking-news alert.
///
/// The screen is built around one refusal: **a push cannot go out in one
/// language.** Payloads are written before they leave the server and cannot be
/// translated on the device, so an alert composed only in Somali would reach
/// English-preference readers as Somali or not at all. Send stays disabled,
/// the incomplete locale is named, and the preview shows both.
class PushComposerPage extends ConsumerWidget {
  const PushComposerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(pushDraftProvider);
    final reach = ref.watch(pushReachProvider(draft.topicsKey)).value;

    return ConsolePage(
      title: l10n.pushTitle,
      subtitle: reach == null
          ? null
          : l10n.estimatedReach(
              AppNumberFormat.decimal(reach.total, context.languageCode),
            ),
      actions: [
        OutlinedButton(onPressed: () {}, child: Text(l10n.saveAsDraft)),
        FilledButton(
          onPressed: draft.canSend ? () => _review(context, ref, draft) : null,
          child: Text(l10n.reviewAndSend),
        ),
      ],
      notice: draft.canSend
          ? null
          : ConsoleNotice(
              warning: true,
              icon: Icons.warning_amber_rounded,
              message: l10n.sendBlocked,
            ),
      child: WindowSizeScope(
        builder: (context, size) {
          final composer = _ComposerColumn(draft: draft);
          final previews = _PreviewColumn(draft: draft);

          if (!size.isAtLeastExpanded) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.gutter,
                0,
                Spacing.gutter,
                Spacing.emptyState,
              ),
              children: [
                composer,
                const SizedBox(height: Spacing.sectionBreak),
                previews,
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.gutter,
              0,
              Spacing.gutter,
              Spacing.gutter,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(child: composer),
                ),
                const SizedBox(width: Spacing.sectionBreak),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(child: previews),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    PushDraftDto draft,
  ) async {
    final l10n = context.l10n;
    final reach = ref.read(pushReachProvider(draft.topicsKey)).value;
    final user = ref.read(currentUserProvider);

    final confirmed = await showSendConfirmation(
      context,
      draft: draft,
      reach: reach,
      senderName: user?.name ?? '',
    );
    if (!confirmed || !context.mounted) return;

    final sent = await ref.read(pushSenderProvider.notifier).send();
    if (!context.mounted) return;
    showConsoleToast(
      context,
      message: l10n.pushSent(
        AppNumberFormat.decimal(sent, context.languageCode),
      ),
      kind: ToastKind.success,
    );
  }
}

class _ComposerColumn extends ConsumerWidget {
  const _ComposerColumn({required this.draft});

  final PushDraftDto draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final locale in PushDraftDto.requiredLocales) ...[
          _MessageSection(locale: locale, draft: draft),
          const SizedBox(height: Spacing.sectionBreak),
        ],
        Text(
          l10n.sectionTarget,
          style: context.text.overline.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.cardInternal),
        ConsoleTextField(
          label: l10n.fieldDeepLink,
          hintText: 'pltv://article/4183',
          onSubmitted: ref.read(pushDraftProvider.notifier).setDeepLink,
        ),
        const SizedBox(height: Spacing.listRhythm),
        Wrap(
          spacing: Spacing.chip,
          runSpacing: Spacing.chip,
          children: [
            for (final topic in const [
              'breaking',
              'national',
              'sport',
              'economy',
              'programmes',
            ])
              FilterChip(
                label: Text(topic),
                selected: draft.topics.contains(topic),
                onSelected: (_) =>
                    ref.read(pushDraftProvider.notifier).toggleTopic(topic),
              ),
          ],
        ),
      ],
    );
  }
}

class _MessageSection extends ConsumerStatefulWidget {
  const _MessageSection({required this.locale, required this.draft});

  final String locale;
  final PushDraftDto draft;

  @override
  ConsumerState<_MessageSection> createState() => _MessageSectionState();
}

class _MessageSectionState extends ConsumerState<_MessageSection> {
  late final _title = TextEditingController(
    text: widget.draft.message(widget.locale).title,
  );
  late final _body = TextEditingController(
    text: widget.draft.message(widget.locale).body,
  );

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = ref.read(pushDraftProvider.notifier);
    final message = widget.draft.message(widget.locale);
    final isSomali = widget.locale == 'so';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.messageInLocale(isSomali ? 'SOOMAALI' : 'ENGLISH'),
                style: context.text.overline.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacing.chip),
              // A tinted chip, not bare red text: it is a standing requirement,
              // not an error the user has just caused.
              Container(
                height: 19,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LightTokens.errorContainer,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: LightTokens.errorContainerOutline),
                ),
                child: Text(
                  l10n.required,
                  style: context.text.overline.copyWith(
                    fontSize: 9.5,
                    color: LightTokens.error,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                message.isComplete ? l10n.complete : l10n.bodyMissing,
                style: context.text.meta.copyWith(
                  color: message.isComplete
                      ? context.colors.accent
                      : context.scheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.cardInternal),
          ConsoleTextField(
            label: l10n.fieldTitle,
            controller: _title,
            onSubmitted: (_) {},
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.truncationHint(PushMessageDto.titleTruncatesAt),
                  style: context.text.meta.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                l10n.charCount(
                  message.title.length,
                  PushMessageDto.titleTruncatesAt,
                ),
                style: context.text.meta.copyWith(
                  color: message.titleWillTruncate
                      ? context.scheme.error
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.listRhythm),
          ConsoleTextField(
            label: l10n.fieldBody,
            controller: _body,
            errorText: message.body.trim().isEmpty
                ? l10n.bodyRequiredHint
                : null,
            onSubmitted: (_) {},
          ),
          if (!isSomali && message.body.trim().isEmpty) ...[
            const SizedBox(height: Spacing.chip),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  controller.copyBodyFrom(from: 'so', to: 'en');
                  _body.text = ref.read(pushDraftProvider).message('en').body;
                },
                child: Text(l10n.copySomaliBody),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewColumn extends StatelessWidget {
  const _PreviewColumn({required this.draft});

  final PushDraftDto draft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.lockScreenPreview,
          style: context.text.label.copyWith(color: context.scheme.primary),
        ),
        const SizedBox(height: Spacing.cardInternal),
        for (final locale in PushDraftDto.requiredLocales) ...[
          LockScreenPreview(
            locale: locale,
            message: draft.message(locale),
            topicLabel: locale == 'so' ? 'DEG DEG' : 'BREAKING',
          ),
          const SizedBox(height: Spacing.listRhythm),
        ],
      ],
    );
  }
}
