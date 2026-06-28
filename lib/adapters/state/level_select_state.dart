import 'package:arrow_maze_cliente_copy/application/dtos/level_summary_dto.dart';

class LevelSelectState {
  final List<LevelSummaryDTO> levels;
  final bool isLoading;
  final String? error;
  final bool isPreloadingAll;
  final int preloadCompleted;
  final int preloadTotal;

  const LevelSelectState({
    this.levels = const [],
    this.isLoading = false,
    this.error,
    this.isPreloadingAll = false,
    this.preloadCompleted = 0,
    this.preloadTotal = 0,
  });

  double get preloadProgress => preloadTotal == 0 ? 0 : preloadCompleted / preloadTotal;

  LevelSelectState copyWith({
    List<LevelSummaryDTO>? levels,
    bool? isLoading,
    String? error,
    bool? isPreloadingAll,
    int? preloadCompleted,
    int? preloadTotal,
  }) {
    return LevelSelectState(
      levels: levels ?? this.levels,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isPreloadingAll: isPreloadingAll ?? this.isPreloadingAll,
      preloadCompleted: preloadCompleted ?? this.preloadCompleted,
      preloadTotal: preloadTotal ?? this.preloadTotal,
    );
  }
}
