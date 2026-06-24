import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

class LoadLevelUseCase {
  final ILevelRepository levelRepository;

  LoadLevelUseCase({required this.levelRepository});

  Future<GameSession> execute(String levelId) async {
    final level = await levelRepository.getLevel(levelId);
    final shape = level.getBoardShape();

    // For now, create an empty board (no arrows)
    // In a real scenario, the backend would provide the board layout
    final board = BoardBuilder.create().setShape(shape).build();

    final session = GameSession(
      board: board,
      levelId: level.id,
      maxMoves: level.moveLimit,
      timeRemaining: level.isTimed() ? level.timeLimit.getValue() : null,
    );

    return session;
  }
}
