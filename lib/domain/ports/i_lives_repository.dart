import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';

/// Persistence port for the player's life pool. Device-local by design
/// (like the avatar): lives are a pacing mechanic, not progress worth
/// syncing to the backend or comparing between players.
abstract class ILivesRepository {
  /// The stored pool for [userId], or a full pool for a player who has
  /// never lost a life.
  Future<PlayerLives> load(String userId);

  Future<void> save(String userId, PlayerLives lives);
}
