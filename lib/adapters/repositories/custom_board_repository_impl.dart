import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_custom_board_repository.dart';

class CustomBoardRepositoryImpl implements ICustomBoardRepository {
  final ApiClient apiClient;

  CustomBoardRepositoryImpl({required this.apiClient});

  @override
  Future<CustomBoardDTO> create({
    required String name,
    required String difficulty,
    required String boardLayout,
  }) async {
    debugPrint('🧩 CustomBoardRepositoryImpl.create: Publishing "$name"');
    final json = await apiClient.post('/api/v1/custom-boards', {
      'name': name,
      'difficulty': difficulty,
      'boardLayout': boardLayout,
    });
    return CustomBoardDTO.fromJson(json);
  }

  @override
  Future<List<CustomBoardDTO>> fetchAll({int limit = 50}) async {
    debugPrint('🧩 CustomBoardRepositoryImpl.fetchAll: limit=$limit');
    final json = await apiClient.get('/api/v1/custom-boards?limit=$limit');
    final boards = json['boards'] as List<dynamic>? ?? [];
    return boards
        .map((b) => CustomBoardDTO.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    debugPrint('🧩 CustomBoardRepositoryImpl.delete: $id');
    await apiClient.delete('/api/v1/custom-boards/$id');
  }
}
