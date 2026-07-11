import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_my_boards_repository.dart';

/// SharedPreferences-backed store of adopted community boards. Stored
/// device-wide (not per user): the level-repository decorator resolves
/// custom levels by id alone and has no user context — and an adopted
/// board is content, not progress, so sharing it across accounts on the
/// same device is harmless.
class MyBoardsRepositoryImpl implements IMyBoardsRepository {
  static const _key = 'my_custom_boards';

  @override
  Future<List<CustomBoardDTO>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      return raw
          .map((s) =>
              CustomBoardDTO.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️  MyBoardsRepositoryImpl.getAll: Error - $e');
      return [];
    }
  }

  @override
  Future<CustomBoardDTO?> getById(String id) async {
    final all = await getAll();
    for (final board in all) {
      if (board.id == id) return board;
    }
    return null;
  }

  @override
  Future<void> add(CustomBoardDTO board) async {
    final all = await getAll();
    final kept = all.where((b) => b.id != board.id).toList()..add(board);
    await _save(kept);
  }

  @override
  Future<void> remove(String id) async {
    final all = await getAll();
    await _save(all.where((b) => b.id != id).toList());
  }

  Future<void> _save(List<CustomBoardDTO> boards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      boards.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }
}
