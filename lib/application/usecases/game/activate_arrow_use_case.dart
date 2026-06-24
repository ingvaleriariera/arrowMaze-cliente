import 'package:arrow_maze_cliente_copy/application/ports/i_audio_service.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/move_result.dart';

class ActivateArrowUseCase {
  final IAudioService audioService;

  ActivateArrowUseCase({required this.audioService});

  Future<MoveResult> execute(GameSession session, String arrowId) async {
    final result = session.executeMove(arrowId);

    if (result.success) {
      await audioService.playEffect('arrow_exit');
    }

    return result;
  }
}
