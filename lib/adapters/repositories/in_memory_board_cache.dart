import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_board_cache.dart';

/// In-memory implementation of [IBoardCache]. Lives only as long as the
/// app process — there's no need to persist pre-generated boards across
/// restarts, since regenerating from a level's deterministic seed is the
/// same cost as a cache miss anyway.
class InMemoryBoardCache implements IBoardCache {
  final Map<String, Board> _boards = {};

  @override
  bool has(String levelId) => _boards.containsKey(levelId);

  @override
  void put(String levelId, Board board) {
    _boards[levelId] = board;
  }

  @override
  Board? take(String levelId) => _boards.remove(levelId);
}
