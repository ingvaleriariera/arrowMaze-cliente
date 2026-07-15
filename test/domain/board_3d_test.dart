import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

// 3D board support: cells with 6 connections (up/down/left/right +
// forward/back along Z). The backend keeps sending flat 0/1 grids; the
// client extrudes the silhouette into an N-layer prism and the whole
// pipeline (shape, graph, generation, solvability) works on it.

BoardShape _flatSquare(int side) {
  final cells = <String>{};
  for (int y = 0; y < side; y++) {
    for (int x = 0; x < side; x++) {
      cells.add('$x,$y');
    }
  }
  return BoardShape(validCells: cells);
}

Arrow _singleCellArrow(String id, Position pos, Direction dir) => Arrow(
      id: id,
      segments: [ArrowSegment(position: pos, directionToNext: dir)],
      color: ArrowColor.fromHex('#00f5a0'),
    );

/// Same fire rule as the real game's tap handler.
bool _isFullySolvable(Board board) {
  bool removed = true;
  while (removed && board.arrows.isNotEmpty) {
    removed = false;
    for (final id in board.arrows.keys.toList()) {
      if (board.isActivatable(id) &&
          !board.graph.hasVoidReentry(id, board.arrows, board.grid, board.shape)) {
        board.removeArrow(id);
        removed = true;
      }
    }
  }
  return board.arrows.isEmpty;
}

void main() {
  group('Position and Direction in 3D', () {
    test('position defaults to z=0 and keeps the 2-part canonical key', () {
      const pos = Position(3, 5);
      expect(pos.z, 0);
      expect(pos.toKey(), '3,5');
    });

    test('positions above the base layer use the 3-part key', () {
      const pos = Position(3, 5, 2);
      expect(pos.toKey(), '3,5,2');
      expect(Position.fromKey('3,5,2'), pos);
      expect(Position.fromKey('3,5'), const Position(3, 5));
    });

    test('translate moves along all three axes', () {
      const start = Position(1, 1, 1);
      expect(start.translate(Direction.right), const Position(2, 1, 1));
      expect(start.translate(Direction.forward), const Position(1, 1, 2));
      expect(start.translate(Direction.back), const Position(1, 1, 0));
    });

    test('opposite() covers all 6 directions', () {
      expect(Direction.forward.opposite(), Direction.back);
      expect(Direction.back.opposite(), Direction.forward);
      expect(Direction.up.opposite(), Direction.down);
      expect(Direction.left.opposite(), Direction.right);
    });
  });

  group('BoardShape.extrude', () {
    test('multiplies the silhouette by depth (54 cells → 216 at depth 4)', () {
      // A silhouette with 54 cells, like the heart example.
      final flat = BoardShape(validCells: {
        for (int i = 0; i < 54; i++) '${i % 9},${i ~/ 9}',
      });
      final prism = BoardShape.extrude(flat, 4);
      expect(prism.size(), 54 * 4);
    });

    test('every layer repeats the exact silhouette', () {
      final flat = _flatSquare(3);
      final prism = BoardShape.extrude(flat, 4);
      for (int z = 0; z < 4; z++) {
        for (int y = 0; y < 3; y++) {
          for (int x = 0; x < 3; x++) {
            expect(prism.contains(Position(x, y, z)), isTrue,
                reason: 'cell ($x,$y,$z) must exist');
          }
        }
      }
      expect(prism.contains(const Position(0, 0, 4)), isFalse);
    });

    test('depth=1 leaves a 2D shape byte-for-byte identical', () {
      final flat = _flatSquare(4);
      final same = BoardShape.extrude(flat, 1);
      expect(same.validCells, flat.validCells);
    });

    test('front and back faces are exits', () {
      final prism = BoardShape.extrude(_flatSquare(3), 4);
      // Back face: z=0 exiting toward z=-1.
      expect(prism.isExitFrom(const Position(1, 1, 0), Direction.back), isTrue);
      // Front face: z=3 exiting toward z=4.
      expect(
          prism.isExitFrom(const Position(1, 1, 3), Direction.forward), isTrue);
      // Interior along Z: not an exit.
      expect(
          prism.isExitFrom(const Position(1, 1, 1), Direction.forward), isFalse);
    });
  });

  group('BoardGraph with 6 connections', () {
    test('an arrow is blocked through Z and freed when the blocker fires', () {
      final prism = BoardShape.extrude(_flatSquare(3), 3);

      // "a" at the bottom layer points forward (into the prism); "b" sits
      // directly above it on layer 2 and points right (free to exit).
      final a = _singleCellArrow('a', const Position(1, 1, 0), Direction.forward);
      final b = _singleCellArrow('b', const Position(1, 1, 2), Direction.right);

      final board = BoardBuilder.fromArrows(prism, [a, b]);

      expect(board.graph.nodes['a']!.blockedBy, contains('b'),
          reason: 'the Z-ray from a must find b two layers above');
      expect(board.isActivatable('a'), isFalse);
      expect(board.isActivatable('b'), isTrue);

      board.removeArrow('b');
      expect(board.isActivatable('a'), isTrue,
          reason: 'once b fires, a exits through the front face');
    });

    test('Z-rays terminate at the prism bounds (no infinite scan)', () {
      final prism = BoardShape.extrude(_flatSquare(2), 4);
      final arrow =
          _singleCellArrow('solo', const Position(0, 0, 0), Direction.forward);

      // Building the graph walks the ray to the bound; if the Z bound were
      // missing this would never return.
      final board = BoardBuilder.fromArrows(prism, [arrow]);
      expect(board.isActivatable('solo'), isTrue);
    });
  });

  group('Generation on extruded boards', () {
    test('generates solvable prisms using the Z axis', () {
      final flat = _flatSquare(4);
      var sawZDirection = false;

      for (int seed = 0; seed < 10; seed++) {
        final prism = BoardShape.extrude(flat, 3);
        final board = BoardBuilder.create(seed: seed)
            .setShape(prism)
            .setDifficulty('medium')
            .build();

        // Every cell of every layer ends up covered.
        expect(board.grid.length, prism.size(),
            reason: 'all ${prism.size()} prism cells must be covered (seed $seed)');

        // The generator actually uses the new connections.
        sawZDirection = sawZDirection ||
            board.arrows.values.any((arrow) =>
                arrow.getDirection().dz != 0 ||
                arrow.segments.any((s) => s.directionToNext.dz != 0));

        expect(_isFullySolvable(board), isTrue,
            reason: 'prism with seed $seed must be fully solvable');
      }

      expect(sawZDirection, isTrue,
          reason: 'across 10 seeds, at least one arrow must use forward/back');
    });

    test('flat boards still never use Z directions (2D behavior intact)', () {
      final board = BoardBuilder.create(seed: 7)
          .setShape(_flatSquare(5))
          .setDifficulty('easy')
          .build();

      for (final arrow in board.arrows.values) {
        expect(arrow.getDirection().dz, 0);
        for (final segment in arrow.segments) {
          expect(segment.directionToNext.dz, 0);
        }
      }
      expect(_isFullySolvable(board), isTrue);
    });
  });
}
