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

  /// When true, arrows grow/scan across the 6 hex neighbors
  /// (Direction.hexAll) instead of the normal 4-planar/6-extruded choice.
  /// Meant to pair with a [BoardShape.hexagon] or [BoardShape.hexagonRing].
  final bool useHexDirections;

  BoardBuilder({int? seed, this.useHexDirections = false}) {
    _random = Random(seed);
    _difficultyStr = 'EASY';
  }

  static BoardBuilder create({int? seed, bool useHexDirections = false}) =>
      BoardBuilder(seed: seed, useHexDirections: useHexDirections);

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
    _cachedBounds = null;
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
      var fillerIds = _fillUncoveredCells();

      final totalArrows = _arrows.length;
      if (totalArrows <= 3) continue;

      // Probe on a throwaway graph: _countUnsolvable drains it via
      // removeArrow, so the board actually returned below needs its own
      // fresh one.
      var probe = _buildWithExistingArrows();
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
      var stuck = _findUnsolvableIds(probe).length;

      // A blocking cycle always involves at least one filler arrow: the
      // main loop's arrows are each activatable w.r.t. everything placed
      // before them, so firing them in reverse placement order always
      // clears a filler-less board. That means re-rolling just the fillers
      // (directions are shuffled per roll) can fix a stuck board far more
      // cheaply than discarding the whole attempt — which matters on
      // shapes like level 15's ring, whose narrow corridors leave many
      // leftover cells and made every attempt likely to jam.
      for (int refill = 0; stuck > 0 && refill < 6; refill++) {
        for (final id in fillerIds) {
          _arrows.remove(id);
        }
        fillerIds = _fillUncoveredCells();
        probe = _buildWithExistingArrows();
        stuck = _findUnsolvableIds(probe).length;
      }

      debugPrint(
          '🧪 Generation attempt $attempt: ${_arrows.length} arrows, ${activatable.length} activatable, $stuck stuck');

      if (stuck == 0) {
        debugPrint('✅ Valid puzzle found!');
        // _arrows.length, not totalArrows: refills can change the filler
        // count slightly, and maxMoves must match what's actually shipped.
        _calculatedMaxMoves =
            calculateMaxMoves(_arrows.length, _difficultyStr);
        return _buildWithExistingArrows();
      }

      if (stuck < bestStuckCount) {
        bestStuckCount = stuck;
        bestArrows = Map.of(_arrows);
      }
    }

    // Every attempt left something unsolvable — take the closest call we
    // saw (fewest permanently-stuck arrows) and REPAIR it rather than
    // shipping it as-is. Deleting exactly the stuck set from a jammed
    // board is guaranteed to leave a fully solvable one: the playthrough
    // simulation already removed every other arrow, so with the jam gone
    // the same removal order clears the board. A few repair rounds first
    // try to re-fill the freed cells (so they don't end up arrow-less);
    // if the refill re-jams every time, the final round deletes the stuck
    // set without refilling — a couple of empty cells is a cosmetic
    // blemish, an unwinnable level is a broken game.
    debugPrint(
        '⚠️  Max attempts reached, repairing best candidate ($bestStuckCount stuck arrow(s))');
    if (bestArrows != null) {
      _arrows
        ..clear()
        ..addAll(bestArrows);
    }

    var stuckIds = _findUnsolvableIds(_buildWithExistingArrows());
    for (int repair = 0; stuckIds.isNotEmpty && repair < 5; repair++) {
      for (final id in stuckIds) {
        _arrows.remove(id);
      }
      _fillUncoveredCells();
      stuckIds = _findUnsolvableIds(_buildWithExistingArrows());
    }
    if (stuckIds.isNotEmpty) {
      debugPrint(
          '🩹 Repair: dropping ${stuckIds.length} permanently stuck arrow(s), leaving their cells uncovered');
      for (final id in stuckIds) {
        _arrows.remove(id);
      }
    }

    final board = _buildWithExistingArrows();
    _calculatedMaxMoves = calculateMaxMoves(_arrows.length, _difficultyStr);
    return board;
  }

  /// The ids of arrows with no valid removal order, simulated by
  /// repeatedly removing every currently activatable arrow — exactly
  /// like a player clearing the board — until nothing more can be
  /// removed. Mutates [board]'s graph in place, so callers must only use
  /// this on a throwaway probe board, never the one that's actually
  /// returned.
  Set<String> _findUnsolvableIds(Board board) {
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

    return remaining;
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
  ///
  /// Returns the ids of the arrows it added, so _generateAndBuild can strip
  /// and re-roll just the fillers when the solvability probe finds a
  /// blocking cycle (which always involves fillers — see there).
  List<String> _fillUncoveredCells() {
    final addedIds = <String>[];
    final grid = <String, String>{};
    for (final arrow in _arrows.values) {
      for (final segment in arrow.segments) {
        grid[segment.position.toKey()] = arrow.id;
      }
    }

    final missing = Set<String>.from(_shape.validCells)..removeAll(grid.keys);
    if (missing.isEmpty) return addedIds;

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
      // Same acceptance rule as the main generation loop
      // (_findActivatableArrow): free to fire AND no face-to-face pattern.
      // Fillers skipping _hasDeadlockPattern was exactly what let arrows
      // spawn staring at each other across the hollow center of ring
      // boards (level 15) — the solvability probe can't catch those, since
      // both arrows can still technically exit into the hole.
      var path = grown;
      var ownCells = grown.map((p) => p.toKey()).toSet();
      var directions = _getVectorsForPath(grown);
      Direction? chosen;
      for (final vec in directions) {
        if (_isActivatable(grown.last, vec, grid, ownCells: ownCells) &&
            !_hasDeadlockPattern(grown.last, vec, grid)) {
          chosen = vec;
          break;
        }
      }

      if (chosen == null && grown.length > 1) {
        path = [startPos];
        ownCells = {startPos.toKey()};
        directions = _getVectorsForPath(path);
        for (final vec in directions) {
          if (_isActivatable(startPos, vec, grid, ownCells: ownCells) &&
              !_hasDeadlockPattern(startPos, vec, grid)) {
            chosen = vec;
            break;
          }
        }
      }

      // Still nothing immediately free: fall back to any direction that
      // doesn't create a face-to-face pattern and doesn't run into this
      // arrow's own not-yet-registered body. Being blocked by another
      // arrow at generation time is normal (that's the whole game) as
      // long as it's eventually solvable.
      chosen ??= directions.firstWhere(
        (vec) =>
            _isActivatable(path.last, vec, const <String, String>{},
                ownCells: ownCells) &&
            !_hasDeadlockPattern(path.last, vec, grid),
        orElse: () => directions.firstWhere(
          (vec) => !_hasDeadlockPattern(path.last, vec, grid),
          orElse: () => directions.first,
        ),
      );

      final arrowId = 'arrow_${_arrows.length}';
      final segments = _createArrowSegments(path, chosen);
      _arrows[arrowId] = Arrow(
        id: arrowId,
        segments: segments,
        color: _getColorForIndex(_arrows.length),
      );
      addedIds.add(arrowId);

      for (final segment in segments) {
        grid[segment.position.toKey()] = arrowId;
      }
      for (final pos in path) {
        missing.remove(pos.toKey());
      }
    }
    return addedIds;
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
    while (pos.x >= 0 &&
        pos.y >= 0 &&
        pos.z >= 0 &&
        pos.x < 100 &&
        pos.y < 100 &&
        pos.z < 100) {
      // Holes (cells outside the shape, e.g. the hollow center of a ring
      // board) are deliberately scanned across, not treated as an exit:
      // an arrow on the far side of the hole is still on the same board
      // line and the two can stare each other down across the gap.
      if (!_shape.contains(pos)) {
        pos = pos.translate(direction);
        continue;
      }
      final occupiedBy = grid[pos.toKey()];
      if (occupiedBy != null) {
        // Only a HEAD pointing straight back is a stare-down. Hitting
        // another arrow's body is ordinary, resolvable blocking (the body
        // clears once that arrow fires) even if its head, somewhere else
        // on this line, happens to point the opposite way — vetoing those
        // too starved narrow ring corridors of legal directions and forced
        // the filler into blocking cycles (unsolvable level 15 boards).
        final otherArrow = _arrows[occupiedBy];
        if (otherArrow != null &&
            otherArrow.getDirection() == oppositeDir &&
            otherArrow.getHead().position == pos) {
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
      final dirs = List.of(_availableDirections());
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
      return List.of(_availableDirections())..shuffle(_random);
    }

    final travel = _directionBetween(path[path.length - 2], path.last);
    if (travel != null) return [travel];

    return List.of(_availableDirections())..shuffle(_random);
  }

  /// The unit direction from [from] to its adjacent [to], across any of
  /// the 6 connections; null when the cells aren't adjacent.
  Direction? _directionBetween(Position from, Position to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final dz = to.z - from.z;
    for (final dir in _availableDirections()) {
      if (dir.dx == dx && dir.dy == dy && dir.dz == dz) return dir;
    }
    return null;
  }

  bool _isActivatable(
      Position head, Direction vec, Map<String, String> grid,
      {Set<String>? ownCells}) {
    var pos = head.translate(vec);

    // Same exit rule as BoardGraph.build and the in-game tap check
    // (hasVoidReentry): interior holes are NOT exits — the ray tunnels
    // across them, and any occupied cell on the far side blocks. The ray
    // only truly leaves the board past the shape's bounding box (all
    // three axes: a Z-bound matters as much as X/Y on extruded boards).
    final bounds = _shapeBounds();

    while (pos.x >= 0 &&
        pos.y >= 0 &&
        pos.z >= 0 &&
        pos.x <= bounds.maxX &&
        pos.y <= bounds.maxY &&
        pos.z <= bounds.maxZ) {
      if (_shape.contains(pos)) {
        // Blocked by another arrow, or by one of this arrow's own
        // not-yet-registered cells (see _findActivatableArrow).
        if (grid[pos.toKey()] != null ||
            (ownCells?.contains(pos.toKey()) ?? false)) {
          return false;
        }
      }

      pos = pos.translate(vec);
    }

    return true;
  }

  ({int maxX, int maxY, int maxZ})? _cachedBounds;

  ({int maxX, int maxY, int maxZ}) _shapeBounds() {
    final cached = _cachedBounds;
    if (cached != null) return cached;
    var maxX = 0, maxY = 0, maxZ = 0;
    for (final c in _shape.getCells()) {
      if (c.x > maxX) maxX = c.x;
      if (c.y > maxY) maxY = c.y;
      if (c.z > maxZ) maxZ = c.z;
    }
    return _cachedBounds = (maxX: maxX, maxY: maxY, maxZ: maxZ);
  }

  /// The direction set this shape's cells connect through: the 6 hex
  /// neighbors on hex boards, 4 planar neighbors on flat
  /// square boards, or 6 (adding forward/back along Z) on extruded ones.
  /// Gated on actual depth so flat boards never generate arrows pointing
  /// into Z — those would exit instantly and trivialize the puzzle.
  List<Direction> _availableDirections() {
    if (useHexDirections) return Direction.hexAll;
    return _shapeBounds().maxZ > 0 ? Direction.all : Direction.planar;
  }

  List<ArrowSegment> _createArrowSegments(
      List<Position> path, Direction direction) {
    final segments = <ArrowSegment>[];

    for (int i = 0; i < path.length - 1; i++) {
      final curr = path[i];
      final next = path[i + 1];
      // Paths are grown one adjacent cell at a time, so this is always
      // one of the 6 unit directions.
      final dir = _directionBetween(curr, next) ?? Direction.up;
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

  Position _positionFromKey(String key) => Position.fromKey(key);
}
