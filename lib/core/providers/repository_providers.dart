import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/bookmarks/data/repositories/prefs_bookmark_repository.dart';
import '../../features/bookmarks/domain/repositories/bookmark_repository.dart';
import '../../features/live/data/repositories/live_repository_impl.dart';
import '../../features/live/domain/repositories/live_repository.dart';
import '../../features/news/data/repositories/news_repository_impl.dart';
import '../../features/news/domain/repositories/news_repository.dart';
import '../../features/radio/data/repositories/radio_repository_impl.dart';
import '../../features/radio/domain/repositories/radio_repository.dart';
import '../../features/vod/data/repositories/vod_repository_impl.dart';
import '../../features/vod/domain/repositories/vod_repository.dart';
import '../api/api_providers.dart';
import 'preferences_providers.dart';

/// Repository wiring — the only place where an interface meets its
/// implementation.
///
/// Every provider here is typed as the *interface*. That is what makes a fake
/// a one-line override in tests:
///
/// ```dart
/// ProviderScope(
///   overrides: [newsRepositoryProvider.overrideWithValue(FakeNews())],
///   child: const PuntlandTvApp(),
/// )
/// ```
final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepositoryImpl(ref.watch(puntlandApiProvider)),
);

final liveRepositoryProvider = Provider<LiveRepository>(
  (ref) => LiveRepositoryImpl(ref.watch(puntlandApiProvider)),
);

final radioRepositoryProvider = Provider<RadioRepository>(
  (ref) => RadioRepositoryImpl(ref.watch(puntlandApiProvider)),
);

final vodRepositoryProvider = Provider<VodRepository>(
  (ref) => VodRepositoryImpl(ref.watch(puntlandApiProvider)),
);

/// Local-only: no [PuntlandApi] dependency, by design.
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final repo = PrefsBookmarkRepository(ref.watch(sharedPreferencesProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// Saved slugs as a reactive set, so every bookmark button in the app reflects
/// a change made on any other screen.
final savedSlugsProvider = StreamProvider<Set<String>>((ref) {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return repo.watchSavedSlugs();
});
