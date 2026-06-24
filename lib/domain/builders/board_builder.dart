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
  late int _difficulty;
  late String _difficultyStr;
  late Random _random;
  final Map<String, Arrow> _arrows = {};
  int? _calculatedMaxMoves;

  BoardBuilder({int? seed}) {
    _random = Random(seed);
    _difficultyStr = 'EASY';
  }

  static BoardBuilder create({int? seed}) => BoardBuilder(seed: seed);

  BoardBuilder setShape(BoardShape shape) {
    _shape = shape;
    return this;
  }

  BoardBuilder setDifficulty(int difficulty, {String? difficultyStr}) {
    _difficulty = difficulty;
    if (difficultyStr != null) {
      _difficultyStr = difficultyStr;
    }
    return this;
  }

  int? getCalculatedMaxMoves() => _calculatedMaxMoves;

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

    // DEBUG: Print grid contents and arrow positions BEFORE building graph
    debugPrint('=== GRID CONTENTS ===');
    grid.forEach((key, arrowId) => debugPrint('  cell $key → arrow $arrowId'));
    debugPrint('=== ARROWS HEAD POSITIONS ===');
    _arrows.values.forEach((a) {
      final head = a.getHead();
      final pos = head.position;
      final dir = a.getDirection();
      debugPrint(
          '  arrow ${a.id} head=${pos.toKey()} dir=(${dir.dx},${dir.dy})');
    });

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
    _arrows.clear();

    // Try up to 1000 times to generate a VALID puzzle (not all arrows free)
    for (int attempt = 0; attempt < 1000; attempt++) {
      _arrows.clear();
      final generated = _generateArrows();
      if (!generated) continue;

      // Build board and graph to check if it's a valid puzzle
      final board = _buildWithExistingArrows();
      final activatable = board.graph.getActivatable();
      final totalArrows = _arrows.length;

      debugPrint(
          '🧪 Generation attempt $attempt: $totalArrows arrows, ${activatable.length} activatable');

      // Valid puzzle = NOT all arrows are free AND have at least 4 arrows
      if (activatable.length < totalArrows && totalArrows > 3) {
        debugPrint('✅ Valid puzzle found!');
        // Calculate maxMoves
        final margin = _difficultyStr == 'HARD'
            ? 0.15
            : _difficultyStr == 'MEDIUM'
                ? 0.25
                : 0.35;
        _calculatedMaxMoves = (totalArrows * (1 + margin)).ceil();
        return board;
      }

      debugPrint(
          '❌ Invalid: all arrows free or too few arrows, retrying...');
    }

    // Fallback: use the last generated board even if not ideal
    debugPrint('⚠️  Max attempts reached, using last generated board');
    final board = _buildWithExistingArrows();
    final totalArrows = _arrows.length;
    final margin = _difficultyStr == 'HARD'
        ? 0.15
        : _difficultyStr == 'MEDIUM'
            ? 0.25
            : 0.35;
    _calculatedMaxMoves = (totalArrows * (1 + margin)).ceil();
    return board;
  }

  bool _generateArrows() {
    final remaining = Set<String>.from(_shape.validCells);
    final grid = <String, String>{};
    int failStreak = 0;
    int arrowIndex = 0;

    final maxLen = _difficulty == 3 ? 7 : _difficulty == 2 ? 5 : 4;

    while (remaining.isNotEmpty) {
      if (failStreak > 100) {
        return false;
      }

      final arrowData = _findActivatableArrow(remaining, grid, maxLen);
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

  Map<String, dynamic>? _findActivatableArrow(
      Set<String> remaining, Map<String, String> grid, int maxLen) {
    for (int attempt = 0; attempt < 300; attempt++) {
      // Random starting cell
      final cells = remaining.toList();
      if (cells.isEmpty) return null;

      final startKey = cells[_random.nextInt(cells.length)];
      final startPos = _positionFromKey(startKey);

      final len = 1 + _random.nextInt(maxLen);
      final path = _growPath(startPos, len, remaining);

      if (path.isEmpty) continue;

      final head = path.last;
      final directions = _getVectorsForPath(path);

      for (final vec in directions) {
        final activatable = _isActivatable(head, vec, grid);
        if (activatable) {
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
    debugPrint(
        'growPath: remaining=${remaining.length} start=${start.toKey()}');

    // Debug: Check remaining keys format
    if (remaining.isNotEmpty) {
      debugPrint('  remaining keys sample: ${remaining.take(5).toList()}');
      final neighborKey = Position(1, 0).toKey();
      debugPrint('  neighbor key format: "$neighborKey"');
    }

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
        final inRemaining = remaining.contains(nextKey);
        final notUsed = !used.contains(nextKey);

        debugPrint(
            '  trying dir (${dir.dx},${dir.dy}) → next=$nextKey inRemaining=$inRemaining notUsed=$notUsed');

        if (inRemaining && notUsed) {
          debugPrint('    ✅ Added to path');
          path.add(next);
          used.add(nextKey);
          added = true;
          break;
        }
      }

      if (!added) {
        debugPrint('  ❌ No valid direction found, path length=${path.length}');
        break;
      }
    }

    debugPrint(
        'growPath result: path of length ${path.length}');
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
      Position head, Direction vec, Map<String, String> grid) {
    var cx = head.x + vec.dx;
    var cy = head.y + vec.dy;

    while (cx >= 0 && cy >= 0 && cx < 100 && cy < 100) {
      final pos = Position(cx, cy);

      // If position is not in shape, it's void (can exit)
      if (!_shape.contains(pos)) {
        return true;
      }

      // Check if blocked by another arrow
      if (grid['${pos.toKey()}'] != null) {
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
      '#00f5a0', '#0088ff', '#ff3366', '#ffb800',
      '#cc44ff', '#ff6600', '#00ddff', '#ff44aa',
      '#aaff00', '#ff4444', '#44ffcc', '#ff8844',
      '#4488ff', '#ffdd00', '#ff44ff', '#44ff88',
      '#ff6644', '#44aaff',
    ];
    return ArrowColor.fromHex(colors[index % colors.length]);
  }

  Position _positionFromKey(String key) {
    final parts = key.split(',');
    return Position(int.parse(parts[0]), int.parse(parts[1]));
  }
}
