import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/push_dto.dart';
import '../../../../core/providers/console_providers.dart';

/// What the alert will actually look like on a phone.
///
/// The preview exists because a push is the one thing in the console the
/// author never sees before 38,000 people do. Rendering both locales side by
/// side also makes an empty English body impossible to overlook.
class LockScreenPreview extends ConsumerWidget {
  const LockScreenPreview({
    super.key,
    required this.locale,
    required this.message,
    required this.topicLabel,
  });

  final String locale;
  final PushMessageDto message;
  final String topicLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final incomplete = !message.isComplete;
    final now = ref.watch(consoleClockProvider)();

    return Container(
      padding: const EdgeInsets.all(Spacing.listRhythm),
      decoration: BoxDecoration(
        color: DarkTokens.background,
        borderRadius: Radii.cardBorder,
        border: Border.all(
          color: incomplete ? context.scheme.error : DarkTokens.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${locale == 'so' ? 'SOOMAALI · so' : 'ENGLISH · en-US'}'
                '${incomplete ? ' · ${l10n.previewIncomplete}' : ''}',
                style: context.text.overline.copyWith(
                  fontSize: 9.5,
                  color: incomplete
                      ? context.scheme.error
                      : DarkTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.listRhythm),
          Text(
            AppDateFormat.time(now, locale),
            style: context.text.display.copyWith(
              fontSize: 30,
              color: Colors.white,
            ),
          ),
          Text(
            AppDateFormat.weekdayDayMonth(now, locale),
            style: context.text.meta.copyWith(
              color: DarkTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.listRhythm),
          Container(
            padding: const EdgeInsets.all(Spacing.cardInternal),
            decoration: BoxDecoration(
              color: DarkTokens.surface,
              borderRadius: Radii.cardBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: LightTokens.error,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        topicLabel,
                        style: context.text.overline.copyWith(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'now',
                      style: context.text.meta.copyWith(
                        fontSize: 11,
                        color: DarkTokens.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.chip),
                Text(
                  message.title.isEmpty ? '—' : message.title,
                  // Two lines is what a real lock screen gives a title.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.label.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  message.body.isEmpty ? l10n.bodyMissing : message.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.meta.copyWith(
                    color: message.body.isEmpty
                        ? context.scheme.error
                        : DarkTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (message.titleWillTruncate) ...[
            const SizedBox(height: Spacing.chip),
            Text(
              l10n.truncationHint(PushMessageDto.titleTruncatesAt),
              style: context.text.meta.copyWith(color: context.scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
