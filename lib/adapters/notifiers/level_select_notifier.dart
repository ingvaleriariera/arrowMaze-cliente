import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/level_select_state.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/get_level_summaries_use_case.dart';

class LevelSelectNotifier extends StateNotifier<LevelSelectState> {
  final GetLevelSummariesUseCase getLevelSummariesUseCase;

  LevelSelectNotifier({required this.getLevelSummariesUseCase})
      : super(const LevelSelectState());

  Future<void> loadSummaries(String userId) async {
    debugPrint('🔄 LevelSelectNotifier: Starting loadSummaries for userId=$userId');
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('📞 LevelSelectNotifier: Calling getLevelSummariesUseCase.execute()');
      final summaries = await getLevelSummariesUseCase.execute(userId);
      
      debugPrint('✅ LevelSelectNotifier: Received ${summaries.length} summaries');
      for (var i = 0; i < summaries.length; i++) {
        debugPrint('   Level $i: id=${summaries[i].levelId}, difficulty=${summaries[i].difficulty}, completed=${summaries[i].completed}');
      }

      debugPrint('🔄 LevelSelectNotifier: Updating state with isLoading=false');
      state = state.copyWith(
        levels: summaries,
        isLoading: false,
      );
      debugPrint('✅ LevelSelectNotifier: State updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ LevelSelectNotifier: Error caught in loadSummaries');
      debugPrint('   Exception: $e');
      debugPrint('   StackTrace: $stackTrace');
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
