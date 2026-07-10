import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';

/// Level 15's exact geometry (see level-015 in the backend seeder,
/// src/infrastructure/seeders/levels.data.ts): an 18x18 grid whose center
/// (x 5-13, y 5-12) is a hollow, boardless hole — a thick square "O".
/// Regression coverage for two bugs on this shape: the uncovered-cell
/// filler skipping the face-to-face check (arrows staring at each other
/// across the hole), and generation shipping boards with blocking cycles.
BoardShape _ringShape() {
  final cells = <String>{};
  for (int y = 0; y < 18; y++) {
    for (int x = 0; x < 18; x++) {
      final inHole = x >= 5 && x <= 13 && y >= 5 && y <= 12;
      if (!inHole) cells.add('$x,$y');
    }
  }
  return BoardShape(validCells: cells);
}

/// A true face-to-face stare-down: scanning from an arrow's head along its
/// exit direction — tunneling across holes and empty cells, since an arrow
/// on the far side of the hollow center is still on the same board line —
/// the first occupied cell found is another arrow's HEAD pointing straight
/// back. (Hitting another arrow's *body* is ordinary blocking, not a
/// stare-down: the body clears once that arrow fires.)
String? _findFacingArrow(Board board, BoardShape shape, String arrowId) {
  final arrow = board.arrows[arrowId]!;
  final direction = arrow.getDirection();
  final ownCells = arrow.segments.map((s) => s.position.toKey()).toSet();

  var pos = arrow.getHead().position.translate(direction);
  while (pos.x >= 0 && pos.y >= 0 && pos.x < 100 && pos.y < 100) {
    final key = pos.toKey();
    if (shape.contains(pos)) {
      final otherId = board.grid[key];
      if (otherId != null && !ownCells.contains(key)) {
        final other = board.arrows[otherId]!;
        final isTheirHead = other.getHead().position.toKey() == key;
        if (isTheirHead && other.getDirection() == direction.opposite()) {
          return otherId;
        }
        return null;
      }
    }
    pos = pos.translate(direction);
  }
  return null;
}

/// Simulates a full playthrough applying the exact same fire rule as the
/// real game's tap handler (PlayingState.handle): the arrow must be
/// activatable AND must not be blocked by void re-entry (an arrow on the
/// far side of an interior hole). Repeats until the board is empty
/// (solvable) or nothing more can fire (deadlocked).
bool _isFullySolvable(Board board) {
  bool removedSomething = true;
  while (removedSomething && board.arrows.isNotEmpty) {
    removedSomething = false;
    for (final id in board.arrows.keys.toList()) {
      if (board.isActivatable(id) &&
          !board.graph.hasVoidReentry(id, board.arrows, board.grid, board.shape)) {
        board.removeArrow(id);
        removedSomething = true;
      }
    }
  }
  return board.arrows.isEmpty;
}

void main() {
  test(
      'ring boards (level 15\'s "square O") never generate arrows staring '
      'at each other, including across the hollow center', () {
    final shape = _ringShape();

    for (int seed = 0; seed < 30; seed++) {
      final board = BoardBuilder.create(seed: seed)
          .setShape(shape)
          .setDifficulty('HARD')
          .build();

      for (final id in board.arrows.keys) {
        final facing = _findFacingArrow(board, shape, id);
        expect(
          facing,
          isNull,
          reason: 'Arrow $id and $facing point straight at each other '
              '(seed $seed) — the filler step must apply the same '
              'face-to-face rejection as the main generation loop',
        );
      }
    }
  });

  test('ring boards are always fully solvable', () {
    final shape = _ringShape();

    // The exact seed every device uses for this level (see
    // LoadLevelUseCase: seed = levelId.hashCode), plus a spread of others.
    final seeds = ['level-015'.hashCode, for (int s = 0; s < 30; s++) s];

    for (final seed in seeds) {
      final board = BoardBuilder.create(seed: seed)
          .setShape(shape)
          .setDifficulty('HARD')
          .build();

      expect(
        _isFullySolvable(board),
        isTrue,
        reason: 'Ring board with seed $seed shipped with permanently '
            'stuck arrows (a blocking cycle) — generation must keep '
            'retrying rather than shipping an unwinnable board',
      );
    }
  });

  // The most hostile shape level 15 has had: nested 2-cell-thick square
  // rings separated by hole corridors (a previous iteration of the level,
  // and a worst case for blocking cycles). The always-solvable guarantee
  // must hold even here.
  test('nested-ring (spiral) boards are always fully solvable', () {
    const grid = [
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
      [1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1],
      [1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1],
      [1,1,0,1,1,0,0,0,0,0,0,0,1,1,0,1,1],
      [1,1,0,1,1,0,1,1,1,1,1,0,1,1,0,1,1],
      [1,1,0,1,1,0,1,1,1,1,1,0,1,1,0,1,1],
      [1,1,0,1,1,0,1,1,0,0,0,0,1,1,0,1,1],
      [1,1,0,1,1,0,1,1,0,0,0,0,1,1,0,1,1],
      [1,1,0,1,1,0,1,1,1,1,1,0,1,1,0,1,1],
      [1,1,0,1,1,0,1,1,1,1,1,0,1,1,0,1,1],
      [1,1,0,1,1,0,0,0,0,1,1,0,1,1,0,1,1],
      [1,1,0,1,1,1,1,1,1,1,1,0,1,1,0,1,1],
      [1,1,0,1,1,1,1,1,1,1,1,0,1,1,0,1,1],
      [1,1,0,0,0,0,0,0,0,0,0,0,1,1,0,1,1],
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1],
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1],
    ];
    final cells = <String>{};
    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        if (grid[y][x] == 1) cells.add('$x,$y');
      }
    }
    final shape = BoardShape(validCells: cells);

    for (int seed = 0; seed < 15; seed++) {
      final board = BoardBuilder.create(seed: seed)
          .setShape(shape)
          .setDifficulty('HARD')
          .build();

      expect(
        _isFullySolvable(board),
        isTrue,
        reason: 'Spiral board with seed $seed shipped with permanently '
            'stuck arrows — the solvability guarantee must hold on any shape',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
