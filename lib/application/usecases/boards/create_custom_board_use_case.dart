import 'dart:convert';
import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_custom_board_repository.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_my_boards_repository.dart';

/// Publishes a designed board to the community and adopts it into the
/// creator's own list, so it's immediately playable for its author.
class CreateCustomBoardUseCase {
  final ICustomBoardRepository customBoardRepository;
  final IMyBoardsRepository myBoardsRepository;

  CreateCustomBoardUseCase({
    required this.customBoardRepository,
    required this.myBoardsRepository,
  });

  Future<CustomBoardDTO> execute({
    required String name,
    required String difficulty,
    required List<List<int>> grid,
  }) async {
    final boardLayout = jsonEncode({
      'grid': grid,
      'rows': grid.length,
      'cols': grid.isEmpty ? 0 : grid.first.length,
    });

    final created = await customBoardRepository.create(
      name: name,
      difficulty: difficulty,
      boardLayout: boardLayout,
    );

    await myBoardsRepository.add(created);
    return created;
  }
}
