import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/boards_state.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/boards/create_custom_board_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/boards/delete_custom_board_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/boards/get_community_boards_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/boards/manage_my_boards_use_case.dart';

class BoardsNotifier extends StateNotifier<BoardsState> {
  final GetCommunityBoardsUseCase getCommunityBoardsUseCase;
  final ManageMyBoardsUseCase manageMyBoardsUseCase;
  final CreateCustomBoardUseCase createCustomBoardUseCase;
  final DeleteCustomBoardUseCase deleteCustomBoardUseCase;

  BoardsNotifier({
    required this.getCommunityBoardsUseCase,
    required this.manageMyBoardsUseCase,
    required this.createCustomBoardUseCase,
    required this.deleteCustomBoardUseCase,
  }) : super(const BoardsState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoadingCommunity: true, clearError: true);
    // The local list never depends on the network — load it first so
    // "Míos" works even if the community fetch fails offline.
    var mine = await manageMyBoardsUseCase.getAll();
    state = state.copyWith(mine: mine);

    try {
      final community = await getCommunityBoardsUseCase.execute();

      // Heal locally stored copies with fresher server data: boards
      // created before the backend returned author info were stored with
      // 'Unknown' — replace them with the community version by id.
      final byId = {for (final b in community) b.id: b};
      var healed = false;
      for (final local in mine) {
        final remote = byId[local.id];
        if (remote != null &&
            (local.authorUsername != remote.authorUsername ||
                local.authorId != remote.authorId)) {
          await manageMyBoardsUseCase.add(remote);
          healed = true;
        }
      }
      if (healed) mine = await manageMyBoardsUseCase.getAll();

      state = state.copyWith(
        community: community,
        mine: mine,
        isLoadingCommunity: false,
      );
    } catch (e) {
      debugPrint('❌ BoardsNotifier.loadAll: Community fetch failed - $e');
      state = state.copyWith(
        isLoadingCommunity: false,
        error: 'No se pudieron cargar los tableros de la comunidad',
      );
    }
  }

  /// Author-only community deletion: removes the board from the server,
  /// then from the local adopted list and the in-memory community list.
  /// Returns false when the server refused (not the author, offline…).
  Future<bool> deleteOwn(String boardId) async {
    try {
      await deleteCustomBoardUseCase.execute(boardId);
      await manageMyBoardsUseCase.remove(boardId);
      state = state.copyWith(
        mine: await manageMyBoardsUseCase.getAll(),
        community: state.community.where((b) => b.id != boardId).toList(),
      );
      return true;
    } catch (e) {
      debugPrint('❌ BoardsNotifier.deleteOwn: $e');
      return false;
    }
  }

  Future<void> adopt(CustomBoardDTO board) async {
    await manageMyBoardsUseCase.add(board);
    state = state.copyWith(mine: await manageMyBoardsUseCase.getAll());
  }

  Future<void> removeFromMine(String boardId) async {
    await manageMyBoardsUseCase.remove(boardId);
    state = state.copyWith(mine: await manageMyBoardsUseCase.getAll());
  }

  /// Publishes the designed board. Returns true on success; on failure the
  /// error lands in state and the editor stays open so nothing is lost.
  Future<bool> create({
    required String name,
    required String difficulty,
    required List<List<int>> grid,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final created = await createCustomBoardUseCase.execute(
        name: name,
        difficulty: difficulty,
        grid: grid,
      );
      state = state.copyWith(
        isSaving: false,
        mine: await manageMyBoardsUseCase.getAll(),
        community: [created, ...state.community],
      );
      return true;
    } catch (e) {
      debugPrint('❌ BoardsNotifier.create: $e');
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}
