import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';

class PauseLevelUseCase {
  Future<void> execute(GameSession session) async {
    session.pause();
  }
}
