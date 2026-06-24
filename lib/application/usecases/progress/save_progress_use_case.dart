import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';

class SaveProgressUseCase {
  final IGameProgressRepository progressRepository;

  SaveProgressUseCase({required this.progressRepository});

  Future<void> execute(GameProgress progress) async {
    return progressRepository.save(progress);
  }
}
