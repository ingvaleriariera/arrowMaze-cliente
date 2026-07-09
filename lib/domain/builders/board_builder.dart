import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/graph/board_graph.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

class BoardBuilder {
  late BoardShape _shape;
  late String _difficultyStr;
  late Random _random;
  final Map<String, Arrow> _arrows = {};
  int? _calculatedMaxMoves;

  BoardBuilder({int? seed}) {
    _random = Random(seed);
    _difficultyStr = 'EASY';
  }

  static BoardBuilder create({int? seed}) => BoardBuilder(seed: seed);

  /// Builds a fresh, unplayed [Board] from an already-known arrow layout
  /// (e.g. one pulled from [IBoardCache]) instead of searching for a new
  /// one. Cheap and synchronous: it's just grid/graph bookkeeping over
  /// arrows that already exist, none of BoardBuilder's randomized retry
  /// loop runs.
  static Board fromArrows(BoardShape shape, List<Arrow> arrows) {
    final builder = BoardBuilder.create()..setShape(shape);
    for (final arrow in arrows) {
      builder.addArrow(arrow);
    }
    return builder.build();
  }

  BoardBuilder setShape(BoardShape shape) {
    _shape = shape;
    return this;
  }

  /// Only the maxMoves margin still depends on difficulty — arrow length
  /// and density are now driven purely by board size (see _generateArrows).
  BoardBuilder setDifficulty(String difficultyStr) {
    _difficultyStr = difficultyStr.toUpperCase();
    return this;
  }

  int? getCalculatedMaxMoves() => _calculatedMaxMoves;

  /// Move-limit margin over the arrow count, by difficulty. Exposed
  /// statically so callers that reuse an already-generated [Board] (e.g.
  /// from a preload cache) can recompute the same maxMoves without
  /// re-running generation just to read [_calculatedMaxMoves].
  static int calculateMaxMoves(int totalArrows, String difficultyStr) {
    final margin = difficultyStr == 'HARD'
        ? 0.15
        : difficultyStr == 'MEDIUM'
            ? 0.25
            : 0.35;
    return (totalArrows * (1 + margin)).ceil();
  }

  BoardBuilder addArrow(Arrow arrow) {
    _arrows[arrow.id] = arrow;
    return this;
  }

  Board build() {
    // If arrows were manually added, just build the graph
    if (_arrows.isNotEmpty) {
      return _buildWithExistingArrows();
    }

    // Generate arrows automatically
    return _generateAndBuild();
  }

  Board _buildWithExistingArrows() {
    final grid = <String, String>{};
    for (final arrow in _arrows.values) {
      for (final segment in arrow.segments) {
        grid[segment.position.toKey()] = arrow.id;
      }
    }

    final graph = BoardGraph.empty();
    graph.build(_arrows, grid, _shape);

    return Board(
      shape: _shape,
      arrows: _arrows,
      grid: grid,
      graph: graph,
    );
  }

  Board _generateAndBuild() {
    Map<String, Arrow>? bestArrows;
    var bestStuckCount = 1 << 30;

    // Try up to 80 times to generate a VALID, fully solvable puzzle (not
    // all arrows free, and no arrow left permanently stuck). Each attempt
    // rebuilds the whole board graph, so this is the most expensive loop
    // in generation — keep it tight now that difficulty is mapped
    // correctly and longer arrows make a valid puzzle easy to find.
    //
    // _generateArrows can return false (hit its iteration/fail-streak cap
    // before covering every cell) — still run _fillUncoveredCells and the
    // solvability probe on whatever it managed rather than discarding the
    // attempt outright, since a partial-but-solvable layout plus a filled
    // remainder is still a usable candidate.
    for (int attempt = 0; attempt < 80; attempt++) {
      _arrows.clear();
      _generateArrows();
      _fillUncoveredCells();

      final totalArrows = _arrows.length;
      if (totalArrows <= 3) continue;

      // Probe on a throwaway graph: _countUnsolvable drains it via
      // removeArrow, so the board actually returned below needs its own
      // fresh one.
      final probe = _buildWithExistingArrows();
      final activatable = probe.graph.getActivatable();
      if (activatable.length >= totalArrows) {
        debugPrint(
            '🧪 Generation attempt $attempt: all arrows free, retrying...');
        continue;
      }

      // A filled-in leftover cell (or any other blocking combination) can
      // leave one or more arrows with no valid removal order — a level
      // that looks fine but can never be finished. Simulating a full
      // playthrough (remove every currently activatable arrow, repeat)
      // catches that, which just checking "not all arrows start free"
      // doesn't.
      final stuck = _countUnsolvable(probe);
      debugPrint(
          '🧪 Generation attempt $attempt: $totalArrows arrows, ${activatable.length} activatable, $stuck stuck');

      if (stuck == 0) {
        debugPrint('✅ Valid puzzle found!');
        _calculatedMaxMoves = calculateMaxMoves(totalArrows, _difficultyStr);
        return _buildWithExistingArrows();
      }

      if (stuck < bestStuckCount) {
        bestStuckCount = stuck;
        bestArrows = Map.of(_arrows);
      }
    }

    // Every attempt left something unsolvable — ship the closest call we
    // saw (fewest permanently-stuck arrows) instead of blindly the
    // arbitrary last attempt, which could be far worse.
    debugPrint(
        '⚠️  Max attempts reached, using best candidate ($bestStuckCount stuck arrow(s))');
    if (bestArrows != null) {
      _arrows
        ..clear()
        ..addAll(bestArrows);
    }
    final board = _buildWithExistingArrows();
    _calculatedMaxMoves = calculateMaxMoves(_arrows.length, _difficultyStr);
    return board;
  }

  /// Number of arrows with no valid removal order, simulated by
  /// repeatedly removing every currently activatable arrow — exactly
  /// like a player clearing the board — until nothing more can be
  /// removed. Mutates [board]'s graph in place, so callers must only use
  /// this on a throwaway probe board, never the one that's actually
  /// returned.
  int _countUnsolvable(Board board) {
    final remaining = Set<String>.from(board.arrows.keys);

    while (remaining.isNotEmpty) {
      final activatable =
          board.graph.getActivatable().where(remaining.contains).toList();
      if (activatable.isEmpty) break;
      for (final id in activatable) {
        board.graph.removeArrow(id);
        remaining.remove(id);
      }
    }

    return remaining.length;
  }

  static const int _maxGenerationIterations = 200;

  bool _generateArrows() {
    final remaining = Set<String>.from(_shape.validCells);
    final grid = <String, String>{};
    int failStreak = 0;
    int arrowIndex = 0;
    int totalIterations = 0;

    // Boards this big (>=7 on either side, per the now-much-larger
    // backend boardLayouts) can fit the long 8-15 segment arrows from the
    // SayGames-style density target; smaller boards fold that bucket's
    // share into "medium" instead, since a 15-segment arrow can't fit.
    final allowLong = _boardSpansAtLeast(7);

    while (remaining.isNotEmpty) {
      totalIterations++;
      if (failStreak > 100 || totalIterations > _maxGenerationIterations) {
        return false;
      }

      final arrowData = _findActivatableArrow(remaining, grid, allowLong);
      if (arrowData == null) {
        failStreak++;
        continue;
      }

      failStreak = 0;

      // Create arrow
      final arrowId = 'arrow_$arrowIndex';
      final color = _getColorForIndex(arrowIndex);
      final segments = _createArrowSegments(arrowData['cells'] as List<Position>,
          arrowData['direction'] as Direction);

      final arrow = Arrow(
        id: arrowId,
        segments: segments,
        color: color,
      );

      _arrows[arrowId] = arrow;

      // Register cells in grid
      for (final segment in segments) {
        grid[segment.position.toKey()] = arrowId;
      }

      // Remove cells from remaining
      for (final pos in arrowData['cells'] as List<Position>) {
        remaining.remove(pos.toKey());
      }

      arrowIndex++;
    }

    return true;
  }

  /// Guarantees every valid cell ends up covered by some arrow. A failed
  /// or abandoned generation attempt (failStreak/iteration cap hit, or the
  /// 60-attempt fallback) can leave a few cells unclaimed because no
  /// activatable path could be grown from them in time; rather than ship
  /// a board with dead, arrow-less cells, fill any leftovers here with
  /// small 1-2 segment arrows grown only through other leftover cells.
  void _fillUncoveredCells() {
    final grid = <String, String>{};
    for (final arrow in _arrows.values) {
      for (final segment in arrow.segments) {
        grid[segment.position.toKey()] = arrow.id;
      }
    }

    final missing = Set<String>.from(_shape.validCells)..removeAll(grid.keys);
    if (missing.isEmpty) return;

    debugPrint('🩹 Filling ${missing.length} uncovered cell(s) with small arrows');

    while (missing.isNotEmpty) {
      final startPos = _positionFromKey(missing.first);
      final grown = _growPath(startPos, 2, missing);

      // The grown 2-cell snake only offers the one direction its travel
      // forces. If that's blocked, prefer a lone single cell instead,
      // which gets to try all 4 directions — better odds of finding one
      // that's immediately free rather than starting out blocked (still
      // fine either way: _isFullySolvable in _generateAndBuild rejects
      // the whole attempt if a chosen direction turns out to make the
      // board unsolvable, so this is just trying to avoid that retry).
      var path = grown;
      var ownCells = grown.map((p) => p.toKey()).toSet();
      var directions = _getVectorsForPath(grown);
      Direction? chosen;
      for (final vec in directions) {
        if (_isActivatable(grown.last, vec, grid, ownCells: ownCells)) {
          chosen = vec;
          break;
        }
      }

      if (chosen == null && grown.length > 1) {
        path = [startPos];
        ownCells = {startPos.toKey()};
        directions = _getVectorsForPath(path);
        for (final vec in directions) {
          if (_isActivatable(startPos, vec, grid, ownCells: ownCells)) {
            chosen = vec;
            break;
          }
        }
      }

      // Still nothing immediately free: fall back to any direction that
      // at least doesn't run into this arrow's own not-yet-registered
      // body. Being blocked by another arrow at generation time is normal
      // (that's the whole game) as long as it's eventually solvable.
      chosen ??= directions.firstWhere(
        (vec) => _isActivatable(
            path.last, vec, const <String, String>{}, ownCells: ownCells),
        orElse: () => directions.first,
      );

      final arrowId = 'arrow_${_arrows.length}';
      final segments = _createArrowSegments(path, chosen);
      _arrows[arrowId] = Arrow(
        id: arrowId,
        segments: segments,
        color: _getColorForIndex(_arrows.length),
      );

      for (final segment in segments) {
        grid[segment.position.toKey()] = arrowId;
      }
      for (final pos in path) {
        missing.remove(pos.toKey());
      }
    }
  }

  /// True if the shape's bounding box spans at least [n] cells in either
  /// dimension. Cheap to recompute per generation attempt since shapes
  /// rarely exceed a few dozen cells.
  bool _boardSpansAtLeast(int n) {
    final cells = _shape.getCells();
    if (cells.isEmpty) return false;
    var minX = cells.first.x, maxX = cells.first.x;
    var minY = cells.first.y, maxY = cells.first.y;
    for (final c in cells) {
      if (c.x < minX) minX = c.x;
      if (c.x > maxX) maxX = c.x;
      if (c.y < minY) minY = c.y;
      if (c.y > maxY) maxY = c.y;
    }
    return (maxX - minX + 1) >= n || (maxY - minY + 1) >= n;
  }

  /// Weighted arrow-length pick targeting a denser, more varied board:
  /// 20% long (8-15), 33% medium (4-7), 33% short (2-3), 14% single-cell.
  /// On boards too small to fit a long arrow, that 20% share folds evenly
  /// into the other three buckets instead.
  int _pickArrowLength(bool allowLong) {
    final r = _random.nextDouble();
    if (allowLong) {
      if (r < 0.20) return 8 + _random.nextInt(8); // 8-15
      if (r < 0.53) return 4 + _random.nextInt(4); // 4-7
      if (r < 0.86) return 2 + _random.nextInt(2); // 2-3
      return 1;
    }
    if (r < 0.40) return 4 + _random.nextInt(4); // 4-7 (absorbs long's share)
    if (r < 0.80) return 2 + _random.nextInt(2); // 2-3
    return 1;
  }

  bool _hasDeadlockPattern(Position head, Direction direction, Map<String, String> grid) {
    final oppositeDir = direction.opposite();
    var pos = head.translate(direction);
    while (pos.x >= 0 && pos.y >= 0 && pos.x < 100 && pos.y < 100) {
      if (!_shape.contains(pos)) {
        pos = pos.translate(direction);
        continue;
      }
      final occupiedBy = grid[pos.toKey()];
      if (occupiedBy != null) {
        final otherArrow = _arrows[occupiedBy];
        if (otherArrow != null && otherArrow.getDirection() == oppositeDir) {
          return true;
        }
        return false;
      }
      pos = pos.translate(direction);
    }
    return false;
  }

  Map<String, dynamic>? _findActivatableArrow(
      Set<String> remaining, Map<String, String> grid, bool allowLong) {
    for (int attempt = 0; attempt < 300; attempt++) {
      // Random starting cell
      final cells = remaining.toList();
      if (cells.isEmpty) return null;

      final startKey = cells[_random.nextInt(cells.length)];
      final startPos = _positionFromKey(startKey);

      final len = _pickArrowLength(allowLong);
      final path = _growPath(startPos, len, remaining);

      if (path.isEmpty) continue;

      final head = path.last;
      final directions = _getVectorsForPath(path);
      final ownCells = path.map((p) => p.toKey()).toSet();

      for (final vec in directions) {
        // Pass the path's own (not-yet-registered) cells too: a snake
        // whose path curls back on its own direction of travel must never
        // be approved with an exit vector that immediately re-enters its
        // own body — that arrow would be permanently unsolvable.
        final activatable = _isActivatable(head, vec, grid, ownCells: ownCells);
        if (activatable && !_hasDeadlockPattern(head, vec, grid)) {
          return {
            'cells': path,
            'direction': vec,
          };
        }
      }
    }

    return null;
  }

  List<Position> _growPath(
      Position start, int maxLen, Set<String> remaining) {
    final path = [start];
    final used = {start.toKey()};

    for (int i = 1; i < maxLen; i++) {
      final curr = path.last;
      final dirs = [
        Direction.up,
        Direction.down,
        Direction.left,
        Direction.right
      ];
      dirs.shuffle(_random);

      bool added = false;
      for (final dir in dirs) {
        final next = curr.translate(dir);
        final nextKey = next.toKey();

        if (remaining.contains(nextKey) && !used.contains(nextKey)) {
          path.add(next);
          used.add(nextKey);
          added = true;
          break;
        }
      }

      if (!added) break;
    }

    return path;
  }

  List<Direction> _getVectorsForPath(List<Position> path) {
    if (path.length == 1) {
      return [
        Direction.up,
        Direction.down,
        Direction.left,
        Direction.right,
      ]..shuffle(_random);
    }

    final tail = path[path.length - 2];
    final head = path.last;
    final dx = head.x - tail.x;
    final dy = head.y - tail.y;

    for (final dir in [Direction.up, Direction.down, Direction.left, Direction.right]) {
      if (dir.dx == dx && dir.dy == dy) {
        return [dir];
      }
    }

    return [Direction.up, Direction.down, Direction.left, Direction.right]
      ..shuffle(_random);
  }

  bool _isActivatable(
      Position head, Direction vec, Map<String, String> grid,
      {Set<String>? ownCells}) {
    var cx = head.x + vec.dx;
    var cy = head.y + vec.dy;

    while (cx >= 0 && cy >= 0 && cx < 100 && cy < 100) {
      final pos = Position(cx, cy);

      // If position is not in shape, it's void (can exit)
      if (!_shape.contains(pos)) {
        return true;
      }

      // Check if blocked by another arrow, or by one of this arrow's own
      // not-yet-registered cells (see _findActivatableArrow).
      if (grid['${pos.toKey()}'] != null || (ownCells?.contains(pos.toKey()) ?? false)) {
        return false;
      }

      cx += vec.dx;
      cy += vec.dy;
    }

    return true;
  }

  List<ArrowSegment> _createArrowSegments(
      List<Position> path, Direction direction) {
    final segments = <ArrowSegment>[];

    for (int i = 0; i < path.length - 1; i++) {
      final curr = path[i];
      final next = path[i + 1];
      final dx = next.x - curr.x;
      final dy = next.y - curr.y;

      Direction dir = Direction.up;
      if (dx == 1 && dy == 0) dir = Direction.right;
      if (dx == -1 && dy == 0) dir = Direction.left;
      if (dx == 0 && dy == 1) dir = Direction.down;
      if (dx == 0 && dy == -1) dir = Direction.up;

      segments.add(ArrowSegment(position: curr, directionToNext: dir));
    }

    // Last segment: direction is the arrow's exit direction
    segments.add(ArrowSegment(
      position: path.last,
      directionToNext: direction,
    ));

    return segments;
  }

  ArrowColor _getColorForIndex(int index) {
    const colors = [
      '#00f5a0', '#0088ff', '#ffb800', '#cc44ff',
      '#00ddff', '#aaff00', '#44ffcc', '#ff8844',
      '#4488ff', '#ffdd00', '#44ff88', '#44aaff',
    ];
    return ArrowColor.fromHex(colors[index % colors.length]);
  }

  Position _positionFromKey(String key) {
    final parts = key.split(',');
    return Position(int.parse(parts[0]), int.parse(parts[1]));
  }
}
