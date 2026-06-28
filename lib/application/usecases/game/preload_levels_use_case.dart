import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_generation_request.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_board_cache.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

/// Generates and caches boards for upcoming levels ahead of time, so that
/// LoadLevelUseCase can skip generation entirely once the player actually
/// selects one of them. Best-effort: a level that fails to preload just
/// falls back to the normal on-demand path in LoadLevelUseCase.
class PreloadLevelsUseCase {
  final ILevelRepository levelRepository;
  final IBoardCache boardCache;

  PreloadLevelsUseCase({required this.levelRepository, required this.boardCache});

  /// [onProgress], if given, is called after each level id is processed
  /// (whether it succeeded, failed, or was already cached) with the
  /// number done so far and the total — enough for a UI progress bar.
  Future<void> execute(
    List<String> levelIds, {
    void Function(int completed, int total)? onProgress,
  }) async {
    for (int i = 0; i < levelIds.length; i++) {
      final levelId = levelIds[i];

      if (boardCache.has(levelId)) {
        onProgress?.call(i + 1, levelIds.length);
        continue;
      }

      try {
        final level = await levelRepository.getLevel(levelId);
        // Generation runs on a background isolate (a Web Worker on web)
        // via compute() so it never blocks the UI thread, no matter how
        // many levels are being preloaded in a row.
        final result = await compute(
          generateBoard,
          BoardGenerationRequest(
            seed: level.id.hashCode,
            boardLayoutJson: level.boardLayout,
            difficulty: level.difficulty,
          ),
        );
        boardCache.put(levelId, result.board);
        debugPrint('📦 PreloadLevelsUseCase: Cached board for $levelId');
      } catch (e) {
        debugPrint('⚠️  PreloadLevelsUseCase: Failed to preload $levelId — $e');
      }

      onProgress?.call(i + 1, levelIds.length);
    }
  }
}
