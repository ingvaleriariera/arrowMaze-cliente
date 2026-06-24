import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';

class MockGameProgressRepository implements IGameProgressRepository {
  final Map<String, GameProgress> _storage = {};

  @override
  Future<void> save(GameProgress progress) async {
    _storage[progress.userId] = progress;
  }

  @override
  Future<GameProgress?> get(String userId) async {
    return _storage[userId];
  }

  @override
  Future<GameProgress> sync(String userId) async {
    if (_storage.containsKey(userId)) {
      return _storage[userId]!;
    }
    // Create new if doesn't exist
    final progress = GameProgress(userId: userId);
    _storage[userId] = progress;
    return progress;
  }
}
