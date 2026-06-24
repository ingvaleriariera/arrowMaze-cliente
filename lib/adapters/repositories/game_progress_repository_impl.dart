import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/progress_mapper.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_progress_repository.dart';

class GameProgressRepositoryImpl implements IGameProgressRepository {
  final ApiClient apiClient;
  final ProgressMapper progressMapper;

  // In-memory cache for local storage (in real app, use sqflite)
  final Map<String, GameProgress> _localCache = {};

  GameProgressRepositoryImpl({
    required this.apiClient,
    required this.progressMapper,
  });

  @override
  Future<void> save(GameProgress progress) async {
    _localCache[progress.userId] = progress;
  }

  @override
  Future<GameProgress?> get(String userId) async {
    return _localCache[userId];
  }

  @override
  Future<GameProgress> sync(String userId) async {
    try {
      // Get from backend
      final backendJson = await apiClient.get('/progress/$userId');
      final backendProgress = progressMapper.fromMap(backendJson);

      // Get local version
      final localProgress = await get(userId);

      // Merge with last-write-wins strategy (backend wins if it has higher scores)
      if (localProgress != null) {
        final mergedScores = <String, int>{...localProgress.bestScores};
        for (final entry in backendProgress.bestScores.entries) {
          final localScore = mergedScores[entry.key] ?? 0;
          if (entry.value > localScore) {
            mergedScores[entry.key] = entry.value;
          }
        }

        final mergedProgress = GameProgress(
          userId: userId,
          completedLevels: {
            ...localProgress.completedLevels,
            ...backendProgress.completedLevels,
          }.toList(),
          bestScores: mergedScores,
          coins: backendProgress.coins > localProgress.coins 
              ? backendProgress.coins 
              : localProgress.coins,
        );

        await save(mergedProgress);
        return mergedProgress;
      }

      // No local progress, use backend
      await save(backendProgress);
      return backendProgress;
    } catch (e) {
      // If sync fails, return local or create new
      return await get(userId) ?? GameProgress(userId: userId);
    }
  }
}
