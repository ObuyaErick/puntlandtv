import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/page.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/program.dart';

part 'vod_controllers.g.dart';

@riverpod
Future<List<Program>> programs(Ref ref) {
  return ref.watch(vodRepositoryProvider).programs();
}

@riverpod
Future<Page<Episode>> episodes(Ref ref, String? programId) {
  return ref.watch(vodRepositoryProvider).episodes(programId: programId);
}

@riverpod
Future<Program?> program(Ref ref, String id) async {
  final all = await ref.watch(programsProvider.future);
  for (final p in all) {
    if (p.id == id) return p;
  }
  return null;
}
