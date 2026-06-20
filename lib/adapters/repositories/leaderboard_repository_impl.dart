import '../../application/dtos/leaderboard_entry_dto.dart';
import '../../application/dtos/submit_score_result_dto.dart';
import '../../application/ports/i_leaderboard_repository.dart';
import '../api/api_client.dart';

class LeaderboardRepositoryImpl implements ILeaderboardRepository {
  final ApiClient apiClient;

  LeaderboardRepositoryImpl(this.apiClient);

  @override
  Future<List<LeaderboardEntryDTO>> getTopScores(String levelId, int limit) async {
    final response = await apiClient.get('/leaderboard/$levelId');
    final entries = response['entries'] as List<dynamic>;
    return entries.take(limit).map((json) {
      final entry = json as Map<String, dynamic>;
      return LeaderboardEntryDTO(
        entry['rank'] as int,
        entry['username'] as String,
        entry['score'] as int,
        levelId,
      );
    }).toList();
  }

  @override
  Future<SubmitScoreResultDTO> submitScore(String userId, String levelId, int score) async {
    final response = await apiClient.post('/scores/submit', {
      'userId': userId,
      'levelId': levelId,
      'score': score,
    });
    return SubmitScoreResultDTO(
      response['accepted'] as bool,
      response['qualifiedForLeaderboard'] as bool,
    );
  }
}
