import 'package:test/test.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_observer.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/move_result.dart';

/// Mock observer to track which events were fired
class TestGameObserver implements IGameObserver {
  List<String> events = [];
  List<MoveResult> moveResults = [];
  List<int> scoreUpdates = [];
  List<Map<String, dynamic>> levelCompletions = [];

  @override
  void onPlayerMoved(MoveResult result) {
    events.add('onPlayerMoved');
    moveResults.add(result);
  }

  @override
  void onScoreUpdated(int newScore) {
    events.add('onScoreUpdated');
    scoreUpdates.add(newScore);
  }

  @override
  void onLevelCompleted(bool success, int finalScore) {
    events.add('onLevelCompleted');
    levelCompletions.add({'success': success, 'finalScore': finalScore});
  }

  void reset() {
    events.clear();
    moveResults.clear();
    scoreUpdates.clear();
    levelCompletions.clear();
  }
}

void main() {
  group('Observer Pattern — IGameObserver Port', () {
    test('TestGameObserver implements IGameObserver correctly', () {
      final observer = TestGameObserver();

      // Should be a valid IGameObserver
      expect(observer, isA<IGameObserver>());

      // Test all three methods can be called without error
      expect(() {
        observer.onPlayerMoved(MoveResult.exitSuccess('a', []));
      }, returnsNormally);

      expect(() {
        observer.onScoreUpdated(100);
      }, returnsNormally);

      expect(() {
        observer.onLevelCompleted(true, 500);
      }, returnsNormally);
    });

    test('Observer events are tracked correctly', () {
      final observer = TestGameObserver();

      // Fire some events
      observer.onPlayerMoved(MoveResult.exitSuccess('a', []));
      observer.onScoreUpdated(100);
      observer.onLevelCompleted(true, 500);

      // Verify all events were recorded
      expect(observer.events, equals(['onPlayerMoved', 'onScoreUpdated', 'onLevelCompleted']));
      expect(observer.scoreUpdates, equals([100]));
      expect(observer.levelCompletions.length, equals(1));
      expect(observer.levelCompletions.first['success'], isTrue);
      expect(observer.levelCompletions.first['finalScore'], equals(500));
    });

    test('Multiple observers can be created independently', () {
      final observer1 = TestGameObserver();
      final observer2 = TestGameObserver();

      observer1.onPlayerMoved(MoveResult.exitSuccess('a', []));
      observer2.onPlayerMoved(MoveResult.exitSuccess('b', []));

      // Each observer tracks its own events
      expect(observer1.moveResults.first.arrowId, equals('a'));
      expect(observer2.moveResults.first.arrowId, equals('b'));

      // Events are isolated
      expect(observer1.events, equals(['onPlayerMoved']));
      expect(observer2.events, equals(['onPlayerMoved']));
    });

    test('Observer.reset() clears all tracked data', () {
      final observer = TestGameObserver();

      observer.onPlayerMoved(MoveResult.exitSuccess('a', []));
      observer.onScoreUpdated(100);
      observer.onLevelCompleted(true, 500);

      expect(observer.events.length, equals(3));
      expect(observer.scoreUpdates.length, equals(1));
      expect(observer.levelCompletions.length, equals(1));

      observer.reset();

      expect(observer.events, isEmpty);
      expect(observer.scoreUpdates, isEmpty);
      expect(observer.levelCompletions, isEmpty);
    });

    test('Observer correctly handles failed moves', () {
      final observer = TestGameObserver();

      final failedMove = MoveResult.exitFailure('x');
      observer.onPlayerMoved(failedMove);

      expect(observer.moveResults.first.success, isFalse);
      expect(observer.moveResults.first.arrowId, equals('x'));
    });

    test('Observer correctly handles different score updates', () {
      final observer = TestGameObserver();

      observer.onScoreUpdated(0);
      observer.onScoreUpdated(50);
      observer.onScoreUpdated(150);
      observer.onScoreUpdated(200);

      expect(observer.scoreUpdates, equals([0, 50, 150, 200]));
    });

    test('Observer correctly handles victory vs defeat', () {
      final observer = TestGameObserver();

      observer.onLevelCompleted(true, 500);
      observer.onLevelCompleted(false, 100);
      observer.onLevelCompleted(true, 800);

      expect(observer.levelCompletions.length, equals(3));
      expect(observer.levelCompletions[0]['success'], isTrue);
      expect(observer.levelCompletions[0]['finalScore'], equals(500));
      expect(observer.levelCompletions[1]['success'], isFalse);
      expect(observer.levelCompletions[1]['finalScore'], equals(100));
      expect(observer.levelCompletions[2]['success'], isTrue);
      expect(observer.levelCompletions[2]['finalScore'], equals(800));
    });
  });
}
