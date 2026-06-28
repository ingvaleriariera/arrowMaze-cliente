import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_generation_request.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_board_cache.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

class LoadLevelUseCase {
  final ILevelRepository levelRepository;
  final IBoardCache boardCache;

  LoadLevelUseCase({required this.levelRepository, required this.boardCache});

  Future<GameSession> execute(String levelId) async {
    debugPrint('🎮 LoadLevelUseCase.execute: Loading levelId=$levelId');

    final level = await levelRepository.getLevel(levelId);
    debugPrint('   Level loaded: ${level.id}');

    // A PreloadLevelsUseCase run may have already generated this board in
    // the background while the player was on a previous level — skip the
    // (expensive) generation entirely when that's the case.
    final cachedBoard = boardCache.take(levelId);
    final Board board;
    final int calculatedMaxMoves;
    if (cachedBoard != null) {
      debugPrint('⚡ LoadLevelUseCase: Using preloaded board for $levelId');
      board = cachedBoard;
      calculatedMaxMoves =
          BoardBuilder.calculateMaxMoves(board.arrows.length, level.difficulty.toUpperCase());
    } else {
      // Deterministic seed from levelId so every player sees the same
      // arrow layout for a given level (keeps leaderboard scores comparable).
      // Generation runs on a background isolate (a Web Worker on web) via
      // compute() so it never blocks the UI thread/frame rendering.
      debugPrint('   Generating arrows with difficulty=${level.difficulty} (background isolate)...');
      final result = await compute(
        generateBoard,
        BoardGenerationRequest(
          seed: level.id.hashCode,
          boardLayoutJson: level.boardLayout,
          difficulty: level.difficulty,
        ),
      );
      board = result.board;
      calculatedMaxMoves = result.maxMoves;
    }
    debugPrint('✅ LoadLevelUseCase: Board built with ${board.arrows.length} arrows');
    debugPrint('   Calculated maxMoves: $calculatedMaxMoves (margin for ${level.difficulty})');

    // DEBUG: Print each arrow's blockedBy
    debugPrint('🔍 COLLISION DEBUG:');
    for (final arrow in board.arrows.values) {
      final node = board.graph.nodes[arrow.id];
      final blockedBy = node?.blockedBy ?? {};
      final pos = arrow.getHead().position;
      debugPrint('   Arrow ${arrow.id}: pos=(${pos.x},${pos.y}) blockedBy=$blockedBy');
    }

    final activatable = board.graph.getActivatable();
    debugPrint('🎯 Activatable at start: $activatable (${activatable.length}/${board.arrows.length})');

    final session = GameSession(
      board: board,
      levelId: level.id,
      maxMoves: calculatedMaxMoves,
      timeRemaining: level.isTimed() ? level.timeLimit.getValue() : null,
    );

    return session;
  }
}
