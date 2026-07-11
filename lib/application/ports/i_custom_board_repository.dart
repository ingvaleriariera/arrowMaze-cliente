import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';

/// Remote (backend) community boards.
abstract class ICustomBoardRepository {
  /// Publishes a board and returns it as stored by the server.
  Future<CustomBoardDTO> create({
    required String name,
    required String difficulty,
    required String boardLayout,
  });

  /// Community boards, newest first.
  Future<List<CustomBoardDTO>> fetchAll({int limit = 50});
}
