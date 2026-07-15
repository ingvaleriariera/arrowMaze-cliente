import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/i_game_progress_local_store.dart';

/// Web counterpart to GameProgressDatabase: sqflite has no Flutter Web
/// implementation, so on kIsWeb this backs the same
/// [IGameProgressLocalStore] port with shared_preferences (localStorage)
/// instead. The stored row keeps the exact same shape sqflite returns —
/// completedLevels/bestScores as JSON-encoded TEXT, coins as int,
/// avatarEmoji as String — so GameProgressRepositoryImpl's reconstruction
/// logic needs no changes to work with either backend.
class WebGameProgressStore implements IGameProgressLocalStore {
  static String _keyFor(String userId) => 'game_progress_$userId';

  final SharedPreferences _prefs;

  WebGameProgressStore(this._prefs);

  @override
  Future<Map<String, dynamic>?> getProgress(String userId) async {
    try {
      debugPrint('📖 WebGameProgressStore.getProgress: Reading $userId from localStorage');
      final raw = _prefs.getString(_keyFor(userId));
      if (raw == null) {
        debugPrint('ℹ️  WebGameProgressStore: No progress found for $userId');
        return null;
      }

      debugPrint('✅ WebGameProgressStore: Found progress for $userId');
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ WebGameProgressStore.getProgress: Error - $e');
      rethrow;
    }
  }

  @override
  Future<void> saveProgress(
    String userId,
    List<String> completedLevels,
    Map<String, int> bestScores,
    int coins,
    String avatarEmoji,
  ) async {
    try {
      debugPrint('💾 WebGameProgressStore.saveProgress: Saving $userId to localStorage');

      final row = {
        'userId': userId,
        'completedLevels': jsonEncode(completedLevels),
        'bestScores': jsonEncode(bestScores),
        'coins': coins,
        'avatarEmoji': avatarEmoji,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      await _prefs.setString(_keyFor(userId), jsonEncode(row));
      debugPrint('✅ WebGameProgressStore: Saved $userId to localStorage');
    } catch (e) {
      debugPrint('❌ WebGameProgressStore.saveProgress: Error - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProgress(String userId) async {
    try {
      debugPrint('🗑️  WebGameProgressStore.deleteProgress: Deleting $userId');
      await _prefs.remove(_keyFor(userId));
      debugPrint('✅ WebGameProgressStore: Deleted $userId');
    } catch (e) {
      debugPrint('❌ WebGameProgressStore.deleteProgress: Error - $e');
      rethrow;
    }
  }

  @override
  Future<void> closeDatabase() async {
    // No-op: shared_preferences has no connection/handle to close, unlike
    // sqflite's Database. Kept to satisfy IGameProgressLocalStore.
  }
}
