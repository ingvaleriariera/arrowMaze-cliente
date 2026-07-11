import 'package:arrow_maze_cliente_copy/application/ports/i_custom_board_repository.dart';

/// Deletes one of the player's own published boards from the community.
/// Authorship is enforced server-side (the request carries the JWT).
class DeleteCustomBoardUseCase {
  final ICustomBoardRepository customBoardRepository;

  DeleteCustomBoardUseCase({required this.customBoardRepository});

  Future<void> execute(String boardId) =>
      customBoardRepository.delete(boardId);
}
