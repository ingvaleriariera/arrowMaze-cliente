import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

class MockLevelRepository implements ILevelRepository {
  @override
  Future<Level> getLevel(String levelId) async {
    if (levelId == 'level_001') {
      return Level(
        id: levelId,
        difficulty: 'EASY',
        boardLayout: '[[1,1,1],[1,1,1],[1,1,1]]',
        moveLimit: 10,
        timeLimit: TimeLimit.none,
      );
    } else if (levelId == 'level_002') {
      return Level(
        id: levelId,
        difficulty: 'MEDIUM',
        boardLayout: '[[1,1,1,1],[1,1,1,1],[1,1,1,1]]',
        moveLimit: 20,
        timeLimit: TimeLimit.of(120),
      );
    }
    // Default
    return Level(
      id: levelId,
      difficulty: 'EASY',
      boardLayout: '[[1,1,1],[1,1,1],[1,1,1]]',
      moveLimit: 10,
      timeLimit: TimeLimit.none,
    );
  }

  @override
  Future<List<Level>> getLevels() async {
    return [
      Level(
        id: 'level_001',
        difficulty: 'EASY',
        boardLayout: '[[1,1,1],[1,1,1],[1,1,1]]',
        moveLimit: 10,
        timeLimit: TimeLimit.none,
      ),
      Level(
        id: 'level_002',
        difficulty: 'MEDIUM',
        boardLayout: '[[1,1,1,1],[1,1,1,1],[1,1,1,1]]',
        moveLimit: 20,
        timeLimit: TimeLimit.of(120),
      ),
    ];
  }

  @override
  Future<List<Level>> getLevelsByDifficulty(String difficulty) async {
    final levels = await getLevels();
    return levels.where((level) => level.difficulty == difficulty).toList();
  }
}
