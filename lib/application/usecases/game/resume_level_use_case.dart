import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';

class ResumeLevelUseCase {
  Future<void> execute(GameSession session) async {
    session.resume();
  }
}
