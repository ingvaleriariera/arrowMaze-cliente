import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_cliente_copy/domain/services/per_arrow_time_limit_policy.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

void main() {
  group('PerArrowTimeLimitPolicy', () {
    final policy = PerArrowTimeLimitPolicy();

    test('hard levels get 2 seconds per arrow', () {
      final limit = policy.forLevel(difficulty: 'hard', totalArrows: 100);
      expect(limit.getValue(), 200);
    });

    test('difficulty comparison is case-insensitive (backend sends lowercase)', () {
      final lower = policy.forLevel(difficulty: 'hard', totalArrows: 80);
      final upper = policy.forLevel(difficulty: 'HARD', totalArrows: 80);
      expect(lower, upper);
      expect(lower.hasLimit(), isTrue);
    });

    test('small hard boards are floored at 60 seconds', () {
      final limit = policy.forLevel(difficulty: 'hard', totalArrows: 10);
      expect(limit.getValue(), 60);
    });

    test('easy and medium levels are untimed', () {
      expect(policy.forLevel(difficulty: 'easy', totalArrows: 100), TimeLimit.none);
      expect(policy.forLevel(difficulty: 'medium', totalArrows: 100), TimeLimit.none);
    });
  });
}
