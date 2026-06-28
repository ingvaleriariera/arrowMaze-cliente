import 'package:arrow_maze_cliente_copy/application/dtos/level_summary_dto.dart';

class LevelSelectState {
  final List<LevelSummaryDTO> levels;
  final bool isLoading;
  final String? error;
  final bool isPreloadingAll;

  const LevelSelectState({
    this.levels = const [],
    this.isLoading = false,
    this.error,
    this.isPreloadingAll = false,
  });

  LevelSelectState copyWith({
    List<LevelSummaryDTO>? levels,
    bool? isLoading,
    String? error,
    bool? isPreloadingAll,
  }) {
    return LevelSelectState(
      levels: levels ?? this.levels,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isPreloadingAll: isPreloadingAll ?? this.isPreloadingAll,
    );
  }
}
