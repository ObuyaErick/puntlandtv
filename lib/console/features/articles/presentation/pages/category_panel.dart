import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../app/console_navigation.dart';
import '../../../../core/admin_api/dto/broadcast_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/widgets/console_fields.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../../core/widgets/side_panel.dart';
import '../controllers/article_list_controller.dart';
import '../controllers/category_controller.dart';

/// Opens the category editor: blank for [category] null, otherwise that row.
///
/// The panel closes with `true` when someone asked to see the category's
/// articles, and the navigation happens here, from the page it was opened
/// over: the panel is a route of its own, and it has to be gone before the
/// Articles branch pops back to the list.
Future<void> showCategoryPanel(
  BuildContext context, {
  CategoryConfigDto? category,
}) async {
  final viewArticles = await showSidePanel<bool>(
    context: context,
    builder: (context) => CategoryPanel(category: category),
  );
  if ((viewArticles ?? false) && context.mounted) context.openArticles();
}

/// Asks before deleting [category], then deletes it and says how it went.
///
/// Shared by the panel's Delete button and the table row's quick action, so
/// the question and the refusal read the same from either. [onConfirmed] fires
/// once the answer is yes, before the write, so the caller can show itself
/// busy. Returns whether the category is gone.
Future<bool> confirmDeleteCategory(
  BuildContext context,
  WidgetRef ref,
  CategoryConfigDto category, {
  VoidCallback? onConfirmed,
}) async {
  final l10n = context.l10n;
  final name = category.nameFor(context.languageCode);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteCategoryTitle(name)),
      content: Text(l10n.deleteCategoryBody(category.slug)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.scheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
      constraints: const BoxConstraints(maxWidth: 400),
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  onConfirmed?.call();
  try {
    await ref.read(categoryActionsProvider.notifier).delete(category.slug);
    if (context.mounted) {
      showConsoleToast(
        context,
        message: l10n.categoryDeleted(name),
        kind: ToastKind.success,
      );
    }
    return true;
  } on Failure catch (failure) {
    // The count on screen was stale: someone filed an article here since the
    // list loaded. Refetch so the disabled state catches up.
    if (failure.code == CategoryFailureCode.inUse) {
      ref.invalidate(categoryConfigProvider);
    }
    if (context.mounted) {
      showConsoleToast(
        context,
        message: failure.code == CategoryFailureCode.inUse
            ? l10n.categoryInUseRefusal
            : l10n.errorCodeLine(failure.code),
        kind: ToastKind.error,
      );
    }
    return false;
  }
}

/// Creates a category, or renames and deletes one.
///
/// The one form carries the page's lesson in both modes. Creating, the slug is
/// a field with its rule checked as it is typed and a warning that this is the
/// last chance to get it right; editing, it is shown but not editable. The
/// names are the part that is safe to change, and each empty one says which
/// tab bar it hides the category from.
class CategoryPanel extends ConsumerStatefulWidget {
  const CategoryPanel({super.key, this.category});

  /// Null when creating.
  final CategoryConfigDto? category;

  @override
  ConsumerState<CategoryPanel> createState() => _CategoryPanelState();
}

class _CategoryPanelState extends ConsumerState<CategoryPanel> {
  late final _slug = TextEditingController(text: widget.category?.slug ?? '');
  late final Map<String, TextEditingController> _names = {
    for (final locale in CategoryConfigDto.locales)
      locale: TextEditingController(text: widget.category?.names[locale] ?? ''),
  };

  /// The slug error stays quiet until someone has typed into the field, so a
  /// freshly opened form does not open by shouting at them.
  var _slugTouched = false;
  var _busy = false;

  bool get _isNew => widget.category == null;

  @override
  void dispose() {
    _slug.dispose();
    for (final controller in _names.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _slugValue => _slug.text.trim();

  Map<String, String> get _nameValues => {
    for (final MapEntry(:key, :value) in _names.entries) key: value.text.trim(),
  };

  bool get _hasAnyName => _nameValues.values.any((name) => name.isNotEmpty);

  String? _slugError(List<CategoryConfigDto> existing) {
    if (!_isNew) return null;
    final slug = _slugValue;
    if (!CategoryConfigDto.slugPattern.hasMatch(slug)) {
      return context.l10n.slugFormatError;
    }
    if (existing.any((row) => row.slug == slug)) {
      return context.l10n.slugTakenError;
    }
    return null;
  }

  bool _isDirty() {
    final original = widget.category;
    if (original == null) return true;
    return _nameValues.entries.any(
      (entry) => entry.value != (original.names[entry.key] ?? '').trim(),
    );
  }

  /// The name the toasts use: the active locale's, falling back like the
  /// table does.
  String _displayName() => CategoryConfigDto(
    slug: _isNew ? _slugValue : widget.category!.slug,
    names: _nameValues,
    articleCount: 0,
    order: 0,
  ).nameFor(context.languageCode);

  Future<void> _save() async {
    final l10n = context.l10n;
    final actions = ref.read(categoryActionsProvider.notifier);
    final name = _displayName();

    setState(() => _busy = true);
    try {
      if (_isNew) {
        await actions.create(slug: _slugValue, names: _nameValues);
      } else {
        await actions.rename(slug: widget.category!.slug, names: _nameValues);
      }
      if (!mounted) return;
      Navigator.of(context).maybePop();
      showConsoleToast(
        context,
        message: _isNew ? l10n.categoryCreated(name) : l10n.categorySaved(name),
        kind: ToastKind.success,
      );
    } on Failure catch (failure) {
      if (!mounted) return;
      showConsoleToast(
        context,
        message: l10n.errorCodeLine(failure.code),
        kind: ToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Narrows the article list to this category and leaves for it.
  void _viewArticles(String slug) {
    ref.read(articleFilterProvider.notifier).onlyCategory(slug);
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    try {
      final deleted = await confirmDeleteCategory(
        context,
        ref,
        widget.category!,
        onConfirmed: () => setState(() => _busy = true),
      );
      if (deleted && mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final existing = ref.watch(categoryConfigProvider).value ?? const [];
    final category = _isNew
        ? null
        // The live row rather than the one the panel was opened with, so a
        // refetch after a refused delete updates the count and the button.
        : existing
                  .where((row) => row.slug == widget.category!.slug)
                  .firstOrNull ??
              widget.category;

    final slugError = _slugError(existing);
    final canSave =
        !_busy && slugError == null && (_isNew ? _hasAnyName : _isDirty());

    return SidePanelScaffold(
      title: _isNew ? l10n.newCategory : l10n.editCategory,
      subtitle: category?.slug,
      actions: [
        if (category != null)
          // Disabled rather than hidden, with the reason below the form: "why
          // can I not delete this" is a question the panel has to answer.
          OutlinedButton(
            onPressed: !_busy && category.canDelete ? _delete : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colors.outline),
              foregroundColor: context.scheme.error,
            ),
            child: Text(l10n.delete),
          ),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: Text(_isNew ? l10n.createCategory : l10n.save),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConsoleTextField(
            label: l10n.fieldSlug,
            controller: _slug,
            hintText: l10n.slugHint,
            enabled: _isNew,
            autofocus: _isNew,
            errorText: _slugTouched ? slugError : null,
            onChanged: (_) => setState(() => _slugTouched = true),
          ),
          const SizedBox(height: 6),
          Text(
            _isNew ? l10n.slugChooseCarefully : l10n.slugLocked,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sectionBreak),
          Text(
            l10n.sectionDisplayNames,
            style: context.text.overline.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.cardInternal),
          for (final locale in CategoryConfigDto.locales) ...[
            _NameField(
              language: context.languageNameOf(locale),
              controller: _names[locale]!,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: Spacing.listRhythm),
          ],
          if (!_hasAnyName)
            Text(
              _isNew ? l10n.categoryNeedsName : l10n.categoryHiddenEverywhere,
              style: context.text.meta.copyWith(color: context.scheme.error),
            ),
          if (category != null) ...[
            const SizedBox(height: Spacing.sectionBreak),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.categoryArticleCount(category.articleCount),
                    style: context.text.body.copyWith(
                      color: context.scheme.onSurface,
                    ),
                  ),
                ),
                // The way to the stories the count is about — and, when the
                // count is what blocks a delete, the way to go and move them.
                if (category.articleCount > 0)
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _viewArticles(category.slug),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    iconAlignment: IconAlignment.end,
                    label: Text(l10n.viewCategoryArticles),
                  ),
              ],
            ),
            if (!category.canDelete) ...[
              const SizedBox(height: 4),
              Text(
                l10n.deleteCategoryBlocked(category.articleCount),
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// One language's name, and what leaving it empty does.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.language,
    required this.controller,
    required this.onChanged,
  });

  final String language;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final empty = controller.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConsoleTextField(
          label: l10n.categoryNameIn(language),
          controller: controller,
          onChanged: (_) => onChanged(),
        ),
        if (empty) ...[
          const SizedBox(height: 6),
          Text(
            l10n.categoryHiddenIn(language),
            // The table's colour for the same state, so the two read as one.
            style: context.text.meta.copyWith(color: context.scheme.error),
          ),
        ],
      ],
    );
  }
}
