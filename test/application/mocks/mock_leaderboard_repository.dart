import 'package:arrow_maze_cliente_copy/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/global_leaderboard_entry_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_leaderboard_repository.dart';

class MockLeaderboardRepository implements ILeaderboardRepository {
  @override
  Future<List<LeaderboardEntryDTO>> getTopScores(String levelId, int limit) async {
    final entries = [
      LeaderboardEntryDTO(
        rank: 1,
        username: 'player1',
        score: 500,
        levelId: levelId,
      ),
      LeaderboardEntryDTO(
        rank: 2,
        username: 'player2',
        score: 450,
        levelId: levelId,
      ),
      LeaderboardEntryDTO(
        rank: 3,
        username: 'player3',
        score: 400,
        levelId: levelId,
      ),
    ];

    return entries.take(limit).toList();
  }

  @override
  Future<List<GlobalLeaderboardEntryDTO>> getGlobalTopScores(int limit) async {
    final entries = [
      GlobalLeaderboardEntryDTO(rank: 1, username: 'player1', totalScore: 1500),
      GlobalLeaderboardEntryDTO(rank: 2, username: 'player2', totalScore: 1200),
      GlobalLeaderboardEntryDTO(rank: 3, username: 'player3', totalScore: 900),
    ];

    return entries.take(limit).toList();
  }
}
