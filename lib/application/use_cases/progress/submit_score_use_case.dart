import '../../dtos/submit_score_result_dto.dart';
import '../../ports/i_leaderboard_repository.dart';

class SubmitScoreUseCase {
  final ILeaderboardRepository leaderboardRepository;

  SubmitScoreUseCase(this.leaderboardRepository);

  Future<SubmitScoreResultDTO> execute(String userId, String levelId, int score) =>
      leaderboardRepository.submitScore(userId, levelId, score);
}
