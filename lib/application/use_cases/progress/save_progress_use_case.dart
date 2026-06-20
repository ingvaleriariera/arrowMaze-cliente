import '../../../domain/entities/game_progress.dart';
import '../../../domain/ports/i_game_progress_repository.dart';

class SaveProgressUseCase {
  final IGameProgressRepository progressRepository;

  SaveProgressUseCase(this.progressRepository);

  Future<void> execute(GameProgress progress) => progressRepository.save(progress);
}
