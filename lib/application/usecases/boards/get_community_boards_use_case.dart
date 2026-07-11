import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_custom_board_repository.dart';

class GetCommunityBoardsUseCase {
  final ICustomBoardRepository customBoardRepository;

  GetCommunityBoardsUseCase({required this.customBoardRepository});

  Future<List<CustomBoardDTO>> execute({int limit = 50}) =>
      customBoardRepository.fetchAll(limit: limit);
}
