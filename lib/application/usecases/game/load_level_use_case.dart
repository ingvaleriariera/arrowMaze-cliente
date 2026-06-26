import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

class LoadLevelUseCase {
  final ILevelRepository levelRepository;

  LoadLevelUseCase({required this.levelRepository});

  Future<GameSession> execute(String levelId) async {
    debugPrint('🎮 LoadLevelUseCase.execute: Loading levelId=$levelId');

    // TEST: Verify Position.translate() correctness
    debugPrint('📍 Position.translate() test:');
    final testPos = Position(2, 3);
    debugPrint('  right: ${testPos.translate(Direction.right).toKey()} (expect 3,3)');
    debugPrint('  down:  ${testPos.translate(Direction.down).toKey()} (expect 2,4)');
    debugPrint('  up:    ${testPos.translate(Direction.up).toKey()} (expect 2,2)');
    debugPrint('  left:  ${testPos.translate(Direction.left).toKey()} (expect 1,3)');

    final level = await levelRepository.getLevel(levelId);
    debugPrint('   Level loaded: ${level.id}');

    final shape = level.getBoardShape();
    final validCells = shape.getCells();
    debugPrint('   Board shape: ${validCells.length} valid cells');

    // TEST: Verify remaining uses same key format as position.toKey()
    debugPrint('📋 Remaining keys format test (first 5):');
    final remaining = shape.validCells;
    remaining.take(5).forEach((key) => debugPrint('  key: "$key"'));
    debugPrint('   Position.toKey() format:');
    validCells.take(5).forEach((pos) => debugPrint('  pos: "${pos.toKey()}"'));

    // Generate arrows automatically based on difficulty
    final difficultyMap = {
      'EASY': 1,
      'MEDIUM': 2,
      'HARD': 3,
    };
    final difficultyInt = difficultyMap[level.difficulty] ?? 1;

    // Deterministic seed from levelId so every player sees the same arrow
    // layout for a given level (keeps leaderboard scores comparable).
    final builder = BoardBuilder.create(seed: level.id.hashCode)
        .setShape(shape)
        .setDifficulty(difficultyInt, difficultyStr: level.difficulty);

    debugPrint('   Generating arrows with difficulty=${level.difficulty} (int: $difficultyInt)...');

    final board = builder.build();
    debugPrint('✅ LoadLevelUseCase: Board built with ${board.arrows.length} arrows');

    // Use calculated maxMoves from builder instead of backend moveLimit
    final calculatedMaxMoves = builder.getCalculatedMaxMoves();
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
      maxMoves: calculatedMaxMoves ?? level.moveLimit,
      timeRemaining: level.isTimed() ? level.timeLimit.getValue() : null,
    );

    return session;
  }
}
