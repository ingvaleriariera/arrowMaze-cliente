import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';

class ArrowPainter extends CustomPainter {
  final Direction direction;
  final Color color;
  final double cellSize;
  final bool isActivatable;

  ArrowPainter({
    required this.direction,
    required this.color,
    required this.cellSize,
    required this.isActivatable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Replicate HTML drawing logic exactly
    final bw = cellSize * 0.17;  // body width (line thickness)
    final hw = cellSize * 0.48;  // head width (triangle base)
    final hl = cellSize * 0.38;  // head length (triangle tip distance)

    // Center of cell
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Direction vector
    final dx = direction.dx.toDouble();
    final dy = direction.dy.toDouble();

    // Paint for body (line)
    final bodyPaint = Paint()
      ..color = color
      ..strokeWidth = bw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw body: line from back of arrow to head position
    final startX = cx - dx * cellSize * 0.28;
    final startY = cy - dy * cellSize * 0.28;
    final endX = cx;
    final endY = cy;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      bodyPaint,
    );

    // Draw head (triangle)
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Triangle points (matching HTML drawHead logic exactly)
    // Tip: forward along direction
    final tx = cx + dx * hl * 0.65;
    final ty = cy + dy * hl * 0.65;

    // Base: backward along direction
    final bx = cx - dx * hl * 0.40;
    final by = cy - dy * hl * 0.40;

    // Perpendicular vector for width
    final ppx = -dy;  // perpendicular X
    final ppy = dx;   // perpendicular Y

    // Triangle path: tip → left base → right base → close
    final path = Path()
      ..moveTo(tx, ty)
      ..lineTo(
        bx + ppx * hw / 2,
        by + ppy * hw / 2,
      )
      ..lineTo(
        bx - ppx * hw / 2,
        by - ppy * hw / 2,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Draw shadow/glow if activatable
    if (isActivatable) {
      final shadowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
      canvas.drawPath(path, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.color != color ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.isActivatable != isActivatable;
  }
}
