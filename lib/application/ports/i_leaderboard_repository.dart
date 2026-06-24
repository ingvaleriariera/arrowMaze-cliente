import 'package:arrow_maze_cliente_copy/application/dtos/leaderboard_entry_dto.dart';

abstract class ILeaderboardRepository {
  Future<List<LeaderboardEntryDTO>> getTopScores(String levelId, int limit);
}
