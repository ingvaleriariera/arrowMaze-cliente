import 'package:arrow_maze_cliente_copy/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/global_leaderboard_entry_dto.dart';

abstract class ILeaderboardRepository {
  Future<List<LeaderboardEntryDTO>> getTopScores(String levelId, int limit);
  Future<List<GlobalLeaderboardEntryDTO>> getGlobalTopScores(int limit);
}
