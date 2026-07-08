import 'package:arrow_maze_cliente_copy/application/dtos/global_leaderboard_entry_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_leaderboard_repository.dart';

class GetGlobalLeaderboardUseCase {
  final ILeaderboardRepository leaderboardRepository;

  GetGlobalLeaderboardUseCase({required this.leaderboardRepository});

  Future<List<GlobalLeaderboardEntryDTO>> execute(int limit) async {
    return leaderboardRepository.getGlobalTopScores(limit);
  }
}
