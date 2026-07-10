import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

/// Strategy for deciding whether a level is played against the clock and
/// how much time it gets. Kept behind an abstraction so the rule can vary
/// (per difficulty, per event, tuned after playtesting) without touching
/// LoadLevelUseCase, which only depends on this port.
abstract class ITimeLimitPolicy {
  /// The time budget for a level, or [TimeLimit.none] for an untimed one.
  ///
  /// Takes the generated arrow count (not the cell count) because that is
  /// what actually measures how much work the player has to do.
  TimeLimit forLevel({required String difficulty, required int totalArrows});
}
