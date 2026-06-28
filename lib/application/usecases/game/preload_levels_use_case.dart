import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
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

  Future<void> execute(List<String> levelIds) async {
    for (final levelId in levelIds) {
      if (boardCache.has(levelId)) continue;

      try {
        final level = await levelRepository.getLevel(levelId);
        final shape = level.getBoardShape();
        final builder = BoardBuilder.create(seed: level.id.hashCode)
            .setShape(shape)
            .setDifficulty(level.difficulty);
        final board = builder.build();
        boardCache.put(levelId, board);
        debugPrint('📦 PreloadLevelsUseCase: Cached board for $levelId');
      } catch (e) {
        debugPrint('⚠️  PreloadLevelsUseCase: Failed to preload $levelId — $e');
      }
    }
  }
}
