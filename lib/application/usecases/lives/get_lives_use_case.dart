import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_lives_repository.dart';

/// Loads the player's life pool, applying any regeneration that came due
/// while the app was closed (regen is lazy — computed on read from the
/// stored timestamps, no background process involved).
class GetLivesUseCase {
  final ILivesRepository livesRepository;

  GetLivesUseCase({required this.livesRepository});

  Future<PlayerLives> execute(String userId) async {
    final stored = await livesRepository.load(userId);
    final current = stored.regenerated(DateTime.now());
    if (current.lives != stored.lives) {
      await livesRepository.save(userId, current);
    }
    return current;
  }
}
