import '../../../domain/entities/game_session.dart';

class ResumeLevelUseCase {
  void execute(GameSession session) {
    session.resume();
  }
}
