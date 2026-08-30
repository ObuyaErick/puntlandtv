import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/article.dart';

/// The underlined category strip from the canvas.
///
/// A horizontal `ListView` rather than a `TabBar` because the Somali category
/// names are materially longer than the English ones and must be free to
/// overflow into a scroll rather than being compressed to fit.
class CategoryTabs extends StatelessWidget {
  const CategoryTabs({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<NewsCategory> categories;
  final String selectedSlug;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.slug == selectedSlug;

          return Semantics(
            selected: selected,
            button: true,
            child: InkWell(
              onTap: () => onSelected(category.slug),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2.5,
                      color: selected
                          ? context.scheme.primary
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  category.name,
                  style: context.text.label.copyWith(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? context.scheme.primary
                        : context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
