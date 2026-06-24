import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';

class SyncProgressUseCase {
  final IGameProgressRepository progressRepository;

  SyncProgressUseCase({required this.progressRepository});

  Future<GameProgress> execute(String userId) async {
    return progressRepository.sync(userId);
  }
}
