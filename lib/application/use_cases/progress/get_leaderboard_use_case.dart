import '../../dtos/leaderboard_entry_dto.dart';
import '../../ports/i_leaderboard_repository.dart';

class GetLeaderboardUseCase {
  final ILeaderboardRepository leaderboardRepository;

  GetLeaderboardUseCase(this.leaderboardRepository);

  Future<List<LeaderboardEntryDTO>> execute(String levelId, int limit) =>
      leaderboardRepository.getTopScores(levelId, limit);
}
