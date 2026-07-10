import 'package:arrow_maze_cliente_copy/domain/ports/i_time_limit_policy.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

/// Default clock rule: only HARD levels are timed, at a flat budget of
/// [secondsPerArrow] per generated arrow, floored at [minimumSeconds] so a
/// small hard board never gets an unwinnable sub-minute budget.
///
/// On the current hard boards (~66-116 arrows) this lands between roughly
/// 2 and 4 minutes.
class PerArrowTimeLimitPolicy implements ITimeLimitPolicy {
  static const int secondsPerArrow = 2;
  static const int minimumSeconds = 60;

  @override
  TimeLimit forLevel({required String difficulty, required int totalArrows}) {
    if (difficulty.toUpperCase() != 'HARD') return TimeLimit.none;

    final budget = totalArrows * secondsPerArrow;
    return TimeLimit.of(budget < minimumSeconds ? minimumSeconds : budget);
  }
}
