import '../../../domain/entities/game_progress.dart';
import '../../../domain/entities/game_session.dart';
import '../../../domain/entities/power_up_result.dart';
import '../../../domain/ports/i_game_progress_repository.dart';
import '../../../domain/power_ups/power_up.dart';
import '../../ports/i_audio_service.dart';

class UsePowerUpUseCase {
  final IGameProgressRepository progressRepository;
  final IAudioService audioService;

  UsePowerUpUseCase(this.progressRepository, this.audioService);

  Future<PowerUpResult> execute(
    GameSession session,
    PowerUp powerUp,
    GameProgress progress,
  ) async {
    if (!progress.spendCoins(powerUp.getCost())) {
      return PowerUpResult.failure('Not enough coins');
    }

    final result = session.applyPowerUp(powerUp);
    await progressRepository.save(progress);
    audioService.playEffect('power_up_${powerUp.getType()}');
    return result;
  }
}
