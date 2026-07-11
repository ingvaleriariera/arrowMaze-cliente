import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_my_boards_repository.dart';

/// The player's adopted-boards list: read it, adopt a community board
/// into it, or drop one. Grouped in a single use case because all three
/// are trivial one-step operations over the same local store.
class ManageMyBoardsUseCase {
  final IMyBoardsRepository myBoardsRepository;

  ManageMyBoardsUseCase({required this.myBoardsRepository});

  Future<List<CustomBoardDTO>> getAll() => myBoardsRepository.getAll();

  Future<void> add(CustomBoardDTO board) => myBoardsRepository.add(board);

  Future<void> remove(String id) => myBoardsRepository.remove(id);
}
