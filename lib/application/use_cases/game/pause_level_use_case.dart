import '../../../domain/entities/game_session.dart';

class PauseLevelUseCase {
  void execute(GameSession session) {
    session.pause();
  }
}
