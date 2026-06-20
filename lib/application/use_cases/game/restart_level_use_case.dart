import '../../../domain/entities/game_session.dart';
import 'load_level_use_case.dart';

class RestartLevelUseCase {
  final LoadLevelUseCase loadLevelUseCase;

  RestartLevelUseCase(this.loadLevelUseCase);

  Future<GameSession> execute(String levelId) => loadLevelUseCase.execute(levelId);
}
