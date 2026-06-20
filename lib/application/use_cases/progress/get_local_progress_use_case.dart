import '../../../domain/entities/game_progress.dart';
import '../../../domain/ports/i_game_progress_repository.dart';

class GetLocalProgressUseCase {
  final IGameProgressRepository progressRepository;

  GetLocalProgressUseCase(this.progressRepository);

  Future<GameProgress?> execute(String userId) => progressRepository.get(userId);
}
