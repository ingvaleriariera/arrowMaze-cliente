import 'dart:math';
import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_painter.dart'
    show ExitingArrowAnim, FlashType, SmashingArrowAnim;
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/math_3d_projection.dart';

abstract class Renderable {
  final double depth;
  Renderable(this.depth);
  void paint(Canvas canvas);
}

class DotRenderable extends Renderable {
  final Offset center;
  final double radius;
  final Paint paintObj;

  DotRenderable({
    required double depth,
    required this.center,
    required this.radius,
    required this.paintObj,
  }) : super(depth);

  @override
  void paint(Canvas canvas) {
    canvas.drawCircle(center, radius, paintObj);
  }
}

class ArrowRenderable extends Renderable {
  final void Function(Canvas) _paintAction;
  
  ArrowRenderable({
    required double depth,
    required void Function(Canvas) paintAction,
  }) : _paintAction = paintAction, super(depth);

  @override
  void paint(Canvas canvas) {
    _paintAction(canvas);
  }
}

class True3DBoardPainter extends CustomPainter {
  final Board board;
  final Set<String> activatableArrows;
  final Map<String, FlashType> flashMap;
  final double cellSize;
  final int minX;
  final int minY;
  final int cols;
  final int rows;
  final List<ExitingArrowAnim>? exitingArrows;
  final String? highlightArrowId;
  final double highlightPulse;
  final double gridOverlayOpacity;
  final List<SmashingArrowAnim>? smashingArrows;
  
  final double rotationX;
  final double rotationY;

  late final Math3DProjection _proj;

  static const List<Color> _layerDotColors = [
    Color(0xFF252535),
    Color(0xFF1E3A55),
    Color(0xFF1E4638),
    Color(0xFF4A4322),
  ];

  True3DBoardPainter({
    required this.board,
    required this.activatableArrows,
    required this.cellSize,
    required this.minX,
    required this.minY,
    required this.cols,
    required this.rows,
    required this.flashMap,
    required this.rotationX,
    required this.rotationY,
    this.exitingArrows,
    this.highlightArrowId,
    this.highlightPulse = 0,
    this.gridOverlayOpacity = 0,
    this.smashingArrows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D0D18),
    );

    _proj = Math3DProjection(
      cellSize: cellSize,
      minX: minX,
      minY: minY,
      cols: cols,
      rows: rows,
      maxZ: board.shape.maxZ(),
      canvasSize: size,
      rotX: rotationX,
      rotY: rotationY,
    );

    final renderables = <Renderable>[];

    // 1. Cells
    final dotRadius = max(2.0, cellSize * 0.07);
    for (final pos in board.shape.getCells()) {
      final p = _proj.project(pos.x.toDouble(), pos.y.toDouble(), pos.z.toDouble());
      renderables.add(DotRenderable(
        depth: p.depth,
        center: p.screen,
        radius: dotRadius,
        paintObj: Paint()..color = _layerDotColors[pos.z % _layerDotColors.length],
      ));
    }

    // 2. Arrows
    for (final arrow in board.arrows.values) {
      final color = Color(
        int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) | 0xFF000000,
      );
      final flash = flashMap[arrow.id];
      final boost = arrow.id == highlightArrowId ? highlightPulse : 0.0;
      
      final centers = arrow.segments
          .map((s) => _proj.project(s.position.x.toDouble(), s.position.y.toDouble(), s.position.z.toDouble()))
          .toList();
      
      final avgDepth = centers.fold<double>(0, (sum, c) => sum + c.depth) / centers.length;
      final screenPoints = centers.map((c) => c.screen).toList();

      renderables.add(ArrowRenderable(
        depth: avgDepth,
        paintAction: (c) => _drawArrowAtOffsets(c, screenPoints, arrow.getDirection(), color, 1.0, flash, glowBoost: boost, headZ: arrow.getHead().position.z.toDouble())
      ));
    }

    // 3. Hint Ring
    if (highlightArrowId != null) {
      final arrow = board.arrows[highlightArrowId];
      if (arrow != null) {
        final headPos = arrow.getHead().position;
        final p = _proj.project(headPos.x.toDouble(), headPos.y.toDouble(), headPos.z.toDouble());
        final radius = cellSize * (0.55 + 0.15 * highlightPulse);
        renderables.add(ArrowRenderable(
          depth: p.depth - 0.1, // slightly in front of arrow
          paintAction: (c) {
            c.drawCircle(p.screen, radius, Paint()
              ..color = const Color(0xFFFFD700).withAlpha((140 + 100 * highlightPulse).round())
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(2.0, cellSize * 0.07));
          }
        ));
      }
    }

    // 4. Exit Lines (Grid Overlay)
    if (gridOverlayOpacity > 0) {
      for (final arrow in board.arrows.values) {
        final color = Color(
          int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) | 0xFF000000,
        );
        final head = arrow.getHead().position;
        final dir = arrow.getDirection();
        final dist = board.shape.distanceToExit(head, dir);
        if (dist <= 0) continue;

        final start = _proj.project(head.x.toDouble(), head.y.toDouble(), head.z.toDouble());
        final end = _proj.project((head.x + dir.dx * dist).toDouble(), (head.y + dir.dy * dist).toDouble(), (head.z + dir.dz * dist).toDouble());
        final (vx, vy) = _proj.screenVector(head.x.toDouble(), head.y.toDouble(), head.z.toDouble(), dir.dx.toDouble(), dir.dy.toDouble(), dir.dz.toDouble());
        
        renderables.add(ArrowRenderable(
          depth: start.depth - 0.05,
          paintAction: (c) {
            c.drawLine(
              Offset(start.screen.dx + vx * cellSize * 0.3, start.screen.dy + vy * cellSize * 0.3),
              end.screen,
              Paint()
                ..color = color.withAlpha((gridOverlayOpacity * 200).round())
                ..strokeWidth = max(1.5, cellSize * 0.04)
                ..strokeCap = StrokeCap.round
            );
          }
        ));
      }
    }

    // 5. Smashing Arrows
    if (smashingArrows != null) {
      for (final smash in smashingArrows!) {
        final color = Color(int.parse(smash.color.replaceFirst('#', ''), radix: 16) | 0xFF000000);
        final centers = smash.cells.map((s) => _proj.project(s.x.toDouble(), s.y.toDouble(), s.z.toDouble())).toList();
        final scale = (1 - smash.progress).clamp(0.0, 1.0);
        if (scale <= 0) continue;

        final avgDepth = centers.fold<double>(0, (sum, c) => sum + c.depth) / centers.length;
        final screenPoints = centers.map((c) => c.screen).toList();
        final centroid = screenPoints.reduce((a, b) => a + b) / screenPoints.length.toDouble();

        renderables.add(ArrowRenderable(
          depth: avgDepth - 0.1,
          paintAction: (c) {
            c.save();
            c.translate(centroid.dx, centroid.dy);
            c.scale(scale);
            c.translate(-centroid.dx, -centroid.dy);
            _drawArrowAtOffsets(c, screenPoints, smash.direction, color, scale, null, headZ: smash.cells.last.z.toDouble());
            c.restore();
            _drawImpactBurst(c, screenPoints.last, color, smash.progress);
          }
        ));
      }
    }

    // 6. Exiting Arrows (Worm)
    if (exitingArrows != null) {
      for (final exit in exitingArrows!) {
        final color = Color(int.parse(exit.color.replaceFirst('#', ''), radix: 16) | 0xFF000000);
        final n = exit.cells.length;
        final totalDistance = exit.edgeDistance + n;
        final headTravel = exit.progress * totalDistance;

        final List<({Offset screen, double depth})> centers = [];
        for (int i = 0; i < n; i++) {
          final s = i + headTravel;
          final (double px, double py) = _posOnPath(exit.cells, exit.direction, s);
          final pz = _zOnPath(exit.cells, exit.direction, s);
          centers.add(_proj.project(px, py, pz));
        }

        final avgDepth = centers.fold<double>(0, (sum, c) => sum + c.depth) / centers.length;
        final screenPoints = centers.map((c) => c.screen).toList();
        final headZ = _zOnPath(exit.cells, exit.direction, (n - 1) + headTravel);

        renderables.add(ArrowRenderable(
          depth: avgDepth - 0.1,
          paintAction: (c) => _drawArrowAtOffsets(c, screenPoints, exit.direction, color, 1.0, null, headZ: headZ)
        ));
      }
    }

    // Sort far to near. Larger W in our math means further away.
    // Wait, let's check Math3DProjection. The Z is positive for upper floors.
    // Standard perspective divide: w = z. If we want far things to be drawn first, we sort descending by depth?
    // Let's sort ascending by depth if w is larger for closer things.
    // Actually, in our matrix, we just did transform(). Z isn't negated inside projection.
    // Since Z=0 is ground and Z=maxZ is top, top is closer to camera. So larger Z is closer.
    // With rotateX(pitch), the top of the board goes further away if pitched back.
    // Let's just sort by W and see. If it's backward, we'll reverse.
    renderables.sort((a, b) => b.depth.compareTo(a.depth));

    // Paint all
    for (final r in renderables) {
      r.paint(canvas);
    }
  }

  // --- Drawing logic adapted from BoardPainter ---

  void _drawArrowAtOffsets(
      Canvas canvas,
      List<Offset> cellCenters,
      Direction direction,
      Color color,
      double alpha,
      FlashType? flash, {
      double glowBoost = 0,
      required double headZ,
  }) {
    // Screen vector from the head center backwards? No, from head center forwards.
    // We can compute the screen vector by taking the head point and projecting a point + direction.
    // Or we just approximate the screen vector from the last two segments if n > 1.
    // If n=1, we need the true projection vector.
    
    // Instead of using BoardProjection's screenVector, we can just project the direction directly.
    final (vx, vy) = _proj.screenVector(0, 0, headZ, direction.dx.toDouble(), direction.dy.toDouble(), direction.dz.toDouble());
    
    final col = flash == FlashType.ok
        ? const Color(0xFF00F5A0)
        : flash == FlashType.fail
            ? const Color(0xFFFF3366)
            : color;

    final bw = cellSize * 0.09;
    final hw = bw * 3.2;
    final hl = bw * 4.2;
    final glowBlur = (flash != null ? 24.0 : 12.0) + glowBoost * 20.0;
    final glowAlpha = (alpha * (0.6 + glowBoost * 0.4)).clamp(0.0, 1.0);

    if (cellCenters.length == 1) {
      final c = cellCenters[0];
      final path = Path()
        ..moveTo(c.dx - vx * cellSize * 0.28, c.dy - vy * cellSize * 0.28)
        ..lineTo(c.dx, c.dy);
      _drawGradientPath(canvas, path, col, glowAlpha, bw, glowBlur);
      _drawGradientPath(canvas, path, col, alpha, bw, null);
      _drawHead(canvas, c.dx, c.dy, vx, vy, hw, hl, col, alpha);
    } else {
      final r = cellSize * 0.38;
      final path = Path()..moveTo(cellCenters[0].dx, cellCenters[0].dy);

      for (int i = 1; i < cellCenters.length - 1; i++) {
        final prev = cellCenters[i - 1];
        final curr = cellCenters[i];
        final next = cellCenters[i + 1];

        final idx = curr.dx - prev.dx;
        final idy = curr.dy - prev.dy;
        final il = sqrt(idx * idx + idy * idy);
        if (il == 0) continue;

        final odx = next.dx - curr.dx;
        final ody = next.dy - curr.dy;
        final ol = sqrt(odx * odx + ody * ody);
        if (ol == 0) continue;

        final cr = min(r, min(il / 2, ol / 2));
        path.lineTo(curr.dx - idx / il * cr, curr.dy - idy / il * cr);
        path.quadraticBezierTo(curr.dx, curr.dy,
            curr.dx + odx / ol * cr, curr.dy + ody / ol * cr);
      }
      path.lineTo(cellCenters.last.dx, cellCenters.last.dy);

      _drawGradientPath(canvas, path, col, glowAlpha, bw, glowBlur);
      _drawGradientPath(canvas, path, col, alpha, bw, null);
      _drawHead(canvas, cellCenters.last.dx, cellCenters.last.dy, vx, vy, hw, hl, col, alpha);
    }
  }

  void _drawGradientPath(Canvas canvas, Path path, Color col, double alpha, double strokeWidth, double? blurSigma) {
    Paint makeP(Color c) => Paint()
      ..color = c
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = blurSigma != null ? MaskFilter.blur(BlurStyle.normal, blurSigma) : null;

    final base = col.withAlpha((alpha * 255).toInt());
    if (blurSigma != null) {
      canvas.drawPath(path, makeP(base));
      return;
    }

    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0.0, (s, m) => s + m.length);
    if (total <= 0) {
      canvas.drawPath(path, makeP(base));
      return;
    }

    const resolution = 10;
    double traveled = 0;
    for (final metric in metrics) {
      final segLen = metric.length;
      if (segLen <= 0) continue;
      final steps = max(1, (resolution * segLen / total).round());
      final stepLen = segLen / steps;
      for (int i = 0; i < steps; i++) {
        final from = i * stepLen;
        final to = min(segLen, from + stepLen);
        final frac = (traveled + (from + to) / 2) / total;
        canvas.drawPath(metric.extractPath(from, to), makeP(Color.lerp(base, base, frac)!));
      }
      traveled += segLen;
    }
  }

  void _drawHead(Canvas canvas, double hx, double hy, double vx, double vy, double hw, double hl, Color col, double alpha) {
    final tx = hx + vx * hl * 0.65;
    final ty = hy + vy * hl * 0.65;
    final bx = hx - vx * hl * 0.40;
    final by = hy - vy * hl * 0.40;
    final ppx = -vy;
    final ppy = vx;

    canvas.drawPath(
      Path()
        ..moveTo(tx, ty)
        ..lineTo(bx + ppx * hw / 2, by + ppy * hw / 2)
        ..lineTo(bx - ppx * hw / 2, by - ppy * hw / 2)
        ..close(),
      Paint()
        ..color = col.withAlpha((alpha * 255).toInt())
        ..style = PaintingStyle.fill,
    );
  }

  void _drawImpactBurst(Canvas canvas, Offset center, Color col, double progress) {
    const rays = 6;
    final len = cellSize * 0.9 * progress;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = col.withAlpha((alpha * 255).round())
      ..strokeWidth = max(1.5, cellSize * 0.05)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rays; i++) {
      final angle = 2 * pi * i / rays;
      canvas.drawLine(center, center + Offset(cos(angle) * len, sin(angle) * len), paint);
    }
  }

  (double, double) _posOnPath(List<Position> cells, Direction direction, double s) {
    final n = cells.length;
    if (s <= 0) return (cells[0].x.toDouble(), cells[0].y.toDouble());
    if (s >= n - 1) {
      final last = cells[n - 1];
      final over = s - (n - 1);
      return (last.x + direction.dx * over, last.y + direction.dy * over);
    }
    final i = s.floor();
    final f = s - i;
    return (
      cells[i].x + (cells[i + 1].x - cells[i].x) * f,
      cells[i].y + (cells[i + 1].y - cells[i].y) * f,
    );
  }

  double _zOnPath(List<Position> cells, Direction direction, double s) {
    final n = cells.length;
    if (s <= 0) return cells[0].z.toDouble();
    if (s >= n - 1) {
      final last = cells[n - 1];
      final over = s - (n - 1);
      return last.z + direction.dz * over;
    }
    final i = s.floor();
    final f = s - i;
    return cells[i].z + (cells[i + 1].z - cells[i].z) * f;
  }

  @override
  bool shouldRepaint(True3DBoardPainter old) =>
      old.board != board ||
      old.flashMap != flashMap ||
      old.exitingArrows != exitingArrows ||
      old.highlightArrowId != highlightArrowId ||
      old.highlightPulse != highlightPulse ||
      old.gridOverlayOpacity != gridOverlayOpacity ||
      old.smashingArrows != smashingArrows ||
      old.rotationX != rotationX ||
      old.rotationY != rotationY;
}
