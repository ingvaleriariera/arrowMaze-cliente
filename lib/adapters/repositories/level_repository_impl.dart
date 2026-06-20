import '../../domain/entities/level.dart';
import '../../domain/ports/i_level_repository.dart';
import '../api/api_client.dart';
import '../mappers/level_mapper.dart';

class LevelRepositoryImpl implements ILevelRepository {
  final ApiClient apiClient;
  final LevelMapper levelMapper;

  LevelRepositoryImpl(this.apiClient, this.levelMapper);

  @override
  Future<List<Level>> getLevels() async {
    final response = await apiClient.get('/levels');
    final levels = response['levels'] as List<dynamic>;
    return levels.map((json) => levelMapper.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Level>> getLevelsByDifficulty(String difficulty) async {
    final levels = await getLevels();
    return levels.where((level) => level.getDifficulty() == difficulty).toList();
  }
}
