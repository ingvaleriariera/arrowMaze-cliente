import 'package:arrow_maze_cliente_copy/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/global_leaderboard_entry_dto.dart';

enum LeaderboardMode { perLevel, global }

class LeaderboardState {
  final LeaderboardMode mode;
  final List<LeaderboardEntryDTO> entries;
  final List<GlobalLeaderboardEntryDTO> globalEntries;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.mode = LeaderboardMode.perLevel,
    this.entries = const [],
    this.globalEntries = const [],
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    LeaderboardMode? mode,
    List<LeaderboardEntryDTO>? entries,
    List<GlobalLeaderboardEntryDTO>? globalEntries,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      mode: mode ?? this.mode,
      entries: entries ?? this.entries,
      globalEntries: globalEntries ?? this.globalEntries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
