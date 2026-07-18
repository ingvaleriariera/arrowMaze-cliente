// Coverage for the hexagonal (6-neighbor, axial-coordinate) board mode:
// shape generation (hexagon/hexagonRing), arrow generation restricted to
// Direction.hexAll, and solvability of both board presets used by
// HexBoardScreen (simple hexagon, complex ring).
import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';

void main() {
  test('hexagon(radius) produces the expected cell count', () {
    // 3*r^2 + 3*r + 1 cells for a hex-of-hexagons of radius r.
    expect(BoardShape.hexagon(0).size(), 1);
    expect(BoardShape.hexagon(1).size(), 7);
    expect(BoardShape.hexagon(2).size(), 19);
    expect(BoardShape.hexagon(3).size(), 37);
  });

  test('a hex board generates arrows that only use the 6 hex directions', () {
    final shape = BoardShape.hexagon(3);
    final builder = BoardBuilder.create(seed: 42, useHexDirections: true)
      ..setShape(shape)
      ..setDifficulty('EASY');

    final board = builder.build();

    expect(board.arrows, isNotEmpty);
    for (final arrow in board.arrows.values) {
      final dir = arrow.getDirection();
      final isHexDir = Direction.hexAll.any((h) =>
          h.dx == dir.dx && h.dy == dir.dy && h.dz == dir.dz);
      expect(isHexDir, isTrue,
          reason: 'Arrow ${arrow.id} used a non-hex direction: $dir');
    }
  });

  test('a hex board is solvable: repeatedly clearing activatable arrows empties it', () {
    final shape = BoardShape.hexagon(2);
    final builder = BoardBuilder.create(seed: 7, useHexDirections: true)
      ..setShape(shape)
      ..setDifficulty('EASY');

    final board = builder.build();
    final totalArrows = board.arrows.length;
    expect(totalArrows, greaterThan(0));

    var safety = 0;
    while (board.arrows.isNotEmpty && safety < totalArrows + 5) {
      final activatable = board.getActivatableArrows();
      expect(activatable, isNotEmpty,
          reason: 'Board got stuck with ${board.arrows.length} arrows left '
              '— deadlock in a hex-generated board');
      board.removeArrow(activatable.first);
      safety++;
    }

    expect(board.arrows, isEmpty);
  });

  test('hexagonRing(outer, inner) punches the expected hole', () {
    // outer(7) has 169 cells, inner(3) has 37 — the ring is the difference.
    final ring = BoardShape.hexagonRing(7, 3);
    expect(ring.size(), 169 - 37);
  });

  test('the complex (ring-shaped) hex board is also solvable', () {
    final shape = BoardShape.hexagonRing(7, 3);
    final builder = BoardBuilder.create(seed: 99, useHexDirections: true)
      ..setShape(shape)
      ..setDifficulty('HARD');

    final board = builder.build();
    final totalArrows = board.arrows.length;
    expect(totalArrows, greaterThan(0));

    var safety = 0;
    while (board.arrows.isNotEmpty && safety < totalArrows + 5) {
      final activatable = board.getActivatableArrows();
      expect(activatable, isNotEmpty,
          reason: 'Ring board got stuck with ${board.arrows.length} arrows '
              'left — deadlock on the more complex hex shape');
      board.removeArrow(activatable.first);
      safety++;
    }

    expect(board.arrows, isEmpty);
  });
}
