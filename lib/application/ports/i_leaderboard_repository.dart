import '../dtos/leaderboard_entry_dto.dart';
import '../dtos/submit_score_result_dto.dart';

abstract class ILeaderboardRepository {
  Future<List<LeaderboardEntryDTO>> getTopScores(String levelId, int limit);
  Future<SubmitScoreResultDTO> submitScore(String userId, String levelId, int score);
}
