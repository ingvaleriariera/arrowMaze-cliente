import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';

/// The player's local list of adopted community boards (the ones they
/// chose to "add to my levels"). Device-local by design: the full board
/// payload is stored so an added board stays playable without re-fetching.
abstract class IMyBoardsRepository {
  Future<List<CustomBoardDTO>> getAll();

  Future<CustomBoardDTO?> getById(String id);

  /// Idempotent: adding an already-added board replaces it.
  Future<void> add(CustomBoardDTO board);

  Future<void> remove(String id);
}
