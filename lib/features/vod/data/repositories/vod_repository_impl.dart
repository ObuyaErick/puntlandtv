import '../../../../core/api/puntland_api.dart';
import '../../../../core/domain/page.dart';
import '../../domain/entities/program.dart';
import '../../domain/repositories/vod_repository.dart';

class VodRepositoryImpl implements VodRepository {
  const VodRepositoryImpl(this._api);

  final PuntlandApi _api;

  @override
  Future<List<Program>> programs() async {
    final dtos = await _api.fetchPrograms();
    return dtos
        .map(
          (e) => Program(
            id: e.id,
            title: e.title,
            episodeCount: e.episodeCount,
            artworkUrl: e.artworkUrl,
            cadence: e.cadence,
            genre: e.genre,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Page<Episode>> episodes({String? programId, String? cursor}) async {
    final page = await _api.fetchEpisodes(programId: programId, cursor: cursor);
    return Page<Episode>(
      items: page.data
          .map(
            (e) => Episode(
              id: e.id,
              programId: e.programId,
              title: e.title,
              airedAt: e.airedAt,
              duration: Duration(seconds: e.durationSeconds),
              playbackUrl: e.playbackUrl,
              thumbnailUrl: e.thumbnailUrl,
            ),
          )
          .toList(growable: false),
      nextCursor: page.nextCursor,
    );
  }
}
