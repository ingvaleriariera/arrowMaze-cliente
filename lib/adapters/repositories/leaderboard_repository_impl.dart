import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/global_leaderboard_entry_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements ILeaderboardRepository {
  final ApiClient apiClient;

  LeaderboardRepositoryImpl({required this.apiClient});

  @override
  Future<List<LeaderboardEntryDTO>> getTopScores(String levelId, int limit) async {
    final json = await apiClient.get('/api/v1/leaderboard/$levelId?limit=$limit');
    final entriesList = json['entries'] as List<dynamic>? ?? [];

    return entriesList.map((entry) {
      final e = entry as Map<String, dynamic>;
      return LeaderboardEntryDTO(
        rank: e['rank'] as int,
        username: e['username'] as String,
        score: e['score'] as int,
        levelId: levelId,
      );
    }).toList();
  }

  @override
  Future<List<GlobalLeaderboardEntryDTO>> getGlobalTopScores(int limit) async {
    final json = await apiClient.get('/api/v1/leaderboard/global?limit=$limit');
    final entriesList = json['entries'] as List<dynamic>? ?? [];

    return entriesList.map((entry) {
      final e = entry as Map<String, dynamic>;
      return GlobalLeaderboardEntryDTO(
        rank: e['rank'] as int,
        username: e['username'] as String,
        totalScore: e['totalScore'] as int,
      );
    }).toList();
  }
}
