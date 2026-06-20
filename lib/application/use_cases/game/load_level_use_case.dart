import '../../../domain/builders/board_builder.dart';
import '../../../domain/engine/level_generator.dart';
import '../../../domain/entities/game_session.dart';
import '../../../domain/ports/i_level_repository.dart';

class LoadLevelUseCase {
  final ILevelRepository levelRepository;

  LoadLevelUseCase(this.levelRepository);

  Future<GameSession> execute(String levelId) async {
    final levels = await levelRepository.getLevels();
    final level = levels.firstWhere((l) => l.getId() == levelId);

    final shape = level.getBoardShape();
    final arrows = LevelGenerator().generate(shape);

    final builder = BoardBuilder.create().setShape(shape);
    for (final arrow in arrows) {
      builder.addArrow(arrow);
    }
    final board = builder.build();

    return GameSession(board, level.getId(), level.getMoveLimit(), level.getTimeLimit());
  }
}
