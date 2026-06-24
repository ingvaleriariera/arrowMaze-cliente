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
    // First try to get from cache
    _levelsCache ??= await getLevels();
    
    try {
      return _levelsCache!.firstWhere((level) => level.id == levelId);
    } catch (e) {
      // If not in cache, try direct API call
      final json = await apiClient.get('/api/v1/levels/$levelId');
      return levelMapper.fromJson(json);
    }
  }

  @override
  Future<List<Level>> getLevels() async {
    try {
      final json = await apiClient.get('/api/v1/levels');
      final list = json['levels'] as List<dynamic>? ?? json as List<dynamic>;
      _levelsCache = levelMapper.fromJsonList(list);
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
