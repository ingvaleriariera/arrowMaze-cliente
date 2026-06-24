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

      debugPrint('✅ LevelSelectNotifier: Received ${summaries.length} summaries (before sorting)');

      // Sort levels by numeric ID
      final sortedSummaries = List.of(summaries);
      sortedSummaries.sort((a, b) {
        final numA = int.tryParse(a.levelId.replaceAll('level-', '')) ?? 0;
        final numB = int.tryParse(b.levelId.replaceAll('level-', '')) ?? 0;
        return numA.compareTo(numB);
      });

      debugPrint('✅ LevelSelectNotifier: After sorting:');
      for (var i = 0; i < sortedSummaries.length; i++) {
        debugPrint('   Position $i: id=${sortedSummaries[i].levelId}, difficulty=${sortedSummaries[i].difficulty}');
      }

      debugPrint('🔄 LevelSelectNotifier: Updating state with isLoading=false');
      state = state.copyWith(
        levels: sortedSummaries,
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
