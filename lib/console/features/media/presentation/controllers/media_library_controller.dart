import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/error/failure.dart';
import '../../../../core/admin_api/dto/media_dto.dart';
import '../../../../core/providers/console_providers.dart';

part 'media_library_controller.g.dart';

/// Which filter chip is active.
@riverpod
class MediaFilter extends _$MediaFilter {
  @override
  MediaKindFilter build() => MediaKindFilter.all;

  void select(MediaKindFilter value) => state = value;
}

/// The search box's contents.
///
/// Separate from [MediaFilter] because the two compose: "videos matching
/// 'dood'" is a normal thing to ask, and folding search into the filter enum
/// would make it impossible to express.
///
/// Named `MediaSearch` rather than the obvious `MediaQuery` — that name is
/// taken by a Flutter widget every screen in this codebase uses.
@riverpod
class MediaSearch extends _$MediaSearch {
  @override
  String build() => '';

  void update(String value) => state = value;

  void clear() => state = '';
}

/// Assets ticked for a bulk action.
@riverpod
class MediaSelection extends _$MediaSelection {
  @override
  Set<String> build() => const {};

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void clear() => state = const {};

  void selectAll(Iterable<String> ids) => state = ids.toSet();
}

/// The grid's contents.
@riverpod
Future<List<MediaAssetDto>> mediaLibrary(Ref ref) {
  final query = ref.watch(mediaSearchProvider);
  return ref
      .watch(adminApiProvider)
      .fetchMedia(
        filter: ref.watch(mediaFilterProvider),
        query: query.isEmpty ? null : query,
      );
}

/// Counts for the filter chips, independent of the active filter.
///
/// Fetches the unfiltered library rather than counting the filtered view — a
/// chip that reads 0 because its own filter is not selected is worse than no
/// count at all. The search box *does* narrow the counts, because a search is
/// the user asking about a subset.
@riverpod
Future<MediaCounts> mediaCounts(Ref ref) async {
  final query = ref.watch(mediaSearchProvider);
  final all = await ref
      .watch(adminApiProvider)
      .fetchMedia(query: query.isEmpty ? null : query);
  return MediaCounts.from(all);
}

/// One asset, live. The detail panel watches this rather than holding the row
/// it was opened with, so a save is reflected without closing the panel.
@riverpod
Future<MediaAssetDto> mediaAsset(Ref ref, String id) =>
    ref.watch(adminApiProvider).fetchMediaAsset(id);

/// Writes against the library.
///
/// Every method invalidates the list *and* the counts: the "needs alt text"
/// chip is derived from the same rule the rows are, and letting the two drift
/// is how a newsroom stops trusting the number.
///
/// `keepAlive` is load-bearing rather than an optimisation. Nothing *watches*
/// an actions provider — a caller reads it, calls a method, and lets go — so
/// under auto-dispose the notifier is gone before the await returns and the
/// invalidation that follows throws on a disposed `Ref`. The visible symptom
/// is worse than the exception: the write lands and the grid never refreshes,
/// so the screen shows stale alt-text state for a file that has just been
/// described. Guarding on `ref.mounted` would swap the throw for exactly that
/// silence, which is why this is keep-alive instead.
@Riverpod(keepAlive: true)
class MediaActions extends _$MediaActions {
  @override
  void build() {}

  void _refresh([String? id]) {
    ref
      ..invalidate(mediaLibraryProvider)
      ..invalidate(mediaCountsProvider);
    if (id != null) ref.invalidate(mediaAssetProvider(id));
  }

  Future<MediaAssetDto> save(MediaAssetDto asset) async {
    final saved = await ref.read(adminApiProvider).saveMediaAsset(asset);
    _refresh(saved.id);
    return saved;
  }

  /// Registers an upload and returns it, so the caller can open the detail
  /// panel on the new asset — which for an image is a panel showing two empty
  /// alt-text fields. That is the point: an undescribed image should not sit
  /// in the grid looking finished.
  Future<MediaAssetDto> upload({
    required String filename,
    required MediaKind kind,
    required int byteSize,
  }) async {
    final asset = await ref
        .read(adminApiProvider)
        .uploadMedia(filename: filename, kind: kind, byteSize: byteSize);
    _refresh();
    return asset;
  }

  /// Deletes [ids], skipping nothing — the API refuses an asset in use, and
  /// that refusal is the point. Returns the ids it could not delete so the
  /// caller can say which, rather than reporting a vague partial failure.
  Future<List<String>> delete(Iterable<String> ids) async {
    final api = ref.read(adminApiProvider);
    final refused = <String>[];

    for (final id in ids) {
      try {
        await api.deleteMediaAsset(id);
      } on Failure catch (failure) {
        // Only the in-use refusal is expected and absorbed. Anything else is a
        // real fault, and swallowing it here would turn a broken backend into
        // a silently short delete.
        if (failure.code != MediaFailureCode.inUse) rethrow;
        refused.add(id);
      }
    }

    _refresh();
    ref.read(mediaSelectionProvider.notifier).clear();
    return refused;
  }

  Future<void> retryIngest(String id) async {
    await ref.read(adminApiProvider).retryMediaIngest(id);
    _refresh(id);
  }
}
