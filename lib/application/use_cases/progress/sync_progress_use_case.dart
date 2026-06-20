import '../../../domain/entities/game_progress.dart';
import '../../../domain/ports/i_game_progress_repository.dart';

class SyncProgressUseCase {
  final IGameProgressRepository progressRepository;

  SyncProgressUseCase(this.progressRepository);

  Future<GameProgress> execute(String userId) => progressRepository.sync(userId);
}
