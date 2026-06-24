import 'package:arrow_maze_cliente_copy/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_leaderboard_repository.dart';

class GetLeaderboardUseCase {
  final ILeaderboardRepository leaderboardRepository;

  GetLeaderboardUseCase({required this.leaderboardRepository});

  Future<List<LeaderboardEntryDTO>> execute(String levelId, int limit) async {
    return leaderboardRepository.getTopScores(levelId, limit);
  }
}
