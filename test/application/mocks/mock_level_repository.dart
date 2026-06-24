import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

class MockLevelRepository implements ILevelRepository {
  @override
  Future<Level> getLevel(String levelId) async {
    final levels = await getLevels();
    return levels.firstWhere(
      (level) => level.id == levelId,
      orElse: () => Level(
        id: levelId,
        difficulty: 'EASY',
        boardLayout: '[[1,1,1],[1,1,1],[1,1,1]]',
        moveLimit: 10,
        timeLimit: TimeLimit.none,
      ),
    );
  }

  @override
  Future<List<Level>> getLevels() async {
    return [
      Level(
        id: '550e8400-e29b-41d4-a716-446655440001',
        difficulty: 'EASY',
        boardLayout: '[[1,1,1],[1,1,1],[1,1,1]]',
        moveLimit: 10,
        timeLimit: TimeLimit.none,
      ),
      Level(
        id: '550e8400-e29b-41d4-a716-446655440002',
        difficulty: 'MEDIUM',
        boardLayout: '[[1,1,1,1],[1,1,1,1],[1,1,1,1]]',
        moveLimit: 20,
        timeLimit: TimeLimit.of(120),
      ),
      Level(
        id: '550e8400-e29b-41d4-a716-446655440003',
        difficulty: 'HARD',
        boardLayout: '[[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1]]',
        moveLimit: 15,
        timeLimit: TimeLimit.of(60),
      ),
    ];
  }

  @override
  Future<List<Level>> getLevelsByDifficulty(String difficulty) async {
    final levels = await getLevels();
    return levels.where((level) => level.difficulty == difficulty).toList();
  }
}
