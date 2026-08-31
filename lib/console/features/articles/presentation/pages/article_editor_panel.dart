import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/localised.dart';
import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/widgets/console_fields.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../../core/widgets/side_panel.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/console_user.dart';
import '../../../../core/providers/console_providers.dart';
import '../controllers/article_list_controller.dart';
import '../widgets/translation_panel.dart';

/// Opens the article editor: a side panel from expanded up, a full screen
/// below — the shared presenter decides which.
Future<void> showArticleEditor(
  BuildContext context, {
  required AdminArticleDto article,
}) {
  return showSidePanel<void>(
    context: context,
    builder: (context) => ArticleEditorPanel(article: article),
  );
}

/// Edits one language of an article, with the other language's status beside
/// it.
///
/// Locale tabs rather than two columns: side-by-side needs ~1100dp of editor
/// width to be readable, and the panel is 560. The canvas offers side-by-side
/// as its own mode for exactly that reason.
class ArticleEditorPanel extends ConsumerStatefulWidget {
  const ArticleEditorPanel({super.key, required this.article});

  final AdminArticleDto article;

  @override
  ConsumerState<ArticleEditorPanel> createState() => _ArticleEditorPanelState();
}

class _ArticleEditorPanelState extends ConsumerState<ArticleEditorPanel> {
  late AdminArticleDto _article = widget.article;
  late String _locale = widget.article.sourceLocale;

  late final _headline = TextEditingController(text: _current.title);
  late final _excerpt = TextEditingController(text: _current.excerpt ?? '');

  static const _headlineLimit = 120;

  ArticleTranslationDto get _current =>
      _article.translations[_locale] ??
      ArticleTranslationDto(title: '', updatedAt: DateTime.now());

  @override
  void dispose() {
    _headline.dispose();
    _excerpt.dispose();
    super.dispose();
  }

  void _switchLocale(String locale) {
    setState(() {
      _locale = locale;
      _headline.text = _current.title;
      _excerpt.text = _current.excerpt ?? '';
    });
  }

  /// Marks a translation as re-confirmed by stamping it with the source's
  /// timestamp, which is what clears the stale flag.
  void _reconfirm(String locale) {
    final source = _article.translations[_article.sourceLocale];
    if (source == null) return;

    setState(() {
      _article = _article.copyWith(
        translations: {
          ..._article.translations,
          locale: _article.translations[locale]!.copyWith(
            updatedAt: source.updatedAt,
          ),
        },
      );
    });
    showConsoleToast(
      context,
      message: context.l10n.translationCurrent,
      kind: ToastKind.success,
    );
  }

  Future<void> _save({required bool publish}) async {
    final updated = _article.copyWith(
      translations: {
        ..._article.translations,
        _locale: _current.copyWith(
          title: _headline.text,
          excerpt: _excerpt.text,
          updatedAt: DateTime.now(),
        ),
      },
      status: publish ? ArticleStatus.published : _article.status,
    );

    await ref.read(articleActionsProvider.notifier).save(updated);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPublish =
        ref.watch(currentUserProvider)?.can(Capability.publishArticles) ??
        false;
    final altMissing = _article.imageUrl != null && _article.imageAlt == null;

    return SidePanelScaffold(
      title: _current.title.isEmpty ? l10n.newArticle : _current.title,
      subtitle: l10n.savedAt(
        AppDateFormat.time(_article.updatedAt, context.languageCode),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => _save(publish: false),
          child: Text(l10n.saveDraft),
        ),
        if (canPublish)
          FilledButton(
            // Alt text is a hard gate, not a warning: an unlabelled hero image
            // is unreadable to a screen-reader user and there is no fixing it
            // after publication without another release of the story.
            onPressed: altMissing ? null : () => _save(publish: true),
            child: Text(l10n.publishNow),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocaleTabs(
            article: _article,
            selected: _locale,
            onSelected: _switchLocale,
          ),
          const SizedBox(height: Spacing.gutter),
          ConsoleTextField(
            label: l10n.editorHeadline(_locale.toUpperCase()),
            controller: _headline,
            onSubmitted: (_) {},
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                l10n.headlineHint,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _headline,
                builder: (context, value, _) => Text(
                  l10n.charCount(value.text.length, _headlineLimit),
                  style: context.text.meta.copyWith(
                    color: value.text.length > _headlineLimit
                        ? context.scheme.error
                        : context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.listRhythm),
          ConsoleTextField(
            label: l10n.editorExcerpt(_locale.toUpperCase()),
            controller: _excerpt,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.wordCountAndRead(_current.wordCount, _current.readingMinutes),
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: Spacing.sectionBreak * 2),
          TranslationPanel(
            article: _article,
            onReconfirm: _reconfirm,
            onOpenSideBySide: _switchLocale,
          ),
          const Divider(height: Spacing.sectionBreak * 2),
          _PublishingSection(
            article: _article,
            altMissing: altMissing,
            onBreakingChanged: (value) => setState(() {
              _article = _article.copyWith(isBreaking: value);
            }),
          ),
        ],
      ),
    );
  }
}

class _LocaleTabs extends StatelessWidget {
  const _LocaleTabs({
    required this.article,
    required this.selected,
    required this.onSelected,
  });

  final AdminArticleDto article;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final stale = article.staleLocales;

    return Row(
      children: [
        for (final locale in article.locales) ...[
          Semantics(
            selected: locale == selected,
            button: true,
            child: InkWell(
              onTap: () => onSelected(locale),
              borderRadius: BorderRadius.circular(Radii.button),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: locale == selected
                      ? context.scheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.button),
                  border: Border.all(color: context.colors.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.languageNameOf(locale),
                      style: context.text.label.copyWith(
                        color: locale == selected
                            ? Colors.white
                            : context.scheme.onSurface,
                      ),
                    ),
                    if (stale.contains(locale)) ...[
                      const SizedBox(width: Spacing.chip),
                      const StatusBadge(kind: BadgeKind.failed),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.chip),
        ],
      ],
    );
  }
}

class _PublishingSection extends StatelessWidget {
  const _PublishingSection({
    required this.article,
    required this.altMissing,
    required this.onBreakingChanged,
  });

  final AdminArticleDto article;
  final bool altMissing;
  final ValueChanged<bool> onBreakingChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final source = article.translations[article.sourceLocale];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sectionPublishing,
          style: context.text.overline.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.cardInternal),
        if (altMissing) ...[
          Container(
            padding: const EdgeInsets.all(Spacing.cardInternal),
            decoration: BoxDecoration(
              color: context.scheme.errorContainer,
              borderRadius: Radii.cardBorder,
              border: Border.all(color: context.colors.errorContainerOutline),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 17,
                  color: context.scheme.error,
                ),
                const SizedBox(width: Spacing.chip),
                Expanded(
                  child: Text(
                    l10n.altTextRequired,
                    style: context.text.meta.copyWith(
                      color: context.scheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.listRhythm),
        ],
        _Row(label: l10n.fieldCategory, value: article.categorySlug),
        _Row(
          label: l10n.fieldReadTime,
          value: l10n.autoReadTime(source?.readingMinutes ?? 1),
        ),
        if (article.scheduledFor != null)
          _Row(
            label: l10n.fieldSchedule,
            value: AppDateFormat.byline(
              article.scheduledFor!,
              context.languageCode,
            ),
          ),
        const SizedBox(height: Spacing.chip),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: article.isBreaking,
          onChanged: onBreakingChanged,
          title: Text(l10n.fieldBreaking, style: context.text.body),
          subtitle: Text(
            l10n.breakingHint,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.cardInternal),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.body.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: context.text.body.copyWith(color: context.scheme.primary),
          ),
        ],
      ),
    );
  }
}
