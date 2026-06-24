import 'package:test/test.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/states/victory_state.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

void main() {
  group('Blocking and Activation', () {
    test('Scenario 1: Board with 3 arrows - only C activatable initially', () {
      // Setup:
      // Row 0: . A . .
      // Row 1: . . . .
      // Row 2: . B C .
      // A at (1,0) pointing down - blocked by B at (1,2)
      // B at (1,2) pointing right - blocked by C at (2,2)
      // C at (2,2) pointing right - not blocked

      final boardLayout = '[[1,1,1,1],[1,1,1,1],[1,1,1,1]]';
      final shape = BoardShape.fromJson(boardLayout);

      final arrowA = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(
            position: Position(1, 0),
            directionToNext: Direction.down,
          ),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final arrowB = Arrow(
        id: 'b',
        segments: [
          ArrowSegment(
            position: Position(1, 2),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#0088FF'),
      );

      final arrowC = Arrow(
        id: 'c',
        segments: [
          ArrowSegment(
            position: Position(2, 2),
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

      // Assert: only C is activatable
      final activatable = board.getActivatableArrows();
      expect(activatable.length, equals(1));
      expect(activatable.contains('c'), isTrue);
      expect(board.isActivatable('a'), isFalse);
      expect(board.isActivatable('b'), isFalse);
      expect(board.isActivatable('c'), isTrue);
    });

    test('Scenario 2: Fire C → B becomes activatable', () {
      final boardLayout = '[[1,1,1,1],[1,1,1,1],[1,1,1,1]]';
      final shape = BoardShape.fromJson(boardLayout);

      final arrowA = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(
            position: Position(1, 0),
            directionToNext: Direction.down,
          ),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final arrowB = Arrow(
        id: 'b',
        segments: [
          ArrowSegment(
            position: Position(1, 2),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#0088FF'),
      );

      final arrowC = Arrow(
        id: 'c',
        segments: [
          ArrowSegment(
            position: Position(2, 2),
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

      // Remove C
      board.removeArrow('c');

      // Assert: B is now activatable, A is still blocked
      expect(board.isActivatable('b'), isTrue,
          reason: 'B should be activatable after C is removed');
      expect(board.isActivatable('a'), isFalse,
          reason: 'A should still be blocked by B');
      expect(board.arrows.containsKey('c'), isFalse,
          reason: 'C should be removed from board');
    });

    test('Scenario 3: Fire B → A becomes activatable', () {
      final boardLayout = '[[1,1,1,1],[1,1,1,1],[1,1,1,1]]';
      final shape = BoardShape.fromJson(boardLayout);

      final arrowA = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(
            position: Position(1, 0),
            directionToNext: Direction.down,
          ),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final arrowB = Arrow(
        id: 'b',
        segments: [
          ArrowSegment(
            position: Position(1, 2),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#0088FF'),
      );

      final arrowC = Arrow(
        id: 'c',
        segments: [
          ArrowSegment(
            position: Position(2, 2),
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

      // Remove C then B
      board.removeArrow('c');
      board.removeArrow('b');

      // Assert: A is now activatable
      expect(board.isActivatable('a'), isTrue,
          reason: 'A should be activatable after B is removed');
      expect(board.arrows.containsKey('b'), isFalse,
          reason: 'B should be removed from board');
      expect(board.arrows.containsKey('c'), isFalse,
          reason: 'C should be removed from board');
    });

    test('Scenario 4: Fire A → board empty and VictoryState', () {
      final boardLayout = '[[1,1,1,1],[1,1,1,1],[1,1,1,1]]';
      final shape = BoardShape.fromJson(boardLayout);

      final arrowA = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(
            position: Position(1, 0),
            directionToNext: Direction.down,
          ),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final arrowB = Arrow(
        id: 'b',
        segments: [
          ArrowSegment(
            position: Position(1, 2),
            directionToNext: Direction.right,
          ),
        ],
        color: ArrowColor.fromHex('#0088FF'),
      );

      final arrowC = Arrow(
        id: 'c',
        segments: [
          ArrowSegment(
            position: Position(2, 2),
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
        levelId: 'test_level_1',
        maxMoves: 10,
      );

      // Execute moves in sequence
      final resultC = session.executeMove('c');
      expect(resultC.success, isTrue, reason: 'C should fire successfully');
      expect(board.isEmpty(), isFalse, reason: 'Board should not be empty yet');

      final resultB = session.executeMove('b');
      expect(resultB.success, isTrue, reason: 'B should fire successfully');
      expect(board.isEmpty(), isFalse, reason: 'Board should not be empty yet');

      final resultA = session.executeMove('a');
      expect(resultA.success, isTrue, reason: 'A should fire successfully');

      // Assert: board is empty and state is Victory
      expect(board.isEmpty(), isTrue, reason: 'Board should be empty after all arrows fired');
      expect(session.state is VictoryState, isTrue,
          reason: 'GameSession should be in VictoryState');
      expect(session.isOver(), isTrue, reason: 'Game should be over');
    });
  });
}
