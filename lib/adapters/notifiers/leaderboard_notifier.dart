import 'package:flutter_riverpod/legacy.dart';

import '../../application/dtos/leaderboard_entry_dto.dart';
import '../../application/use_cases/progress/get_leaderboard_use_case.dart';

class LeaderboardNotifier extends StateNotifier<List<LeaderboardEntryDTO>> {
  final GetLeaderboardUseCase getLeaderboardUseCase;

  LeaderboardNotifier(this.getLeaderboardUseCase) : super(const []);

  Future<void> loadLeaderboard(String levelId, {int limit = 10}) async {
    state = await getLeaderboardUseCase.execute(levelId, limit);
  }

  List<LeaderboardEntryDTO> getEntries() => state;
}
