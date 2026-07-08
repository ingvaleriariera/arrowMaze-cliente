import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/leaderboard_state.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/leaderboard/get_leaderboard_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/leaderboard/get_global_leaderboard_use_case.dart';

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final GetLeaderboardUseCase getLeaderboardUseCase;
  final GetGlobalLeaderboardUseCase getGlobalLeaderboardUseCase;

  LeaderboardNotifier({
    required this.getLeaderboardUseCase,
    required this.getGlobalLeaderboardUseCase,
  }) : super(const LeaderboardState());

  Future<void> loadLeaderboard(String levelId) async {
    state = state.copyWith(mode: LeaderboardMode.perLevel, isLoading: true, error: null);
    try {
      final entries = await getLeaderboardUseCase.execute(levelId, 10);
      state = state.copyWith(
        entries: entries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadGlobalLeaderboard() async {
    state = state.copyWith(mode: LeaderboardMode.global, isLoading: true, error: null);
    try {
      final entries = await getGlobalLeaderboardUseCase.execute(10);
      state = state.copyWith(
        globalEntries: entries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
