import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/level_summary_dto.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

class GetLevelSummariesUseCase {
  final ILevelRepository levelRepository;
  final IGameProgressRepository progressRepository;

  GetLevelSummariesUseCase({
    required this.levelRepository,
    required this.progressRepository,
  });

  Future<List<LevelSummaryDTO>> execute(String userId) async {
    debugPrint('🎮 GetLevelSummariesUseCase.execute: Starting for userId=$userId');
    
    try {
      // Step 1: Load levels from backend - this is critical and must succeed
      debugPrint('📊 GetLevelSummariesUseCase: Fetching levels from backend...');
      final levels = await levelRepository.getLevels();
      debugPrint('✅ GetLevelSummariesUseCase: Got ${levels.length} levels from backend');

      if (levels.isEmpty) {
        debugPrint('⚠️  GetLevelSummariesUseCase: No levels available from backend');
        return [];
      }

      // Step 2: Try to load progress - but don't let it block levels
      GameProgress? progress;
      try {
        debugPrint('💾 GetLevelSummariesUseCase: Fetching progress for $userId...');
        progress = await progressRepository.get(userId);
        if (progress != null) {
          debugPrint('✅ GetLevelSummariesUseCase: Got progress with ${progress.completedLevels.length} completed levels');
        } else {
          debugPrint('ℹ️  GetLevelSummariesUseCase: No progress for user (null) - new user');
        }
      } catch (e) {
        debugPrint('⚠️  GetLevelSummariesUseCase: Progress fetch failed (non-blocking) - $e');
        progress = null;
      }

      // Step 3: Build summaries - use empty progress if null
      final effectiveProgress = progress ?? GameProgress(userId: userId);
      debugPrint('🔄 GetLevelSummariesUseCase: Using effective progress: ${effectiveProgress.completedLevels.length} completed, ${effectiveProgress.coins} coins');

      final summaries = <LevelSummaryDTO>[];

      for (final level in levels) {
        final isCompleted = effectiveProgress.isCompleted(level.id);
        final bestScore = effectiveProgress.getBestScore(level.id) ?? 0;

        debugPrint('📝 GetLevelSummariesUseCase: Level ${level.id} - completed: $isCompleted, score: $bestScore');

        summaries.add(
          LevelSummaryDTO(
            levelId: level.id,
            difficulty: level.difficulty,
            completed: isCompleted,
            bestScore: bestScore,
            isTimed: level.isTimed(),
          ),
        );
      }

      debugPrint('✅ GetLevelSummariesUseCase: Created ${summaries.length} level summaries');
      return summaries;
    } catch (e, stackTrace) {
      debugPrint('❌ GetLevelSummariesUseCase: Fatal error - $e');
      debugPrint('   StackTrace: $stackTrace');
      rethrow;
    }
  }
}
