import 'package:arrow_maze_cliente_copy/application/usecases/game/load_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';

class RestartLevelUseCase {
  final LoadLevelUseCase loadLevelUseCase;

  RestartLevelUseCase({required this.loadLevelUseCase});

  Future<GameSession> execute(String levelId) async {
    return loadLevelUseCase.execute(levelId);
  }
}
