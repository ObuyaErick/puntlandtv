import '../../../../core/domain/page.dart';
import '../entities/program.dart';

abstract interface class VodRepository {
  Future<List<Program>> programs();

  Future<Page<Episode>> episodes({String? programId, String? cursor});
}
