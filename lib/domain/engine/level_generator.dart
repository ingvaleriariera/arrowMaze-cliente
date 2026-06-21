import 'dart:math';

import '../entities/arrow.dart';
import '../entities/arrow_segment.dart';
import '../entities/board.dart';
import '../value_objects/arrow_color.dart';
import '../value_objects/board_shape.dart';
import '../value_objects/direction.dart';
import '../value_objects/position.dart';

/// Resultado interno de buscar una flecha activable: celdas de cola→cabeza
/// y la dirección de salida (igual a la del último tramo del camino).
class _ArrowPlacement {
  final List<Position> cells;
  final Direction direction;

  _ArrowPlacement(this.cells, this.direction);
}

/// Genera flechas que llenan la mayoría del tablero (construcción backward,
/// igual que generateLevel() en docs/arrow_maze_v5.html): cada flecha se
/// agrega solo si su camino de salida está libre en ese momento, así el
/// orden inverso de colocación es una secuencia de remoción válida.
class LevelGenerator {
  static const List<String> _palette = [
    '#00F5A0', '#0088FF', '#FF3366', '#FFB800', '#CC44FF', '#FF6600',
    '#00DDFF', '#FF44AA', '#AAFF00', '#FF4444', '#44FFCC', '#FF8844',
    '#4488FF', '#FFDD00', '#FF44FF', '#44FF88', '#FF6644', '#44AAFF',
  ];

  final Random _random;

  LevelGenerator([Random? random]) : _random = random ?? Random();

  List<Direction> get _allDirections =>
      [Direction.up(), Direction.down(), Direction.left(), Direction.right()];

  List<Arrow> generate(
    BoardShape shape, {
    String difficulty = 'MEDIUM',
    int maxRetries = 300,
  }) {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      final arrows = _tryGenerate(shape, difficulty);
      if (arrows != null) return arrows;
    }
    return _tryGenerate(shape, difficulty) ?? const [];
  }

  int _maxSegmentLength(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'HARD':
        return 7;
      case 'EASY':
        return 4;
      default:
        return 5;
    }
  }

  List<Arrow>? _tryGenerate(BoardShape shape, String difficulty) {
    final remaining = Set<String>.from(shape.validCells);
    final occupied = <String, String>{};
    final arrows = <Arrow>[];
    final maxLen = _maxSegmentLength(difficulty);
    final headPositions = <String, Direction>{}; // Mapa de cabezas para detectar face-to-face
    var failStreak = 0;
    var colorIdx = 0;

    while (remaining.isNotEmpty) {
      if (failStreak > 100) return null;
      final placement = _findActivatableArrow(remaining, occupied, shape, maxLen, headPositions);
      if (placement == null) {
        failStreak++;
        continue;
      }
      failStreak = 0;

      final arrowId = 'arrow_${arrows.length}';
      final color = ArrowColor.fromHex(_palette[colorIdx++ % _palette.length]);

      // Las celdas llegan cola→cabeza; el dominio guarda los segmentos
      // cabeza→cola (Arrow.getHead() == segments.first), igual que el
      // resto del motor ya asume.
      final headFirstCells = placement.cells.reversed.toList();
      final segments = headFirstCells
          .map((c) => ArrowSegment(c, placement.direction))
          .toList();
      arrows.add(Arrow(arrowId, segments, color));

      for (final cell in placement.cells) {
        final key = cell.toKey();
        remaining.remove(key);
        occupied[key] = arrowId;
      }

      // Registrar la cabeza de esta flecha para detectar face-to-face futuro
      final head = placement.cells.last;
      headPositions[head.toKey()] = placement.direction;
    }

    // Validación post-generación: simular greedy resolver
    if (!_isCompletelySolvable(arrows, shape)) return null;
    return arrows;
  }

  _ArrowPlacement? _findActivatableArrow(
    Set<String> remaining,
    Map<String, String> occupied,
    BoardShape shape,
    int maxLen,
    Map<String, Direction> headPositions,
  ) {
    final cellList = remaining.map(_parseKey).toList();
    for (var attempt = 0; attempt < 300; attempt++) {
      final start = cellList[_random.nextInt(cellList.length)];
      final len = 1 + _random.nextInt(maxLen);
      final cells = _growPath(start, len, remaining);
      if (cells == null || cells.isEmpty) continue;

      final head = cells.last;
      final candidateDirections = cells.length == 1
          ? (_allDirections..shuffle(_random))
          : [_directionBetween(cells[cells.length - 2], head)];

      for (final direction in candidateDirections) {
        if (_isExitPathClear(head, direction, shape, occupied)) {
          // Verificar face-to-face: escanear en dirección opuesta desde la cabeza
          if (!_isFaceToFace(head, direction, headPositions)) {
            return _ArrowPlacement(cells, direction);
          }
        }
      }
    }
    return null;
  }

  /// Crece un camino tipo "serpiente" desde [start], cambiando de dirección
  /// libremente mientras haya celdas vecinas disponibles en [remaining].
  List<Position>? _growPath(Position start, int length, Set<String> remaining) {
    if (!remaining.contains(start.toKey())) return null;
    final path = [start];
    final used = {start.toKey()};
    for (var i = 1; i < length; i++) {
      final current = path.last;
      final dirs = _allDirections..shuffle(_random);
      Position? next;
      for (final d in dirs) {
        final candidate = current.translate(d);
        final key = candidate.toKey();
        if (remaining.contains(key) && !used.contains(key)) {
          next = candidate;
          break;
        }
      }
      if (next == null) break;
      path.add(next);
      used.add(next.toKey());
    }
    return path;
  }

  bool _isExitPathClear(
    Position head,
    Direction direction,
    BoardShape shape,
    Map<String, String> occupied,
  ) {
    var current = head;
    while (!shape.isExitFrom(current, direction)) {
      current = current.translate(direction);
      if (occupied.containsKey(current.toKey())) return false;
    }
    return true;
  }

  /// Detecta si hay una flecha frente a esta (face-to-face) que causaría deadlock.
  /// Escanea en dirección opuesta desde [head]. Si se encuentra una flecha cuya
  /// cabeza está exactamente en esa celda Y apunta hacia [head], hay face-to-face.
  bool _isFaceToFace(
    Position head,
    Direction direction,
    Map<String, Direction> headPositions,
  ) {
    final opposite = _oppositeDirection(direction);
    var current = head.translate(opposite);
    while (true) {
      final key = current.toKey();
      // Si hay una flecha con cabeza exactamente aquí
      if (headPositions.containsKey(key)) {
        final headDir = headPositions[key]!;
        // Si apunta hacia nuestra cabeza (es decir, en la misma dirección que la nuestra)
        if (_directionsEqual(headDir, direction)) {
          return true; // Face-to-face detectado
        }
      }
      // Continuar escaneando si la celda está vacía
      // (no necesitamos chequear occupied aquí porque headPositions solo tiene cabezas)
      current = current.translate(opposite);
      // Limitar la búsqueda para evitar loops infinitos: máximo 20 celdas
      if (current.x < -20 || current.x > 20 || current.y < -20 || current.y > 20) {
        break;
      }
    }
    return false;
  }

  Direction _oppositeDirection(Direction dir) {
    if (dir.dx == 1) return Direction.left();
    if (dir.dx == -1) return Direction.right();
    if (dir.dy == 1) return Direction.up();
    return Direction.down();
  }

  bool _directionsEqual(Direction a, Direction b) =>
      a.dx == b.dx && a.dy == b.dy;

  Direction _directionBetween(Position from, Position to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    if (dx == 1) return Direction.right();
    if (dx == -1) return Direction.left();
    if (dy == 1) return Direction.down();
    return Direction.up();
  }

  Position _parseKey(String key) {
    final parts = key.split(',');
    return Position(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Verifica que el nivel es completamente resoluble con estrategia greedy.
  /// Simula el juego activando siempre la primera flecha activable encontrada.
  /// Si en algún punto no hay flechas activables pero quedan flechas, es deadlock.
  bool _isCompletelySolvable(List<Arrow> arrows, BoardShape shape) {
    if (arrows.isEmpty) return true;

    // Construir tablero temporal
    final arrowMap = <String, Arrow>{};
    final grid = <String, String>{};
    for (final arrow in arrows) {
      arrowMap[arrow.getId()] = arrow;
      for (final segment in arrow.getSegments()) {
        grid[segment.getPosition().toKey()] = arrow.getId();
      }
    }

    // Simular: mientras haya flechas, activar la primera activable
    var iterations = 0;
    final maxIterations = arrows.length * 10; // Prevenir loops infinitos

    while (arrowMap.isNotEmpty && iterations < maxIterations) {
      iterations++;

      // Reconstruir el grafo de dependencias para la situación actual
      final currentBoard = _buildBoardForSolver(arrowMap, grid, shape);
      final activatable = currentBoard.getActivatableArrows();

      if (activatable.isEmpty) {
        // Deadlock: no hay flechas activables pero quedan flechas
        return false;
      }

      // Activar la primera flecha activable (greedy)
      final nextArrowId = activatable.first;
      _removeArrowForSolver(nextArrowId, arrowMap, grid);
    }

    // Si llegamos aquí, todas las flechas fueron removidas: solvable
    return arrowMap.isEmpty;
  }

  /// Construye un tablero temporal a partir de arrowMap y grid para verificación.
  Board _buildBoardForSolver(Map<String, Arrow> arrowMap, Map<String, String> gridMap, BoardShape shape) {
    final board = Board(shape, arrowMap);
    return board;
  }

  /// Remueve una flecha del mapa y grid.
  void _removeArrowForSolver(String arrowId, Map<String, Arrow> arrowMap, Map<String, String> gridMap) {
    final arrow = arrowMap.remove(arrowId);
    if (arrow != null) {
      for (final segment in arrow.getSegments()) {
        gridMap.remove(segment.getPosition().toKey());
      }
    }
  }
}
