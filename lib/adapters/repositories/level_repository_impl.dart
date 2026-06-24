import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/level_mapper.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

class LevelRepositoryImpl implements ILevelRepository {
  final ApiClient apiClient;
  final LevelMapper levelMapper;

  LevelRepositoryImpl({
    required this.apiClient,
    required this.levelMapper,
  });

  @override
  Future<Level> getLevel(String levelId) async {
    final json = await apiClient.get('/levels/$levelId');
    return levelMapper.fromJson(json);
  }

  @override
  Future<List<Level>> getLevels() async {
    final json = await apiClient.get('/levels');
    final list = json['levels'] as List<dynamic>;
    return levelMapper.fromJsonList(list);
  }

  @override
  Future<List<Level>> getLevelsByDifficulty(String difficulty) async {
    final json = await apiClient.get('/levels?difficulty=$difficulty');
    final list = json['levels'] as List<dynamic>;
    return levelMapper.fromJsonList(list);
  }
}
