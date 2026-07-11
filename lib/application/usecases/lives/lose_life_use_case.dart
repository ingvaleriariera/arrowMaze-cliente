import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_lives_repository.dart';

/// Deducts one life (defeat, or abandoning a level mid-run) and persists
/// the result. Regeneration due up to this moment is applied first so a
/// pending refill isn't silently swallowed by the loss.
class LoseLifeUseCase {
  final ILivesRepository livesRepository;

  LoseLifeUseCase({required this.livesRepository});

  Future<PlayerLives> execute(String userId) async {
    final now = DateTime.now();
    final current = (await livesRepository.load(userId)).regenerated(now);
    final updated = current.afterLosingLife(now);
    await livesRepository.save(userId, updated);
    return updated;
  }
}
