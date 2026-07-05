import 'package:test/test.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/graph/board_graph.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/grid_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/hammer_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/hint_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/magnet_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

/// A genuinely empty board (no arrows, no activatable), bypassing
/// BoardBuilder.build()'s auto-generation — calling build() on a builder
/// with no arrows added triggers the random generator instead of staying
/// empty, which isn't what "no activatable arrows" scenarios want to test.
Board _emptyBoard(BoardShape shape) => Board(
      shape: shape,
      arrows: {},
      grid: {},
      graph: BoardGraph.empty(),
    );

void main() {
  group('Power-ups', () {
    test('Scenario 6: Hammer removes blocked arrow and updates graph', () {
      // Simpler setup:
      // A (2 segments) at (0,0)-(1,0) pointing right
      // B (1 segment) at (2,0) pointing right
      // C (1 segment) at (0,1) pointing right
      final boardLayout = '{"grid": [[1,1,1,1],[1,1,1,1],[1,1,1,1]]}';
      final shape = BoardShape.fromJson(boardLayout);

      final arrowA = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(position: Position(0, 0), directionToNext: Direction.right),
          ArrowSegment(position: Position(1, 0), directionToNext: Direction.right),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final arrowB = Arrow(
        id: 'b',
        segments: [
          ArrowSegment(position: Position(2, 0), directionToNext: Direction.right),
        ],
        color: ArrowColor.fromHex('#0088FF'),
      );

      final arrowC = Arrow(
        id: 'c',
        segments: [
          ArrowSegment(position: Position(0, 1), directionToNext: Direction.right),
        ],
        color: ArrowColor.fromHex('#00F5A0'),
      );

      final board = BoardBuilder.create()
          .setShape(shape)
          .addArrow(arrowA)
          .addArrow(arrowB)
          .addArrow(arrowC)
          .build();

      // A (head at 1,0) scans from (2,0) and finds B there. So A is blocked by B.
      // B (head at 2,0) scans from (3,0). Clear. So B is activatable.
      // C (head at 0,1) scans from (1,1). Clear. So C is activatable.
      expect(board.isActivatable('a'), isFalse, reason: 'A should be blocked by B');
      expect(board.isActivatable('b'), isTrue, reason: 'B should be activatable');
      expect(board.isActivatable('c'), isTrue, reason: 'C should be activatable');

      // Apply hammer on B (the blocker)
      final hammer = HammerPowerUp(targetArrowId: 'b');
      final result = hammer.use(board);

      expect(result.success, isTrue, reason: 'Hammer should successfully remove B');
      expect(board.arrows.containsKey('b'), isFalse, reason: 'B should be removed');
      expect(board.isActivatable('a'), isTrue,
          reason: 'A should be activatable after B is removed');
      expect(board.isActivatable('c'), isTrue);
    });

    test('Hammer on non-existent arrow fails gracefully', () {
      final boardLayout = '{"grid": [[1,1,1],[1,1,1],[1,1,1]]}';
      final shape = BoardShape.fromJson(boardLayout);

      final arrow = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(position: Position(0, 0), directionToNext: Direction.right),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final board = BoardBuilder.create().setShape(shape).addArrow(arrow).build();

      final hammer = HammerPowerUp(targetArrowId: 'nonexistent');
      final result = hammer.use(board);

      expect(result.success, isFalse, reason: 'Should fail for non-existent arrow');
      expect(result.message, contains('not found'));
    });

    test('Hint power-up returns activatable arrow', () {
      final boardLayout = '{"grid": [[1,1,1],[1,1,1],[1,1,1]]}';
      final shape = BoardShape.fromJson(boardLayout);

      final arrowA = Arrow(
        id: 'a',
        segments: [
          ArrowSegment(position: Position(0, 0), directionToNext: Direction.right),
        ],
        color: ArrowColor.fromHex('#FF3366'),
      );

      final arrowB = Arrow(
        id: 'b',
        segments: [
          ArrowSegment(position: Position(1, 0), directionToNext: Direction.right),
        ],
        color: ArrowColor.fromHex('#0088FF'),
      );

      final board = BoardBuilder.create()
          .setShape(shape)
          .addArrow(arrowA)
          .addArrow(arrowB)
          .build();

      final hint = HintPowerUp();
      final result = hint.use(board);

      expect(result.success, isTrue, reason: 'Hint should succeed when activatable arrows exist');
      expect(result.affectedArrowIds, equals(['b']),
          reason: 'Should hint at B (the only activatable arrow)');
    });

    test('Hint fails when no activatable arrows', () {
      final shape = BoardShape.fromJson('{"grid": [[1,1,1],[1,1,1],[1,1,1]]}');
      final hint = HintPowerUp();
      final result = hint.use(_emptyBoard(shape));

      expect(result.success, isFalse, reason: 'Hint should fail on an empty board');
      expect(result.message, contains('available'));
    });

    test('Magnet removes up to 5 activatable arrows regardless of direction', () {
      // 6 rows, one single-cell arrow per row pointing right with nothing
      // else in its row — all 6 are activatable, no direction involved.
      final shape = BoardShape.fromJson(
          '{"grid": [[1,1,1],[1,1,1],[1,1,1],[1,1,1],[1,1,1],[1,1,1]]}');

      var builder = BoardBuilder.create().setShape(shape);
      for (int row = 0; row < 6; row++) {
        builder = builder.addArrow(Arrow(
          id: 'row$row',
          segments: [
            ArrowSegment(position: Position(0, row), directionToNext: Direction.right),
          ],
          color: ArrowColor.fromHex('#FF3366'),
        ));
      }
      final board = builder.build();

      expect(board.getActivatableArrows().length, equals(6));

      final magnet = MagnetPowerUp();
      final result = magnet.use(board);

      expect(result.success, isTrue);
      expect(result.affectedArrowIds.length, equals(MagnetPowerUp.maxArrowsRemoved));
      expect(board.arrows.length, equals(1), reason: 'Exactly 1 of the 6 should remain');
    });

    test('Magnet removes every activatable arrow when fewer than 5 exist', () {
      final boardLayout = '{"grid": [[1,1,1],[1,1,1],[1,1,1]]}';
      final shape = BoardShape.fromJson(boardLayout);

      final board = BoardBuilder.create()
          .setShape(shape)
          .addArrow(Arrow(
            id: 'right',
            segments: [
              ArrowSegment(position: Position(0, 0), directionToNext: Direction.right),
            ],
            color: ArrowColor.fromHex('#FF3366'),
          ))
          .addArrow(Arrow(
            id: 'down',
            segments: [
              ArrowSegment(position: Position(0, 1), directionToNext: Direction.down),
            ],
            color: ArrowColor.fromHex('#0088FF'),
          ))
          .build();

      expect(board.getActivatableArrows().length, equals(2));

      final magnet = MagnetPowerUp();
      final result = magnet.use(board);

      expect(result.success, isTrue);
      expect(result.affectedArrowIds.toSet(), equals({'right', 'down'}));
      expect(board.arrows, isEmpty);
    });

    test('Magnet fails when no activatable arrows', () {
      final shape = BoardShape.fromJson('{"grid": [[1,1,1],[1,1,1],[1,1,1]]}');
      final magnet = MagnetPowerUp();
      final result = magnet.use(_emptyBoard(shape));

      expect(result.success, isFalse,
          reason: 'Magnet should fail when there are no activatable arrows');
    });

    test('Grid power-up reveals every arrow without mutating the board', () {
      final boardLayout = '{"grid": [[1,1,1],[1,1,1],[1,1,1]]}';
      final shape = BoardShape.fromJson(boardLayout);

      final board = BoardBuilder.create()
          .setShape(shape)
          .addArrow(Arrow(
            id: 'a',
            segments: [
              ArrowSegment(position: Position(0, 0), directionToNext: Direction.right),
            ],
            color: ArrowColor.fromHex('#FF3366'),
          ))
          .build();

      final grid = GridPowerUp();
      final result = grid.use(board);

      expect(result.success, isTrue);
      expect(board.arrows.containsKey('a'), isTrue,
          reason: 'Grid is informational only — it must not remove arrows');
    });

    test('Hammer cost is defined', () {
      final hammer = HammerPowerUp(targetArrowId: 'test');
      expect(hammer.getCost(), equals(100));
      expect(hammer.getType(), equals('HAMMER'));
    });

    test('Hint cost is defined', () {
      final hint = HintPowerUp();
      expect(hint.getCost(), equals(100));
      expect(hint.getType(), equals('HINT'));
    });

    test('Magnet cost is defined', () {
      final magnet = MagnetPowerUp();
      expect(magnet.getCost(), equals(500));
      expect(magnet.getType(), equals('MAGNET'));
    });

    test('Grid cost is defined', () {
      final grid = GridPowerUp();
      expect(grid.getCost(), equals(50));
      expect(grid.getType(), equals('GRID'));
    });
  });
}
