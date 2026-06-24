import 'dart:math';
import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';

enum FlashType { ok, fail }

class BoardPainter extends CustomPainter {
  final Board board;
  final Set<String> activatableArrows;
  final String? flashingArrowId;
  final FlashType? flashType;
  final double cellSize;
  final int minX;
  final int minY;
  final List<ExitingArrowAnimation>? exitingArrows;

  BoardPainter({
    required this.board,
    required this.activatableArrows,
    required this.cellSize,
    required this.minX,
    required this.minY,
    this.flashingArrowId,
    this.flashType,
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
      final isActivatable = activatableArrows.contains(arrow.id);

      final color = Color(
        int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) |
            0xFF000000,
      );

      final alpha = isActivatable ? 1.0 : 0.28;

      _drawArrow(canvas, arrow, color, alpha, flashType);
    }

    // 4. Draw exiting arrows with animation
    if (exitingArrows != null) {
      for (final exiting in exitingArrows!) {
        final color = Color(
          int.parse(exiting.color.replaceFirst('#', ''), radix: 16) |
              0xFF000000,
        );
        _drawArrow(canvas, exiting.arrow, color, exiting.alpha,
            FlashType.ok);
      }
    }
  }

  void _drawArrow(Canvas canvas, Arrow arrow, Color color, double alpha,
      FlashType? flash) {
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

    final cellCenters = arrow.segments.map((segment) {
      final x = segment.position.x - minX;
      final y = segment.position.y - minY;
      return Offset(x * cellSize + cellSize / 2, y * cellSize + cellSize / 2);
    }).toList();

    final direction = arrow.getDirection();

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
    return oldDelegate.flashingArrowId != flashingArrowId ||
        oldDelegate.flashType != flashType ||
        oldDelegate.exitingArrows != exitingArrows ||
        oldDelegate.board != board;
  }
}

class ExitingArrowAnimation {
  final Arrow arrow;
  final String color;
  final double alpha;

  ExitingArrowAnimation({
    required this.arrow,
    required this.color,
    required this.alpha,
  });
}
