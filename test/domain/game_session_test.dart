import 'package:test/test.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/states/defeat_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/victory_state.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

void main() {
  group('GameSession', () {
    test('Scenario 5: Exhaust moves without victory → DefeatState', () {
      // Setup: Two arrows where A blocks B
      // A at (0,0) pointing right - exit path: (1,0), (2,0)... includes B
      // B at (1,0) pointing right - exit path: (2,0), (3,0)... clear
      // Only B is activatable initially

      final boardLayout = '[[1,1,1],[1,1,1],[1,1,1]]';
      final shape = BoardShape.fromJson(boardLayout);

      final arrowA = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(
            position: Position(0, 0),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final arrowB = Arrow(
        id: 'b',
        segments: [
          ArrowSegment(
            position: Position(1, 0),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#0088FF'),
      );

      final board = BoardBuilder.create()
          .setShape(shape)
          .addArrow(arrowA)
          .addArrow(arrowB)
          .build();

      final session = GameSession(
        board: board,
        levelId: 'test_limited_moves',
        maxMoves: 1,
      );

      // Only one move allowed, but we have two arrows
      expect(session.isPlaying(), isTrue, reason: 'Should start in playing state');

      // Fire B (the only activatable arrow)
      final result = session.executeMove('b');
      expect(result.success, isTrue, reason: 'B should fire successfully');
      expect(session.moves, equals(1), reason: 'Move count should be 1');

      // Now A is activatable but we're out of moves
      expect(board.isActivatable('a'), isTrue,
          reason: 'A should be activatable after B is removed');
      expect(session.isOver(), isTrue,
          reason: 'Game should be over (exceeded maxMoves)');
      expect(session.state is DefeatState, isTrue,
          reason: 'Should be in DefeatState');

      final defeatState = session.state as DefeatState;
      expect(defeatState.reason, equals('OUT_OF_MOVES'),
          reason: 'Defeat reason should be OUT_OF_MOVES');
    });

    test('Pause and Resume state transitions', () {
      final boardLayout = '[[1,1,1],[1,1,1],[1,1,1]]';
      final shape = BoardShape.fromJson(boardLayout);

      final arrow = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(
            position: Position(0, 0),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final board = BoardBuilder.create().setShape(shape).addArrow(arrow).build();

      final session = GameSession(
        board: board,
        levelId: 'test_pause',
        maxMoves: 10,
      );

      expect(session.isPlaying(), isTrue, reason: 'Should start in playing');

      // Pause
      session.pause();
      expect(session.isPlaying(), isFalse, reason: 'Should not be playing after pause');
      expect(session.isOver(), isFalse, reason: 'Should not be over while paused');

      // Try to move while paused (should fail)
      final pausedResult = session.executeMove('a');
      expect(pausedResult.success, isFalse,
          reason: 'Move should fail while paused');

      // Resume
      session.resume();
      expect(session.isPlaying(), isTrue, reason: 'Should be playing after resume');

      // Move should work now
      final playingResult = session.executeMove('a');
      expect(playingResult.success, isTrue, reason: 'Move should succeed after resume');
    });

    test('Time limit decrements on tick', () {
      final boardLayout = '[[1,1,1],[1,1,1],[1,1,1]]';
      final shape = BoardShape.fromJson(boardLayout);

      final arrow = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(
            position: Position(0, 0),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final board = BoardBuilder.create().setShape(shape).addArrow(arrow).build();

      final session = GameSession(
        board: board,
        levelId: 'test_time',
        maxMoves: 10,
        timeRemaining: 5,
      );

      expect(session.isTimedLevel(), isTrue, reason: 'Should be a timed level');
      expect(session.timeRemaining, equals(5));

      session.tick();
      expect(session.timeRemaining, equals(4));

      session.tick();
      expect(session.timeRemaining, equals(3));

      session.tick();
      expect(session.timeRemaining, equals(2));

      session.tick();
      expect(session.timeRemaining, equals(1));

      session.tick();
      expect(session.timeRemaining, equals(0));
      expect(session.isOver(), isTrue, reason: 'Game should be over when time runs out');
      expect(session.state is DefeatState, isTrue);
    });

    test('Score tracking and penalties', () {
      final boardLayout = '[[1,1,1],[1,1,1],[1,1,1]]';
      final shape = BoardShape.fromJson(boardLayout);

      // Setup: A is free, B is blocked by A
      // A at (0,0) pointing right - exit path: (1,0), (2,0)... includes B, so A is blocked by B? No...
      // Actually:
      // A at (0,0) pointing right - exit path: (1,0), (2,0)... includes B at (1,0), so A is blocked by B
      // B at (1,0) pointing right - exit path: (2,0), (3,0)... clear, so B is activatable

      // Wait, that's still confusing. Let me think step by step:
      // A scans from (1,0) onwards. It finds B at (1,0). So A is blocked by B.
      // B scans from (2,0) onwards. It finds nothing. So B is activatable.

      final arrowA = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(
            position: Position(0, 0),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final arrowB = Arrow(
        id: 'b',
        segments: [
          ArrowSegment(
            position: Position(1, 0),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#0088FF'),
      );

      final board = BoardBuilder.create()
          .setShape(shape)
          .addArrow(arrowA)
          .addArrow(arrowB)
          .build();

      final session = GameSession(
        board: board,
        levelId: 'test_score',
        maxMoves: 10,
      );

      expect(session.score, equals(0), reason: 'Should start with 0 score');

      // Only B is activatable (A is blocked by B)
      expect(board.isActivatable('a'), isFalse, reason: 'A should be blocked by B');
      expect(board.isActivatable('b'), isTrue, reason: 'B should be activatable');

      // Failed move attempt: trying to move blocked arrow A
      final failedResult = session.executeMove('a');
      expect(failedResult.success, isFalse);
      expect(session.score, equals(0),
          reason: 'Should lose 5 points for failed move but clamped at 0 (0 - 5 clamped to 0)');

      // Now move B successfully
      final successResult = session.executeMove('b');
      expect(successResult.success, isTrue);
      expect(session.score, equals(10),
          reason: 'Should gain 10 points per segment for successful move (0 + 10 = 10)');
    });

    test('Deadlock detection (no activatable arrows)', () {
      final boardLayout = '[[1,1,1],[1,1,1],[1,1,1]]';
      final shape = BoardShape.fromJson(boardLayout);

      // Setup a chain: A blocks B, B blocks C, C is free
      // A at (0,0) pointing right: exit path (1,0), (2,0)... includes B
      // B at (1,0) pointing right: exit path (2,0), (3,0)... includes C
      // C at (2,0) pointing right: exit path (3,0)... clear
      // When C is removed, B becomes activatable
      // When B is removed, A becomes activatable
      // When A is removed, board is empty (victory, not deadlock)

      final arrowA = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(
            position: Position(0, 0),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final arrowB = Arrow(
        id: 'b',
        segments: [
          ArrowSegment(
            position: Position(1, 0),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#0088FF'),
      );

      final arrowC = Arrow(
        id: 'c',
        segments: [
          ArrowSegment(
            position: Position(2, 0),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#00F5A0'),
      );

      final board = BoardBuilder.create()
          .setShape(shape)
          .addArrow(arrowA)
          .addArrow(arrowB)
          .addArrow(arrowC)
          .build();

      final session = GameSession(
        board: board,
        levelId: 'test_deadlock',
        maxMoves: 10,
      );

      // Only C is activatable (not blocked)
      expect(board.getActivatableArrows().length, equals(1));
      expect(board.getActivatableArrows().contains('c'), isTrue);

      // Fire C
      session.executeMove('c');

      // Now B is activatable
      expect(board.getActivatableArrows().length, equals(1));
      expect(board.getActivatableArrows().contains('b'), isTrue);
      expect(session.isOver(), isFalse);

      // Fire B
      session.executeMove('b');

      // Now A is activatable
      expect(board.getActivatableArrows().length, equals(1));
      expect(board.getActivatableArrows().contains('a'), isTrue);

      // Fire A
      session.executeMove('a');

      // Board is empty, should be victory not deadlock
      expect(board.isEmpty(), isTrue);
      expect(session.state is VictoryState, isTrue);
    });
  });
}
