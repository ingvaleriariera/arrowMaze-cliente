import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';

abstract class ILevelRepository {
  Future<Level> getLevel(String levelId);
  Future<List<Level>> getLevels();
  Future<List<Level>> getLevelsByDifficulty(String difficulty);
}
