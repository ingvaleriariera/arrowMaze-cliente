import 'package:sqflite/sqflite.dart';

import '../../domain/entities/game_progress.dart';
import '../../domain/ports/i_game_progress_repository.dart';
import '../api/api_client.dart';
import '../mappers/progress_mapper.dart';

class GameProgressRepositoryImpl implements IGameProgressRepository {
  static const String tableName = 'game_progress';
  static const String createTableSql = '''
    CREATE TABLE $tableName (
      userId TEXT PRIMARY KEY,
      completedLevels TEXT NOT NULL,
      bestScores TEXT NOT NULL,
      coins INTEGER NOT NULL
    )
  ''';

  final ApiClient apiClient;
  final ProgressMapper progressMapper;
  final Database database;

  GameProgressRepositoryImpl(this.apiClient, this.progressMapper, this.database);

  @override
  Future<void> save(GameProgress progress) async {
    await database.insert(
      tableName,
      progressMapper.toMap(progress),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<GameProgress?> get(String userId) async {
    final rows = await database.query(tableName, where: 'userId = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    return progressMapper.fromMap(rows.first);
  }

  @override
  Future<GameProgress> sync(String userId) async {
    final local = await get(userId);
    final response = await apiClient.post('/progress/sync', {
      'userId': userId,
      'levels': local == null
          ? <Map<String, dynamic>>[]
          : local.bestScores.entries
              .map((entry) => {
                    'levelId': entry.key,
                    'bestScore': entry.value,
                    'completedAt': '',
                  })
              .toList(),
    });

    final remoteLevels = response['levels'] as List<dynamic>;
    final bestScores = <String, int>{};
    final completedLevels = <String>[];
    for (final entry in remoteLevels) {
      final levelEntry = entry as Map<String, dynamic>;
      final levelId = levelEntry['levelId'] as String;
      bestScores[levelId] = levelEntry['bestScore'] as int;
      completedLevels.add(levelId);
    }

    final merged = GameProgress(userId, completedLevels, bestScores, local?.coins ?? 0);
    await save(merged);
    return merged;
  }
}
