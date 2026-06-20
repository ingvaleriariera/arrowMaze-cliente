import '../../../domain/entities/game_session.dart';
import '../../../domain/entities/move_result.dart';
import '../../ports/i_audio_service.dart';

class ActivateArrowUseCase {
  final IAudioService audioService;

  ActivateArrowUseCase(this.audioService);

  MoveResult execute(GameSession session, String arrowId) {
    final result = session.executeMove(arrowId);
    if (result.isSuccess()) {
      audioService.playEffect('arrow_exit');
    }
    return result;
  }
}
