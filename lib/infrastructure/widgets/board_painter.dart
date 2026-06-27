import 'dart:math';
import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

enum FlashType { ok, fail }

class BoardPainter extends CustomPainter {
  final Board board;
  final Set<String> activatableArrows;
  final Map<String, FlashType> flashMap;
  final double cellSize;
  final int minX;
  final int minY;
  final List<ExitingArrowAnim>? exitingArrows;

  BoardPainter({
    required this.board,
    required this.activatableArrows,
    required this.cellSize,
    required this.minX,
    required this.minY,
    required this.flashMap,
    this.exitingArrows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Black background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D0D18),
    );

    // 2. Draw valid cell dots
    final dotRadius = max(2.0, cellSize * 0.07);
    final dotPaint = Paint()..color = const Color(0xFF252535);

    for (final pos in board.shape.getCells()) {
      final screenX = (pos.x - minX) * cellSize + cellSize / 2;
      final screenY = (pos.y - minY) * cellSize + cellSize / 2;
      canvas.drawCircle(Offset(screenX, screenY), dotRadius, dotPaint);
    }

    // 3. Draw static arrows
    for (final arrow in board.arrows.values) {
      final color = Color(
        int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) |
            0xFF000000,
      );

      // All arrows are bright - blocked arrows show red flash when tapped
      final alpha = 1.0;
      final flashType = flashMap[arrow.id];

      _drawArrow(canvas, arrow, color, alpha, flashType);
    }

    // 4. Draw exiting arrows sliding off the board along their exit
    // direction, the whole snake moving together (head leaves first, tail
    // follows the same path), matching the worm-exit animation from the
    // HTML reference (docs/arrow_maze_v5.html).
    if (exitingArrows != null) {
      for (final exiting in exitingArrows!) {
        final color = Color(
          int.parse(exiting.color.replaceFirst('#', ''), radix: 16) |
              0xFF000000,
        );

        final n = exiting.cells.length;
        final totalDistance = exiting.edgeDistance + n;
        final headTravel = exiting.progress * totalDistance;

        final cellCenters = List<Offset>.generate(n, (i) {
          final pos = _posOnPath(exiting.cells, exiting.direction, i + headTravel);
          final x = pos.dx - minX;
          final y = pos.dy - minY;
          return Offset(
              x * cellSize + cellSize / 2, y * cellSize + cellSize / 2);
        });

        _drawArrowAtOffsets(canvas, cellCenters, exiting.direction, color, 1.0, null);
      }
    }
  }

  /// Interpolated position along [cells] extended past its last cell in
  /// [direction], at fractional distance [s] measured in cell-units from
  /// the start of the path. Mirrors getPosOnPath() in the HTML reference.
  Offset _posOnPath(List<Position> cells, Direction direction, double s) {
    final n = cells.length;
    if (s <= 0) {
      return Offset(cells[0].x.toDouble(), cells[0].y.toDouble());
    }
    if (s >= n - 1) {
      final last = cells[n - 1];
      final overshoot = s - (n - 1);
      return Offset(
        last.x + direction.dx * overshoot,
        last.y + direction.dy * overshoot,
      );
    }
    final i = s.floor();
    final f = s - i;
    final a = cells[i];
    final b = cells[i + 1];
    return Offset(
      a.x + (b.x - a.x) * f,
      a.y + (b.y - a.y) * f,
    );
  }

  void _drawArrow(Canvas canvas, Arrow arrow, Color color, double alpha,
      FlashType? flash) {
    final cellCenters = arrow.segments.map((segment) {
      final x = segment.position.x - minX;
      final y = segment.position.y - minY;
      return Offset(x * cellSize + cellSize / 2, y * cellSize + cellSize / 2);
    }).toList();

    _drawArrowAtOffsets(canvas, cellCenters, arrow.getDirection(), color,
        alpha, flash);
  }

  void _drawArrowAtOffsets(Canvas canvas, List<Offset> cellCenters,
      Direction direction, Color color, double alpha, FlashType? flash) {
    final col = flash == FlashType.ok
        ? const Color(0xFF00F5A0)
        : flash == FlashType.fail
            ? const Color(0xFFFF3366)
            : color;

    final bw = cellSize * 0.17;
    final hw = cellSize * 0.48;
    final hl = cellSize * 0.38;

    final paint = Paint()
      ..color = col.withAlpha((alpha * 255).toInt())
      ..strokeWidth = bw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = col.withAlpha((alpha * 0.6 * 255).toInt())
      ..strokeWidth = bw
      ..maskFilter = MaskFilter.blur(
          BlurStyle.normal, flash != null ? 24 : 12);

    if (cellCenters.length == 1) {
      final c = cellCenters[0];
      final startX = c.dx - direction.dx * cellSize * 0.28;
      final startY = c.dy - direction.dy * cellSize * 0.28;
      final path = Path()..moveTo(startX, startY)..lineTo(c.dx, c.dy);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
      _drawHead(canvas, c.dx, c.dy, direction, hw, hl, col, alpha);
    } else {
      final r = cellSize * 0.38;
      final path = Path();
      path.moveTo(cellCenters[0].dx, cellCenters[0].dy);

      for (int i = 1; i < cellCenters.length - 1; i++) {
        final prev = cellCenters[i - 1];
        final curr = cellCenters[i];
        final next = cellCenters[i + 1];

        final idx = curr.dx - prev.dx;
        final idy = curr.dy - prev.dy;
        final il = sqrt(idx * idx + idy * idy);

        final odx = next.dx - curr.dx;
        final ody = next.dy - curr.dy;
        final ol = sqrt(odx * odx + ody * ody);

        final cr = min(r, min(il / 2, ol / 2));

        path.lineTo(curr.dx - idx / il * cr, curr.dy - idy / il * cr);
        path.quadraticBezierTo(curr.dx, curr.dy,
            curr.dx + odx / ol * cr, curr.dy + ody / ol * cr);
      }

      final last = cellCenters.last;
      path.lineTo(last.dx, last.dy);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
      _drawHead(canvas, last.dx, last.dy, direction, hw, hl, col, alpha);
    }
  }

  void _drawHead(Canvas canvas, double hx, double hy, Direction vec,
      double hw, double hl, Color col, double alpha) {
    final tx = hx + vec.dx * hl * 0.65;
    final ty = hy + vec.dy * hl * 0.65;

    final bx = hx - vec.dx * hl * 0.40;
    final by = hy - vec.dy * hl * 0.40;

    final ppx = -vec.dy.toDouble();
    final ppy = vec.dx.toDouble();

    final path = Path()
      ..moveTo(tx, ty)
      ..lineTo(bx + ppx * hw / 2, by + ppy * hw / 2)
      ..lineTo(bx - ppx * hw / 2, by - ppy * hw / 2)
      ..close();

    final paint = Paint()
      ..color = col.withAlpha((alpha * 255).toInt())
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return oldDelegate.flashMap != flashMap ||
        oldDelegate.exitingArrows != exitingArrows ||
        oldDelegate.board != board;
  }
}

/// A snapshot of an arrow that just exited, plus enough geometry to slide
/// it off the board over the animation's lifetime. [progress] is the
/// eased (0..1) fraction of the animation already elapsed.
class ExitingArrowAnim {
  final List<Position> cells;
  final Direction direction;
  final String color;
  final int edgeDistance;
  final double progress;

  ExitingArrowAnim({
    required this.cells,
    required this.direction,
    required this.color,
    required this.edgeDistance,
    required this.progress,
  });
}
