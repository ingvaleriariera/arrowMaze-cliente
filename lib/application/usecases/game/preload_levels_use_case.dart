import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_generation_request.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_board_cache.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

/// Generates and caches the arrow layout for upcoming levels ahead of
/// time, so that LoadLevelUseCase can skip the expensive randomized
/// search entirely once the player actually selects one of them — for
/// the rest of the app's lifetime, not just the next visit. Best-effort:
/// a level that fails to preload just falls back to the normal on-demand
/// path in LoadLevelUseCase.
class PreloadLevelsUseCase {
  final ILevelRepository levelRepository;
  final IBoardCache boardCache;

  /// Must match LoadLevelUseCase's depth — they share the depth-keyed
  /// cache, so a preloaded layout only counts as a hit at the same depth.
  final int boardDepth;

  PreloadLevelsUseCase({
    required this.levelRepository,
    required this.boardCache,
    this.boardDepth = kBoardDepth,
  });

  String _cacheKey(String levelId) => '$levelId#d$boardDepth';

  /// [onProgress], if given, is called after each level id is processed
  /// (whether it succeeded, failed, or was already cached) with the
  /// number done so far and the total — enough for a UI progress bar.
  Future<void> execute(
    List<String> levelIds, {
    void Function(int completed, int total)? onProgress,
  }) async {
    for (int i = 0; i < levelIds.length; i++) {
      final levelId = levelIds[i];

      if (!boardCache.has(_cacheKey(levelId))) {
        try {
          final level = await levelRepository.getLevel(levelId);
          // Generation runs on a background isolate via compute() — a
          // real OS thread on native platforms. (On web, compute() still
          // runs inline today; see LoadLevelUseCase's note.)
          final result = await compute(
            generateBoard,
            BoardGenerationRequest(
              seed: level.id.hashCode,
              boardLayoutJson: level.boardLayout,
              difficulty: level.difficulty,
              depth: boardDepth,
            ),
          );
          boardCache.put(_cacheKey(levelId), result.board.arrows.values.toList());
          debugPrint('📦 PreloadLevelsUseCase: Cached layout for $levelId');
        } catch (e) {
          debugPrint('⚠️  PreloadLevelsUseCase: Failed to preload $levelId — $e');
        }
      }

      onProgress?.call(i + 1, levelIds.length);

      // Force a real event-loop turn between levels. Without it, this
      // loop's awaits all resolve as microtasks chained back-to-back, so
      // the browser/engine never gets a chance to actually paint the
      // progress bar (or process taps) until the whole batch is done —
      // it just looks frozen even though state is updating underneath.
      await Future.delayed(Duration.zero);
    }
  }
}
