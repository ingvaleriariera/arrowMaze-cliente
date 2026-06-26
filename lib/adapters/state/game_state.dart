import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_painter.dart';

class GameState {
  final GameSession? session;
  final GameProgress? progress;
  final bool isLoading;
  final String? error;
  final Map<String, FlashType> flashMap; // arrowId → flash type

  const GameState({
    this.session,
    this.progress,
    this.isLoading = false,
    this.error,
    this.flashMap = const {},
  });

  GameState copyWith({
    GameSession? session,
    bool clearSession = false,
    GameProgress? progress,
    bool? isLoading,
    String? error,
    Map<String, FlashType>? flashMap,
  }) {
    return GameState(
      session: clearSession ? null : (session ?? this.session),
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      flashMap: flashMap ?? this.flashMap,
    );
  }

  @override
  String toString() => 'GameState(session: $session, progress: $progress, isLoading: $isLoading, error: $error)';
}
