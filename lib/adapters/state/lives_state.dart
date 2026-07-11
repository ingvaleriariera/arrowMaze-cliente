import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';

class LivesState {
  final PlayerLives? lives;
  final bool isLoading;

  /// Countdown to the next regenerated life, refreshed every second by
  /// LivesNotifier's ticker; null while the pool is full (or not loaded).
  final Duration? timeUntilNextLife;

  const LivesState({
    this.lives,
    this.isLoading = false,
    this.timeUntilNextLife,
  });

  int get count => lives?.lives ?? PlayerLives.maxLives;
  bool get canPlay => lives?.canPlay ?? true;

  LivesState copyWith({
    PlayerLives? lives,
    bool? isLoading,
    Duration? timeUntilNextLife,
    bool clearCountdown = false,
  }) {
    return LivesState(
      lives: lives ?? this.lives,
      isLoading: isLoading ?? this.isLoading,
      timeUntilNextLife:
          clearCountdown ? null : (timeUntilNextLife ?? this.timeUntilNextLife),
    );
  }
}
