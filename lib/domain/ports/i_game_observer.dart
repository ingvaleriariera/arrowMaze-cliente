import 'package:arrow_maze_cliente_copy/domain/value_objects/move_result.dart';

/// Observer port for game events. Notified by GameSession (Subject) when
/// significant game events occur.
///
/// Rules:
/// - Pure domain port: no Flutter imports, no external dependencies
/// - Implementers in adapters layer listen to game progress and react
/// - Follows GoF Observer pattern (Behavioral)
abstract class IGameObserver {
  /// Called when a player successfully or unsuccessfully attempts to move.
  /// Reports the raw move result for listeners that care (UI animation, audio).
  void onPlayerMoved(MoveResult result);

  /// Called after score calculation when the score has changed.
  /// Reports the new score value so listeners can update displays.
  void onScoreUpdated(int newScore);

  /// Called when the game session ends (victory or defeat).
  /// [success] is true for victory, false for defeat.
  /// [finalScore] is the calculated final score at game end.
  void onLevelCompleted(bool success, int finalScore);
}
