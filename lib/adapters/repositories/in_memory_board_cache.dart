import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_board_cache.dart';

/// In-memory implementation of [IBoardCache]. Lives only as long as the
/// app process — there's no need to persist generated layouts across
/// restarts, since a level's seed is deterministic and would reproduce
/// the exact same layout anyway.
class InMemoryBoardCache implements IBoardCache {
  final Map<String, List<Arrow>> _layouts = {};

  @override
  bool has(String levelId) => _layouts.containsKey(levelId);

  @override
  void put(String levelId, List<Arrow> arrows) {
    _layouts[levelId] = arrows;
  }

  @override
  List<Arrow>? get(String levelId) => _layouts[levelId];
}
