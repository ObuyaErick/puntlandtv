import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../operations/presentation/pages/categories_page.dart';
import '../controllers/article_editor_controller.dart';

/// Category, read time, schedule and the breaking-news switch.
///
/// Everything here is an article-level field, so every control writes through
/// `updateArticle` and none of them touches a translation. That is why a
/// sub-editor can re-file a story while a journalist is still typing in it.
class PublishingPanel extends ConsumerWidget {
  const PublishingPanel({
    super.key,
    required this.editor,
    required this.onCategoryChanged,
    required this.onBreakingChanged,
    required this.onSchedule,
  });

  final ArticleEditor editor;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onBreakingChanged;
  final ValueChanged<DateTime> onSchedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final article = editor.article;
    final locale = context.languageCode;
    final categories = ref.watch(categoryConfigProvider).value ?? const [];
    final source = editor.draftFor(article.sourceLocale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.sectionPublishing,
          style: context.text.overline.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.listRhythm - 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Labelled(
                label: l10n.fieldCategory,
                child: DropdownButtonFormField<String>(
                  initialValue:
                      categories.any((c) => c.slug == article.categorySlug)
                      ? article.categorySlug
                      : null,
                  isExpanded: true,
                  decoration: _boxed(context),
                  style: context.text.body.copyWith(
                    color: context.scheme.primary,
                  ),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category.slug,
                        // The localised display name, not the slug: the slug is
                        // an identifier for deep links, and a newsroom picking
                        // a category should be reading category names.
                        child: Text(
                          category.nameFor(locale),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onCategoryChanged(value);
                  },
                ),
              ),
            ),
            const SizedBox(width: Spacing.cardInternal),
            SizedBox(
              width: 118,
              child: _Labelled(
                label: l10n.fieldReadTime,
                // Derived, and shown as derived. Reading time is computed from
                // the body the reader gets; an editable field here would be a
                // second opinion the app would ignore.
                child: _Readonly(
                  text: l10n.autoReadTime(source.readingMinutes),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.listRhythm - 2),
        _Labelled(
          label: l10n.fieldSchedule,
          child: InkWell(
            onTap: () => _pickSchedule(context),
            borderRadius: Radii.cardBorder,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: Radii.cardBorder,
                border: Border.all(color: context.colors.outline),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: context.scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      article.scheduledFor == null
                          ? l10n.notScheduled
                          : AppDateFormat.byline(
                              article.scheduledFor!,
                              context.languageCode,
                            ),
                      overflow: TextOverflow.ellipsis,
                      style: context.text.body.copyWith(
                        color: article.scheduledFor == null
                            ? context.scheme.onSurfaceVariant
                            : context.scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.listRhythm - 2),
        Container(
          padding: const EdgeInsets.all(Spacing.cardInternal),
          decoration: BoxDecoration(
            color: context.scheme.errorContainer,
            borderRadius: Radii.cardBorder,
            border: Border.all(color: context.colors.errorContainerOutline),
          ),
          child: Row(
            children: [
              Switch.adaptive(
                value: article.isBreaking,
                onChanged: onBreakingChanged,
              ),
              const SizedBox(width: Spacing.cardInternal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.fieldBreaking,
                      style: context.text.label.copyWith(
                        color: context.scheme.error,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Says what the switch does *and* what it does not: the
                    // flag and the push are separate acts, and an editor who
                    // assumes otherwise either sends nothing or sends twice.
                    Text(
                      l10n.breakingHint,
                      style: context.text.meta.copyWith(
                        color: context.scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickSchedule(BuildContext context) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: editor.article.scheduledFor ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (day == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(editor.article.scheduledFor ?? now),
    );
    if (time == null) return;

    onSchedule(DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  static InputDecoration _boxed(BuildContext context) => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: Radii.cardBorder,
      borderSide: BorderSide(color: context.colors.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: Radii.cardBorder,
      borderSide: BorderSide(color: context.colors.link, width: 2),
    ),
  );
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.text.label.copyWith(color: context.scheme.onSurface),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

class _Readonly extends StatelessWidget {
  const _Readonly({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: AlignmentDirectional.centerStart,
    decoration: BoxDecoration(
      borderRadius: Radii.cardBorder,
      border: Border.all(color: context.colors.outline),
    ),
    child: Text(
      text,
      style: context.text.body.copyWith(color: context.scheme.onSurfaceVariant),
    ),
  );
}
