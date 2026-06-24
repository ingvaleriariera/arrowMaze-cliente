import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/level_mapper.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

class LevelRepositoryImpl implements ILevelRepository {
  final ApiClient apiClient;
  final LevelMapper levelMapper;

  // Cache for levels to avoid repeated API calls
  List<Level>? _levelsCache;

  LevelRepositoryImpl({
    required this.apiClient,
    required this.levelMapper,
  });

  @override
  Future<Level> getLevel(String levelId) async {
    debugPrint('🔍 LevelRepositoryImpl.getLevel: Fetching level: $levelId');

    // The backend only has GET /api/v1/levels (no per-level endpoint)
    // So fetch all levels and find the matching one
    final levels = await getLevels();

    try {
      final level = levels.firstWhere((l) => l.id == levelId);
      debugPrint('✅ LevelRepositoryImpl: Found level: ${level.id}');
      debugPrint('📋 Raw boardLayout from backend:');
      final preview = level.boardLayout.length > 100
          ? '${level.boardLayout.substring(0, 100)}...'
          : level.boardLayout;
      debugPrint('   $preview');
      debugPrint(
          '✅ Level fetched: ${level.id} (${level.boardLayout.length} chars boardLayout)');
      return level;
    } catch (e) {
      debugPrint('❌ Level $levelId not found in backend response');
      throw Exception('Level $levelId not found');
    }
  }

  @override
  Future<List<Level>> getLevels() async {
    try {
      final json = await apiClient.get('/api/v1/levels');
      final list = json['levels'] as List<dynamic>? ?? json as List<dynamic>;
      _levelsCache = levelMapper.fromJsonList(list);

      // DEBUG: Print raw boardLayout for level-007
      for (final levelJson in list) {
        if (levelJson is Map<String, dynamic> && levelJson['id'] == '007') {
          final boardLayout = levelJson['boardLayout'] as String?;
          debugPrint('📦 RAW level-007 boardLayout (STRING):');
          debugPrint('   $boardLayout');

          // Try to parse it
          try {
            final decoded = jsonDecode(boardLayout ?? '{}') as Map<String, dynamic>;
            final grid = decoded['grid'] as List<dynamic>? ?? [];
            debugPrint('📊 DECODED: ${grid.length} rows');
            if (grid.isNotEmpty) {
              debugPrint('   Row 0: ${grid[0]}');
            }
          } catch (e) {
            debugPrint('❌ Failed to decode: $e');
          }
          break;
        }
      }

      return _levelsCache!;
    } catch (e) {
      // If API call fails, return empty list
      return [];
    }
  }

  @override
  Future<List<Level>> getLevelsByDifficulty(String difficulty) async {
    final allLevels = await getLevels();
    return allLevels.where((level) => level.difficulty == difficulty).toList();
  }
}
