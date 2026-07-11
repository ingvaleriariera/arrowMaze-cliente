import 'package:arrow_maze_cliente_copy/application/ports/i_my_boards_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

/// Decorator over the standard level repository that also resolves
/// player-made boards. Level ids prefixed with [customPrefix] are looked
/// up in the local adopted-boards store and adapted into a regular
/// [Level]; everything else is delegated untouched.
///
/// This is what lets custom boards flow through the whole existing game
/// pipeline (LoadLevelUseCase, generation, GameScreen, timer policy)
/// with zero changes to it — the pipeline never learns that some levels
/// come from players instead of the backend seeder.
class CustomAwareLevelRepository implements ILevelRepository {
  static const String customPrefix = 'custom-';

  static String levelIdFor(String boardId) => '$customPrefix$boardId';
  static bool isCustomLevelId(String levelId) =>
      levelId.startsWith(customPrefix);

  final ILevelRepository inner;
  final IMyBoardsRepository myBoards;

  CustomAwareLevelRepository({required this.inner, required this.myBoards});

  @override
  Future<Level> getLevel(String levelId) async {
    if (!isCustomLevelId(levelId)) return inner.getLevel(levelId);

    final boardId = levelId.substring(customPrefix.length);
    final board = await myBoards.getById(boardId);
    if (board == null) {
      throw Exception('Custom board $boardId not found in local list');
    }

    return Level(
      id: levelId,
      difficulty: board.difficulty,
      boardLayout: board.boardLayout,
      // Unused for custom play: the real move budget is computed from the
      // generated arrow count, same as standard levels.
      moveLimit: 999,
      timeLimit: TimeLimit.none,
    );
  }

  // Custom boards deliberately do NOT appear in the standard level list —
  // they live in their own screen and don't participate in the sequential
  // unlock progression.
  @override
  Future<List<Level>> getLevels() => inner.getLevels();

  @override
  Future<List<Level>> getLevelsByDifficulty(String difficulty) =>
      inner.getLevelsByDifficulty(difficulty);
}
