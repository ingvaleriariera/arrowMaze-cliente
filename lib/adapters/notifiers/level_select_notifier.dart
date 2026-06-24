import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/level_select_state.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/get_level_summaries_use_case.dart';

class LevelSelectNotifier extends StateNotifier<LevelSelectState> {
  final GetLevelSummariesUseCase getLevelSummariesUseCase;

  LevelSelectNotifier({required this.getLevelSummariesUseCase})
      : super(const LevelSelectState());

  Future<void> loadSummaries(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summaries = await getLevelSummariesUseCase.execute(userId);
      state = state.copyWith(
        levels: summaries,
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
