import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/custom_aware_level_repository.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/level_select_state.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/level_summary_dto.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/boards/manage_my_boards_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/get_level_summaries_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/preload_levels_use_case.dart';

class LevelSelectNotifier extends StateNotifier<LevelSelectState> {
  final GetLevelSummariesUseCase getLevelSummariesUseCase;
  final PreloadLevelsUseCase preloadLevelsUseCase;
  final ManageMyBoardsUseCase manageMyBoardsUseCase;

  LevelSelectNotifier({
    required this.getLevelSummariesUseCase,
    required this.preloadLevelsUseCase,
    required this.manageMyBoardsUseCase,
  }) : super(const LevelSelectState());

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

      // Adopted community boards appear after the standard progression:
      // always unlocked (they're free play, outside the sequential
      // unlock chain) and labeled with their board name.
      final myBoards = await manageMyBoardsUseCase.getAll();
      final customSummaries = myBoards
          .map((board) => LevelSummaryDTO(
                levelId: CustomAwareLevelRepository.levelIdFor(board.id),
                difficulty: board.difficulty,
                completed: false,
                bestScore: 0,
                isTimed: board.difficulty.toLowerCase() == 'hard',
                unlocked: true,
                displayName: board.name,
              ))
          .toList();

      debugPrint('🔄 LevelSelectNotifier: Updating state with isLoading=false '
          '(${sortedSummaries.length} standard + ${customSummaries.length} custom)');
      state = state.copyWith(
        levels: [...sortedSummaries, ...customSummaries],
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

  Future<void> preloadAllLevels() async {
    if (state.levels.isEmpty || state.isPreloadingAll) return;

    final levelIds = state.levels.map((l) => l.levelId).toList();
    debugPrint('📦 LevelSelectNotifier: Preloading all ${levelIds.length} levels');
    state = state.copyWith(
      isPreloadingAll: true,
      preloadCompleted: 0,
      preloadTotal: levelIds.length,
    );

    try {
      await preloadLevelsUseCase.execute(
        levelIds,
        onProgress: (completed, total) {
          // Each callback fires after one level's generation finishes on
          // the background isolate, so updating state here animates a
          // real progress bar instead of a single before/after jump.
          state = state.copyWith(preloadCompleted: completed, preloadTotal: total);
        },
      );
    } catch (e) {
      debugPrint('⚠️  LevelSelectNotifier: preloadAllLevels failed - $e');
    } finally {
      state = state.copyWith(isPreloadingAll: false);
    }
  }
}
