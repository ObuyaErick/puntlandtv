import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/admin_api/dto/admin_program_dto.dart';
import '../../../../core/providers/console_providers.dart';

part 'program_controller.g.dart';

@riverpod
Future<List<AdminProgramDto>> programList(Ref ref) =>
    ref.watch(adminApiProvider).fetchPrograms();

@riverpod
Future<List<AdminEpisodeDto>> episodeList(Ref ref, String programId) =>
    ref.watch(adminApiProvider).fetchEpisodes(programId);

/// Writes against programmes and episodes.
///
/// `keepAlive` for the same reason the media library's actions provider needs
/// it: nothing watches an actions provider, so under auto-dispose the notifier
/// is disposed before the awaited write returns and the invalidation that
/// follows throws on a dead `Ref`.
@Riverpod(keepAlive: true)
class ProgramActions extends _$ProgramActions {
  @override
  void build() {}

  Future<void> saveProgram(AdminProgramDto program) async {
    await ref.read(adminApiProvider).saveProgram(program);
    ref.invalidate(programListProvider);
  }

  Future<void> saveEpisode(AdminEpisodeDto episode) async {
    await ref.read(adminApiProvider).saveEpisode(episode);
    ref
      ..invalidate(episodeListProvider(episode.programId))
      ..invalidate(programListProvider);
  }

  Future<void> setEpisodeStatus({
    required AdminEpisodeDto episode,
    required EpisodeStatus status,
  }) async {
    await ref
        .read(adminApiProvider)
        .setEpisodeStatus(id: episode.id, status: status);
    ref
      ..invalidate(episodeListProvider(episode.programId))
      ..invalidate(programListProvider);
  }
}
