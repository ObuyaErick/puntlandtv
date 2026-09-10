import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/admin_api/dto/broadcast_dto.dart';
import '../../../../core/providers/console_providers.dart';

part 'category_controller.g.dart';

/// The taxonomy, as the console sees it: every locale's name, plus counts.
///
/// `keepAlive` because the article list and the publishing panel `read` it for
/// their category pickers without watching it, and an auto-disposed provider
/// would hand them an empty list every time.
@Riverpod(keepAlive: true)
Future<List<CategoryConfigDto>> categoryConfig(Ref ref) =>
    ref.watch(adminApiProvider).fetchCategories();

/// Writes against the taxonomy.
///
/// Create and rename go through the whole-list save, because `order` is a
/// property of the collection rather than of one row; delete is its own call,
/// because the save never deletes. `keepAlive` for the same reason as the
/// other actions providers: nothing watches it, so under auto-dispose the
/// notifier would be gone before the awaited write returned.
@Riverpod(keepAlive: true)
class CategoryActions extends _$CategoryActions {
  @override
  void build() {}

  /// Adds a category at the end of the tab bar.
  Future<void> create({
    required String slug,
    required Map<String, String> names,
  }) async {
    final current = await ref.read(categoryConfigProvider.future);
    await _save([
      ...current,
      CategoryConfigDto(
        slug: slug,
        names: names,
        articleCount: 0,
        order: current.length,
      ),
    ]);
  }

  /// Changes a category's display names. The slug cannot change — it *is*
  /// the identity the save matches on.
  Future<void> rename({
    required String slug,
    required Map<String, String> names,
  }) async {
    final current = await ref.read(categoryConfigProvider.future);
    await _save([
      for (final row in current)
        row.slug == slug ? row.copyWith(names: names) : row,
    ]);
  }

  Future<void> delete(String slug) async {
    await ref.read(adminApiProvider).deleteCategory(slug);
    ref.invalidate(categoryConfigProvider);
  }

  /// Saves [rows] in list order, renumbering `order` from zero.
  ///
  /// Renumbered rather than sent as-is: two rows sharing a position leave the
  /// tab bar's order to whatever the database happens to return, and the list
  /// as the console displays it is the order everybody has been looking at.
  Future<void> _save(List<CategoryConfigDto> rows) async {
    await ref.read(adminApiProvider).saveCategories([
      for (final (index, row) in rows.indexed) row.copyWith(order: index),
    ]);
    ref.invalidate(categoryConfigProvider);
  }
}
