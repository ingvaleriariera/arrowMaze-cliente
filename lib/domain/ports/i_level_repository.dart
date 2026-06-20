import '../entities/level.dart';

abstract class ILevelRepository {
  Future<List<Level>> getLevels();
  Future<List<Level>> getLevelsByDifficulty(String difficulty);
}
