import 'package:arrow_maze_cliente_copy/application/ports/i_audio_service.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up_result.dart';

class UsePowerUpUseCase {
  final IGameProgressRepository progressRepository;
  final IAudioService audioService;

  UsePowerUpUseCase({
    required this.progressRepository,
    required this.audioService,
  });

  Future<PowerUpResult> execute(
    GameSession session,
    PowerUp powerUp,
    GameProgress progress,
  ) async {
    // Check if player has enough coins
    if (!progress.spendCoins(powerUp.getCost())) {
      return PowerUpResult.applyFailure('Not enough coins');
    }

    // Apply the power-up via the session (not powerUp.use(session.board)
    // directly) so a board cleared/deadlocked by it also transitions
    // GameSession out of PlayingState, same as a normal move would.
    final result = session.applyPowerUp(powerUp);

    // Only persist and play sound if application was successful
    if (result.success) {
      await progressRepository.save(progress);
      await audioService.playEffect('power_up');
    } else {
      // Refund the coins if power-up couldn't be applied
      progress.addCoins(powerUp.getCost());
    }

    return result;
  }
}
