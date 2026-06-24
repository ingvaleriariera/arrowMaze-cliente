import 'package:test/test.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

void main() {
  group('Entities', () {
    group('Arrow', () {
      test('Arrow has segments and color', () {
        final segments = [
          ArrowSegment(
            position: Position(0, 0),
            directionToNext: Direction.right,
          ),
          ArrowSegment(
            position: Position(1, 0),
            directionToNext: Direction.right,
          ),
        ];
        final color = ArrowColor.fromHex('#FF3366');

        final arrow = Arrow(
          id: 'a1',
          segments: segments,
          color: color,
        );

        expect(arrow.id, equals('a1'));
        expect(arrow.segments.length, equals(2));
        expect(arrow.color, equals(color));
      });

      test('Arrow.getHead returns first segment', () {
        final segments = [
          ArrowSegment(
            position: Position(0, 0),
            directionToNext: Direction.right,
          ),
          ArrowSegment(
            position: Position(1, 0),
            directionToNext: Direction.right,
          ),
        ];

        final arrow = Arrow(
          id: 'a1',
          segments: segments,
          color: ArrowColor.fromHex('#FF3366'),
        );

        expect(arrow.getHead(), equals(segments.first));
      });

      test('Arrow.getDirection returns head direction', () {
        final segments = [
          ArrowSegment(
            position: Position(0, 0),
            directionToNext: Direction.down,
          ),
          ArrowSegment(
            position: Position(0, 1),
            directionToNext: Direction.down,
          ),
        ];

        final arrow = Arrow(
          id: 'a1',
          segments: segments,
          color: ArrowColor.fromHex('#FF3366'),
        );

        expect(arrow.getDirection(), equals(Direction.down));
      });

      test('Arrow requires at least one segment', () {
        expect(
          () => Arrow(
            id: 'a1',
            segments: [],
            color: ArrowColor.fromHex('#FF3366'),
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('BoardShape', () {
      test('BoardShape.fromJson parses valid JSON', () {
        final json = '[[1,1,1],[1,0,1],[1,1,1]]';
        final shape = BoardShape.fromJson(json);

        expect(shape.size(), equals(8), reason: '3x3 grid minus center = 8 cells');
        expect(shape.contains(Position(0, 0)), isTrue);
        expect(shape.contains(Position(1, 1)), isFalse, reason: 'Center is void');
        expect(shape.contains(Position(2, 2)), isTrue);
      });

      test('BoardShape.isExitFrom detects board edge', () {
        final json = '[[1,1,1],[1,1,1],[1,1,1]]';
        final shape = BoardShape.fromJson(json);

        final pos = Position(0, 0);

        // Up from (0,0) is outside board
        expect(shape.isExitFrom(pos, Direction.up), isTrue);

        // Left from (0,0) is outside board
        expect(shape.isExitFrom(pos, Direction.left), isTrue);

        // Right from (0,0) stays on board
        expect(shape.isExitFrom(pos, Direction.right), isFalse);

        // Down from (0,0) stays on board
        expect(shape.isExitFrom(pos, Direction.down), isFalse);
      });

      test('BoardShape.isExitFrom detects void cells', () {
        final json = '[[1,1,1],[1,0,1],[1,1,1]]';
        final shape = BoardShape.fromJson(json);

        // From (1,0) going down, (1,1) is void (exit)
        expect(shape.isExitFrom(Position(1, 0), Direction.down), isTrue);

        // From (0,1) going right, (1,1) is void (exit)
        expect(shape.isExitFrom(Position(0, 1), Direction.right), isTrue);
      });

      test('BoardShape.getCells returns all valid cells', () {
        final json = '[[1,1],[1,1]]';
        final shape = BoardShape.fromJson(json);

        final cells = shape.getCells();
        expect(cells.length, equals(4));
        expect(cells.map((p) => p.toKey()).toSet(),
            equals({'0,0', '1,0', '0,1', '1,1'}));
      });
    });

    group('Level', () {
      test('Level stores configuration', () {
        final boardLayout = '[[1,1,1],[1,1,1],[1,1,1]]';
        final timeLimit = TimeLimit.of(120);

        final level = Level(
          id: 'level_001',
          difficulty: 'MEDIUM',
          boardLayout: boardLayout,
          moveLimit: 20,
          timeLimit: timeLimit,
        );

        expect(level.id, equals('level_001'));
        expect(level.difficulty, equals('MEDIUM'));
        expect(level.moveLimit, equals(20));
        expect(level.isTimed(), isTrue);
      });

      test('Level.getBoardShape parses layout', () {
        final boardLayout = '[[1,0,1],[1,1,1],[1,0,1]]';
        final level = Level(
          id: 'level_001',
          difficulty: 'EASY',
          boardLayout: boardLayout,
          moveLimit: 15,
          timeLimit: TimeLimit.none,
        );

        final shape = level.getBoardShape();
        expect(shape.size(), equals(7));
        expect(shape.contains(Position(1, 0)), isFalse);
      });

      test('Level.isTimed returns false for no time limit', () {
        final level = Level(
          id: 'level_001',
          difficulty: 'EASY',
          boardLayout: '[[1,1,1],[1,1,1],[1,1,1]]',
          moveLimit: 15,
          timeLimit: TimeLimit.none,
        );

        expect(level.isTimed(), isFalse);
      });
    });

    group('GameProgress', () {
      test('GameProgress tracks completion and scores', () {
        final progress = GameProgress(
          userId: 'user_123',
          completedLevels: ['level_001'],
          bestScores: {'level_001': 500},
          coins: 100,
        );

        expect(progress.userId, equals('user_123'));
        expect(progress.isCompleted('level_001'), isTrue);
        expect(progress.isCompleted('level_002'), isFalse);
        expect(progress.getBestScore('level_001'), equals(500));
        expect(progress.coins, equals(100));
      });

      test('GameProgress.recordCompletion updates best score', () {
        final progress = GameProgress(userId: 'user_123');

        progress.recordCompletion('level_001', 300);
        expect(progress.isCompleted('level_001'), isTrue);
        expect(progress.getBestScore('level_001'), equals(300));

        // Completing again with higher score
        progress.recordCompletion('level_001', 400);
        expect(progress.getBestScore('level_001'), equals(400));

        // Completing again with lower score
        progress.recordCompletion('level_001', 350);
        expect(progress.getBestScore('level_001'), equals(400),
            reason: 'Best score should not decrease');
      });

      test('GameProgress.addCoins increases coin count', () {
        final progress = GameProgress(userId: 'user_123', coins: 50);

        progress.addCoins(30);
        expect(progress.coins, equals(80));

        progress.addCoins(0);
        expect(progress.coins, equals(80));
      });

      test('GameProgress.spendCoins deducts if sufficient', () {
        final progress = GameProgress(userId: 'user_123', coins: 100);

        final spent1 = progress.spendCoins(30);
        expect(spent1, isTrue);
        expect(progress.coins, equals(70));

        final spent2 = progress.spendCoins(100);
        expect(spent2, isFalse, reason: 'Should fail if insufficient coins');
        expect(progress.coins, equals(70), reason: 'Coins should not change');
      });

      test('GameProgress with defaults', () {
        final progress = GameProgress(userId: 'user_123');

        expect(progress.completedLevels, isEmpty);
        expect(progress.bestScores, isEmpty);
        expect(progress.coins, equals(0));
      });
    });

    group('Board Operations', () {
      test('Board.getArrowAt returns arrow at position', () {
        final boardLayout = '[[1,1,1],[1,1,1],[1,1,1]]';
        final shape = BoardShape.fromJson(boardLayout);

        final arrow = Arrow(
          id: 'a',
          segments: [
            ArrowSegment(
              position: Position(1, 1),
              directionToNext: Direction.right,
            ),
          ],
          color: ArrowColor.fromHex('#FF3366'),
        );

        final board = BoardBuilder.create()
            .setShape(shape)
            .addArrow(arrow)
            .build();

        expect(board.getArrowAt(Position(1, 1)), equals(arrow));
        expect(board.getArrowAt(Position(0, 0)), isNull);
      });

      test('Board.getHint returns first activatable arrow', () {
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

        final hint = board.getHint();
        expect(hint, isNotNull);
        expect(board.isActivatable(hint!), isTrue);
      });

      test('Board.isEmpty returns true only when no arrows', () {
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

        final board = BoardBuilder.create()
            .setShape(shape)
            .addArrow(arrow)
            .build();

        expect(board.isEmpty(), isFalse);

        board.removeArrow('a');
        expect(board.isEmpty(), isTrue);
      });
    });
  });
}
