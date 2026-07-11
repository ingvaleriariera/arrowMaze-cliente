import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_lives_repository.dart';

/// SharedPreferences-backed life pool, keyed per user. Deliberately NOT
/// part of GameProgressDatabase/progress sync: lives are device-local
/// pacing (see ILivesRepository), and keeping them out of the sqflite
/// schema avoids a migration for a mechanic that may still be tuned.
class LivesRepositoryImpl implements ILivesRepository {
  static String _livesKey(String userId) => 'lives_$userId';
  static String _regenKey(String userId) => 'lives_next_regen_$userId';

  @override
  Future<PlayerLives> load(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lives = prefs.getInt(_livesKey(userId));
      if (lives == null) return PlayerLives.full();

      final regenMillis = prefs.getInt(_regenKey(userId));
      return PlayerLives(
        lives: lives.clamp(0, PlayerLives.maxLives),
        nextRegenAt: regenMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(regenMillis)
            : null,
      );
    } catch (e) {
      debugPrint('⚠️  LivesRepositoryImpl.load: Error reading lives - $e');
      return PlayerLives.full();
    }
  }

  @override
  Future<void> save(String userId, PlayerLives lives) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_livesKey(userId), lives.lives);
    final regen = lives.nextRegenAt;
    if (regen != null) {
      await prefs.setInt(_regenKey(userId), regen.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_regenKey(userId));
    }
  }
}
