import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';

class GameState {
  final GameSession? session;
  final GameProgress? progress;
  final bool isLoading;
  final String? error;

  const GameState({
    this.session,
    this.progress,
    this.isLoading = false,
    this.error,
  });

  GameState copyWith({
    GameSession? session,
    GameProgress? progress,
    bool? isLoading,
    String? error,
  }) {
    return GameState(
      session: session ?? this.session,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  String toString() => 'GameState(session: $session, progress: $progress, isLoading: $isLoading, error: $error)';
}
