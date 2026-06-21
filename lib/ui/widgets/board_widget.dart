import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/board.dart';
import '../../domain/value_objects/direction.dart';
import '../../domain/value_objects/position.dart';

// ─────────────────────────────────────────────────────────────
// MODELOS DE ANIMACIÓN
// ─────────────────────────────────────────────────────────────

/// Datos de una flecha en animación de salida (efecto gusano).
/// Reimplementación Flutter del getAnimatedCells() del HTML.
class ExitAnimation {
  /// Segmentos originales de la flecha (de cola a cabeza).
  final List<Position> cells;
  final Direction direction;
  final Color color;
  final String arrowId;

  /// 0.0 → 1.0 controlado por AnimationController externo.
  double progress;

  ExitAnimation({
    required this.cells,
    required this.direction,
    required this.color,
    required this.arrowId,
    this.progress = 0.0,
  });
}

/// Flash visual cuando se intenta activar una flecha bloqueada.
class FlashState {
  final String arrowId;
  final double progress; // 0.0 → 1.0 (fade de rojo)

  const FlashState({required this.arrowId, required this.progress});
}

// ─────────────────────────────────────────────────────────────
// PAINTER
// ─────────────────────────────────────────────────────────────

/// CustomPainter principal del tablero.
/// Dibuja: puntos en celdas vacías, flechas neón, flechas en salida (gusano).
/// Fiel al estilo del HTML: fondo #0d0d18, puntos #252535, sin bordes de celda.
class BoardPainter extends CustomPainter {
  final Board board;
  final List<ExitAnimation> exitAnimations;
  final FlashState? flash;

  /// Tamaño de cada celda en lógica de grilla (calculado externamente).
  final double cellSize;

  /// Número de columnas y filas para calcular el offset de centrado.
  final int cols;
  final int rows;

  BoardPainter({
    required this.board,
    required this.exitAnimations,
    required this.cellSize,
    required this.cols,
    required this.rows,
    this.flash,
  });

  // ── Utilidades de coordenadas ──────────────────────────────

  /// Centro en píxeles de una celda lógica (x, y).
  Offset _center(double gx, double gy) {
    return Offset(gx * cellSize + cellSize / 2, gy * cellSize + cellSize / 2);
  }

  Offset _centerP(Position p) => _center(p.x.toDouble(), p.y.toDouble());

  // ── easeOut cúbico (igual al HTML) ────────────────────────
  double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

  // ─────────────────────────────────────────────────────────
  // LÓGICA DE ANIMACIÓN — getAnimatedCells en Dart
  // Reimplementación del JS: la cabeza viaja hacia el borde,
  // los segmentos siguen interpolados → efecto gusano.
  // ─────────────────────────────────────────────────────────
  List<Offset> _getAnimatedOffsets(ExitAnimation anim) {
    final cells = anim.cells; // de cola a cabeza
    final n = cells.length;
    final head = cells[n - 1];
    final vec = anim.direction;
    final shape = board.getShape();

    // Distancia hasta la salida (borde o celda void)
    int edgeDist = 0;
    var cx = head.x + vec.dx;
    var cy = head.y + vec.dy;
    while (cx >= 0 && cy >= 0 && cx < cols && cy < rows) {
      final pos = Position(cx, cy);
      if (!shape.contains(pos)) break; // celda void = salida
      edgeDist++;
      cx += vec.dx;
      cy += vec.dy;
    }
    edgeDist++; // +1 para salir del borde

    final D = (edgeDist + n).toDouble();
    final headTravel = _easeOut(anim.progress) * D;

    // Calcula posición interpolada del segmento i a lo largo del path
    return List.generate(n, (i) => _getPosOnPath(cells, vec, i + headTravel));
  }

  /// Interpola la posición s a lo largo del path de celdas + extensión por el borde.
  Offset _getPosOnPath(List<Position> cells, Direction vec, double s) {
    final n = cells.length;
    if (s <= 0) return _centerP(cells[0]);
    if (s >= n - 1) {
      // Más allá de la cabeza → continúa en la dirección vec
      final tail = cells[n - 1];
      final extra = s - (n - 1);
      return _center(
        tail.x.toDouble() + vec.dx * extra,
        tail.y.toDouble() + vec.dy * extra,
      );
    }
    final i = s.floor();
    final f = s - i;
    final a = cells[i];
    final b = cells[i + 1];
    return _center(
      a.x + (b.x - a.x) * f,
      a.y + (b.y - a.y) * f,
    );
  }

  // ─────────────────────────────────────────────────────────
  // DIBUJO — cabeza de flecha (triángulo)
  // ─────────────────────────────────────────────────────────
  void _drawArrowHead(
    Canvas canvas,
    Offset headPos,
    Direction vec,
    Color color,
  ) {
    final hw = cellSize * 0.48;
    final hl = cellSize * 0.38;

    // Tip del triángulo
    final tip = Offset(
      headPos.dx + vec.dx * hl * 0.65,
      headPos.dy + vec.dy * hl * 0.65,
    );
    // Base del triángulo
    final base = Offset(
      headPos.dx - vec.dx * hl * 0.40,
      headPos.dy - vec.dy * hl * 0.40,
    );
    // Perpendicular al vector
    final px = -vec.dy.toDouble();
    final py = vec.dx.toDouble();

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + px * hw / 2, base.dy + py * hw / 2)
      ..lineTo(base.dx - px * hw / 2, base.dy - py * hw / 2)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  // ─────────────────────────────────────────────────────────
  // DIBUJO — cuerpo de flecha (línea con esquinas redondeadas + cabeza)
  // ─────────────────────────────────────────────────────────
  void _drawArrow(
    Canvas canvas,
    List<Offset> offsets,
    Direction direction,
    Color color,
    double alpha,
  ) {
    if (offsets.isEmpty) return;

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = cellSize * 0.17
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, alpha == 1.0 ? 6 : 4);

    if (offsets.length == 1) {
      // Flecha de un solo segmento: línea corta + cabeza
      final c = offsets.first;
      final tail = Offset(
        c.dx - direction.dx * cellSize * 0.28,
        c.dy - direction.dy * cellSize * 0.28,
      );
      canvas.drawLine(tail, c, paint);
      _drawArrowHead(canvas, c, direction, color.withValues(alpha: alpha));
      return;
    }

    // Flecha multi-segmento con esquinas redondeadas
    final r = cellSize * 0.38;
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);

    for (var i = 1; i < offsets.length - 1; i++) {
      final prev = offsets[i - 1];
      final curr = offsets[i];
      final next = offsets[i + 1];

      final idx = curr.dx - prev.dx;
      final idy = curr.dy - prev.dy;
      final il = math.sqrt(idx * idx + idy * idy).clamp(0.001, double.infinity);

      final odx = next.dx - curr.dx;
      final ody = next.dy - curr.dy;
      final ol = math.sqrt(odx * odx + ody * ody).clamp(0.001, double.infinity);

      final cr = math.min(r, math.min(il / 2, ol / 2));

      path.lineTo(curr.dx - idx / il * cr, curr.dy - idy / il * cr);
      path.quadraticBezierTo(
        curr.dx,
        curr.dy,
        curr.dx + odx / ol * cr,
        curr.dy + ody / ol * cr,
      );
    }
    path.lineTo(offsets.last.dx, offsets.last.dy);

    canvas.drawPath(path, paint);
    _drawArrowHead(canvas, offsets.last, direction, color.withValues(alpha: alpha));
  }

  // ─────────────────────────────────────────────────────────
  // PAINT — método principal del CustomPainter
  // ─────────────────────────────────────────────────────────
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo (opcional — el Scaffold ya pinta #0d0d18)
    // No lo dibujamos aquí para respetar el widget padre.

    // 2. Puntos en celdas válidas vacías (#252535, radio = cellSize × 0.07)
    final dotPaint = Paint()
      ..color = const Color(0xFF252535)
      ..style = PaintingStyle.fill;
    final dotRadius = math.max(2.0, cellSize * 0.07);

    for (final key in board.getShape().validCells) {
      final parts = key.split(',');
      final gx = double.parse(parts[0]);
      final gy = double.parse(parts[1]);
      final c = _center(gx, gy);
      canvas.drawCircle(c, dotRadius, dotPaint);
    }

    // 3. Flechas activas
    final activatable = board.getActivatableArrows().toSet();
    final arrows = board.getArrows();

    for (final arrow in arrows.values) {
      final isFree = activatable.contains(arrow.getId());
      final alpha = isFree ? 1.0 : 0.28;

      // Detectar flash (flecha bloqueada tocada)
      Color arrowColor = _hexToColor(arrow.getColor().getValue());
      if (flash != null && flash!.arrowId == arrow.getId()) {
        final t = flash!.progress;
        arrowColor = Color.lerp(arrowColor, const Color(0xFFFF3366), t)!;
      }

      // getSegments() está cabeza→cola (segments.first == head); _drawArrow
      // espera cola→cabeza (offsets.last == head) para dibujar la punta
      // en el extremo correcto, igual que cells en el HTML.
      final offsets = arrow
          .getSegments()
          .reversed
          .map((s) => _centerP(s.getPosition()))
          .toList();
      _drawArrow(canvas, offsets, arrow.getDirection(), arrowColor, alpha);
    }

    // 4. Flechas en animación de salida (efecto gusano)
    for (final anim in exitAnimations) {
      final animOffsets = _getAnimatedOffsets(anim);
      // Alpha: 1.0 hasta progress=0.75, luego fade lineal hasta 0
      final alpha = anim.progress > 0.75
          ? 1.0 - (anim.progress - 0.75) / 0.25
          : 1.0;
      _drawArrow(canvas, animOffsets, anim.direction, anim.color, alpha);
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;

  // ─── Utilidad ──────────────────────────────────────────────
  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET
// ─────────────────────────────────────────────────────────────

/// Widget del tablero de juego.
/// Gestiona las AnimationController para las exit animations.
/// Detecta taps con GestureDetector y convierte coordenadas → arrowId.
class BoardWidget extends StatefulWidget {
  final Board board;
  final void Function(String arrowId) onArrowTapped;
  final bool interactive;

  const BoardWidget({
    super.key,
    required this.board,
    required this.onArrowTapped,
    this.interactive = true,
  });

  @override
  State<BoardWidget> createState() => BoardWidgetState();
}

class BoardWidgetState extends State<BoardWidget> with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<ExitAnimation> _exitAnims = [];
  FlashState? _flash;
  AnimationController? _flashController;

  /// Dispara la animación de salida para una flecha.
  /// Llamar desde GameScreen cuando un MoveResult.success llega.
  void triggerExitAnimation(ExitAnimation anim) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controllers.add(controller);
    _exitAnims.add(anim);

    controller.addListener(() {
      if (!mounted) return;
      setState(() {
        anim.progress = controller.value;
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() {
          _exitAnims.remove(anim);
          _controllers.remove(controller);
        });
        controller.dispose();
      }
    });

    controller.forward();
  }

  /// Muestra flash rojo en la flecha bloqueada durante 500ms.
  void triggerFailFlash(String arrowId) {
    _flashController?.dispose();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flashController!.addListener(() {
      if (!mounted) return;
      setState(() {
        _flash = FlashState(arrowId: arrowId, progress: _flashController!.value);
      });
    });
    _flashController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() => _flash = null);
      }
    });
    setState(() => _flash = FlashState(arrowId: arrowId, progress: 0.0));
    _flashController!.forward();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _flashController?.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPos, double cellSize) {
    if (!widget.interactive) return;
    final gx = (localPos.dx / cellSize).floor();
    final gy = (localPos.dy / cellSize).floor();
    final pos = Position(gx, gy);
    final arrow = widget.board.getArrowAt(pos);
    if (arrow != null) {
      widget.onArrowTapped(arrow.getId());
    }
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.board.getShape();
    final cells = shape.getCells();

    if (cells.isEmpty) return const SizedBox.shrink();

    // Bounding box del tablero
    int maxX = 0, maxY = 0;
    for (final p in cells) {
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    final logicalCols = maxX + 1;
    final logicalRows = maxY + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = math.min(
          constraints.maxWidth / logicalCols,
          constraints.maxHeight / logicalRows,
        );
        final boardW = cellSize * logicalCols;
        final boardH = cellSize * logicalRows;

        return GestureDetector(
          onTapDown: (d) => _handleTap(d.localPosition, cellSize),
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: CustomPaint(
              painter: BoardPainter(
                board: widget.board,
                exitAnimations: List.unmodifiable(_exitAnims),
                cellSize: cellSize,
                cols: logicalCols,
                rows: logicalRows,
                flash: _flash,
              ),
            ),
          ),
        );
      },
    );
  }
}
