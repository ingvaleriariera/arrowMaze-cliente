import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

class LoadLevelUseCase {
  final ILevelRepository levelRepository;

  LoadLevelUseCase({required this.levelRepository});

  Future<GameSession> execute(String levelId) async {
    debugPrint('🎮 LoadLevelUseCase.execute: Loading levelId=$levelId');

    final level = await levelRepository.getLevel(levelId);
    debugPrint('   Level loaded: ${level.id}');

    final shape = level.getBoardShape();
    final validCells = shape.getCells();
    debugPrint('   Board shape: ${validCells.length} valid cells');

    // Generate arrows automatically based on difficulty
    final difficultyMap = {
      'EASY': 1,
      'MEDIUM': 2,
      'HARD': 3,
    };
    final difficultyInt = difficultyMap[level.difficulty] ?? 1;

    final builder = BoardBuilder.create()
        .setShape(shape)
        .setDifficulty(difficultyInt);

    debugPrint('   Generating arrows with difficulty=${level.difficulty} (int: $difficultyInt)...');

    final board = builder.build();
    debugPrint('✅ LoadLevelUseCase: Board built with ${board.arrows.length} arrows');

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
      maxMoves: level.moveLimit,
      timeRemaining: level.isTimed() ? level.timeLimit.getValue() : null,
    );

    return session;
  }
}
