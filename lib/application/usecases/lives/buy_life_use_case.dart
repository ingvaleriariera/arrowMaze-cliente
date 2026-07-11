import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_lives_repository.dart';

/// Exchanges coins for one life. Orchestrates the two repositories so the
/// trade is atomic from the caller's point of view: coins are only spent
/// if a life can actually be granted, and the life is only granted if the
/// player could afford it.
class BuyLifeUseCase {
  static const int lifeCostInCoins = 100;

  final ILivesRepository livesRepository;
  final IGameProgressRepository progressRepository;

  BuyLifeUseCase({
    required this.livesRepository,
    required this.progressRepository,
  });

  /// Returns the updated pool, or null when the purchase wasn't possible
  /// (pool already full, no progress record, or not enough coins).
  Future<PlayerLives?> execute(String userId) async {
    final current =
        (await livesRepository.load(userId)).regenerated(DateTime.now());
    if (current.isFull) return null;

    final progress = await progressRepository.get(userId);
    if (progress == null || !progress.spendCoins(lifeCostInCoins)) {
      return null;
    }
    await progressRepository.save(progress);

    final updated = current.afterGainingLife();
    await livesRepository.save(userId, updated);
    return updated;
  }
}
