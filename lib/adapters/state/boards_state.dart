import 'package:arrow_maze_cliente_copy/application/dtos/custom_board_dto.dart';

class BoardsState {
  final List<CustomBoardDTO> community;
  final List<CustomBoardDTO> mine;
  final bool isLoadingCommunity;
  final bool isSaving;
  final String? error;

  const BoardsState({
    this.community = const [],
    this.mine = const [],
    this.isLoadingCommunity = false,
    this.isSaving = false,
    this.error,
  });

  bool isAdded(String boardId) => mine.any((b) => b.id == boardId);

  BoardsState copyWith({
    List<CustomBoardDTO>? community,
    List<CustomBoardDTO>? mine,
    bool? isLoadingCommunity,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return BoardsState(
      community: community ?? this.community,
      mine: mine ?? this.mine,
      isLoadingCommunity: isLoadingCommunity ?? this.isLoadingCommunity,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
