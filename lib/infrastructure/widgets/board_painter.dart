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

  /// Hint power-up: which arrow to pulse, and how bright the pulse is
  /// right now (0..1, driven by a repeating AnimationController).
  final String? highlightArrowId;
  final double highlightPulse;

  /// Grid power-up: 0 when hidden, otherwise the fade in/out opacity of
  /// the exit-direction lines drawn from every arrow's head.
  final double gridOverlayOpacity;

  /// Hammer power-up: arrows currently mid-smash (shrinking + fading out
  /// in place, plus an impact burst), snapshotted before they were
  /// removed from [board].
  final List<SmashingArrowAnim>? smashingArrows;

  /// 3D game: which Z layer of the prism is being viewed. Only cells and
  /// arrow segments on this layer are painted; segments that continue to
  /// another layer show a ⊙/⊗ transition marker. Always 0 on flat boards.
  final int activeLayer;

  BoardPainter({
    required this.board,
    required this.activatableArrows,
    required this.cellSize,
    required this.minX,
    required this.minY,
    required this.flashMap,
    this.exitingArrows,
    this.highlightArrowId,
    this.highlightPulse = 0,
    this.gridOverlayOpacity = 0,
    this.smashingArrows,
    this.activeLayer = 0,
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
      if (pos.z != activeLayer) continue;
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
      final glowBoost = arrow.id == highlightArrowId ? highlightPulse : 0.0;

      _drawArrow(canvas, arrow, color, alpha, flashType, glowBoost: glowBoost);
    }

    // 3a. Hint power-up: a bright ring around the suggested arrow's head —
    // the glowBoost above is too subtle on its own against a busy board.
    _drawHintRing(canvas);

    // 3b. Grid power-up: a line from every arrow's head to where it would
    // exit, reusing the same distanceToExit() the exit animation uses.
    _drawExitLines(canvas);

    // 3c. Hammer power-up: arrows mid-smash, snapshotted before removal.
    _drawSmashingArrows(canvas);

    // 4. Draw exiting arrows sliding off the board along their exit
    // direction, the whole snake moving together (head leaves first, tail
    // follows the same path), matching the worm-exit animation from the
    // HTML reference (docs/arrow_maze_v5.html).
    if (exitingArrows != null) {
      for (final exiting in exitingArrows!) {
        // Exit animations are planar snapshots — only show the ones that
        // belong to the layer being viewed.
        if (exiting.cells.isNotEmpty && exiting.cells.first.z != activeLayer) {
          continue;
        }
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
      FlashType? flash, {double glowBoost = 0}) {
    // Only the segments living on the active layer are visible; a snake
    // can span several layers, in which case each layer shows its own
    // slice of the body.
    final onLayer = arrow.segments
        .where((s) => s.position.z == activeLayer)
        .toList();
    if (onLayer.isEmpty) return;

    final cellCenters = onLayer.map((segment) {
      final x = segment.position.x - minX;
      final y = segment.position.y - minY;
      return Offset(x * cellSize + cellSize / 2, y * cellSize + cellSize / 2);
    }).toList();

    final headOnLayer = arrow.getHead().position.z == activeLayer;

    _drawArrowAtOffsets(canvas, cellCenters, arrow.getDirection(), color,
        alpha, flash, glowBoost: glowBoost, drawHead: headOnLayer);

    // Layer-transition markers: wherever the body continues to another
    // layer, mark the cell so the player knows the snake dives/climbs.
    for (int i = 0; i < onLayer.length; i++) {
      final dz = onLayer[i].directionToNext.dz;
      final isHead = headOnLayer && i == onLayer.length - 1;
      if (dz != 0 && !isHead) {
        _drawZMarker(canvas, cellCenters[i], dz, color, alpha * 0.8,
            scale: 0.7);
      }
    }
  }

  void _drawArrowAtOffsets(Canvas canvas, List<Offset> cellCenters,
      Direction direction, Color color, double alpha, FlashType? flash,
      {double glowBoost = 0, bool drawHead = true}) {
    final col = flash == FlashType.ok
        ? const Color(0xFF00F5A0)
        : flash == FlashType.fail
            ? const Color(0xFFFF3366)
            : color;

    // Thin stroke with a head sized proportionally to it (SayGames-style
    // slender arrows), instead of the old thick fixed-ratio body/head.
    final bw = cellSize * 0.09;
    final hw = bw * 3.2;
    final hl = bw * 4.2;

    // Hint power-up: brighten and widen the existing glow pass instead of
    // drawing a separate highlight effect — glowBoost is 0 for every
    // arrow except the one currently being hinted.
    final glowBlur = (flash != null ? 24.0 : 12.0) + glowBoost * 20.0;
    final glowAlpha = (alpha * (0.6 + glowBoost * 0.4)).clamp(0.0, 1.0);

    if (cellCenters.length == 1) {
      final c = cellCenters[0];
      final startX = c.dx - direction.dx * cellSize * 0.28;
      final startY = c.dy - direction.dy * cellSize * 0.28;
      final path = Path()..moveTo(startX, startY)..lineTo(c.dx, c.dy);

      _drawGradientPath(canvas, path, col, glowAlpha, bw, glowBlur);
      _drawGradientPath(canvas, path, col, alpha, bw, null);
      if (drawHead) _drawHeadOrZMarker(canvas, c, direction, hw, hl, col, alpha);
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

      _drawGradientPath(canvas, path, col, glowAlpha, bw, glowBlur);
      _drawGradientPath(canvas, path, col, alpha, bw, null);
      if (drawHead) {
        _drawHeadOrZMarker(canvas, last, direction, hw, hl, col, alpha);
      }
    }
  }

  /// Planar heads keep the normal triangle; Z-axis heads (3D game) use
  /// the standard perpendicular-vector notation — ⊗ diving into the
  /// board, ⊙ coming out of it — since there's no planar component to
  /// point a triangle toward.
  void _drawHeadOrZMarker(Canvas canvas, Offset at, Direction direction,
      double hw, double hl, Color col, double alpha) {
    if (direction.dz == 0) {
      _drawHead(canvas, at.dx, at.dy, direction, hw, hl, col, alpha);
    } else {
      _drawZMarker(canvas, at, direction.dz, col, alpha);
    }
  }

  void _drawZMarker(Canvas canvas, Offset center, int dz, Color col,
      double alpha, {double scale = 1.0}) {
    final radius = cellSize * 0.24 * scale;
    final stroke = max(1.5, cellSize * 0.07 * scale);
    final paint = Paint()
      ..color = col.withAlpha((alpha * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, paint);

    if (dz > 0) {
      // Forward, diving into the board: ⊗
      final d = radius * 0.55;
      final line = Paint()
        ..color = col.withAlpha((alpha * 255).toInt())
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center - Offset(d, d), center + Offset(d, d), line);
      canvas.drawLine(center - Offset(d, -d), center + Offset(d, -d), line);
    } else {
      // Back, coming out of the board: ⊙
      canvas.drawCircle(
          center,
          radius * 0.35,
          Paint()..color = col.withAlpha((alpha * 255).toInt()));
    }
  }

  /// Draws [path] with a subtle gradient that runs along its actual arc
  /// length (tail dimmer, head brighter), instead of a straight-line
  /// shader between the path's start/end points. A bounding-box gradient
  /// looks fine on a single straight segment, but on a bent/curved arrow
  /// its axis cuts across the bend diagonally, so most of the visible
  /// color change bunches up around the curve while the straight legs
  /// stay nearly flat. Sampling by length keeps the transition even
  /// everywhere the stroke actually travels.
  void _drawGradientPath(Canvas canvas, Path path, Color col, double alpha,
      double strokeWidth, double? blurSigma) {
    Paint paintFor(Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (blurSigma != null) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
      }
      return paint;
    }

    final tailColor = col.withAlpha((alpha * 255).toInt());
    final headColor = col.withAlpha((alpha * 255).toInt());

    // The blurred glow pass diffuses color so much the arc-length gradient
    // is barely visible in it anyway — draw it once with the path's
    // average color instead of paying for a full per-segment subdivision
    // (with MaskFilter.blur, by far the most expensive part) just for a
    // layer where nobody can see that gradient. This is what made the
    // board noticeably slower with many arrows on screen (start of a
    // level) and lighter as arrows exit through play.
    if (blurSigma != null) {
      canvas.drawPath(path, paintFor(Color.lerp(tailColor, headColor, 0.5)!));
      return;
    }

    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0.0, (sum, m) => sum + m.length);

    if (totalLength <= 0) {
      canvas.drawPath(path, paintFor(headColor));
      return;
    }

    const resolution = 10;
    double traveled = 0;
    for (final metric in metrics) {
      final segLen = metric.length;
      if (segLen <= 0) continue;

      final steps = max(1, (resolution * segLen / totalLength).round());
      final stepLen = segLen / steps;
      for (int i = 0; i < steps; i++) {
        final from = i * stepLen;
        final to = min(segLen, from + stepLen);
        final sub = metric.extractPath(from, to);
        final frac = (traveled + (from + to) / 2) / totalLength;
        final color = Color.lerp(tailColor, headColor, frac)!;
        canvas.drawPath(sub, paintFor(color));
      }
      traveled += segLen;
    }
  }

  /// Hint power-up: a pulsing gold ring around the suggested arrow's head,
  /// unmistakable regardless of the arrow's own color — unlike the
  /// glowBoost passed into _drawArrow (a small brightness/blur bump on an
  /// already-present glow layer), this is a dedicated highlight that
  /// can't be confused with normal rendering.
  void _drawHintRing(Canvas canvas) {
    final id = highlightArrowId;
    if (id == null) return;
    final arrow = board.arrows[id];
    if (arrow == null) return;

    final head = arrow.getHead().position;
    if (head.z != activeLayer) return;
    final cx = (head.x - minX) * cellSize + cellSize / 2;
    final cy = (head.y - minY) * cellSize + cellSize / 2;

    final radius = cellSize * (0.55 + 0.15 * highlightPulse);
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
          .withAlpha((140 + 100 * highlightPulse).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, cellSize * 0.07);

    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  /// Grid power-up: a thin line from each arrow's head to the cell where
  /// it would exit, [board.shape.distanceToExit] — the same distance the
  /// exit animation already uses to know how far an arrow travels off
  /// the board.
  void _drawExitLines(Canvas canvas) {
    if (gridOverlayOpacity <= 0) return;

    for (final arrow in board.arrows.values) {
      final color = Color(
        int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) |
            0xFF000000,
      );
      final head = arrow.getHead().position;
      final direction = arrow.getDirection();
      // Only heads on the visible layer, and only planar exits — a
      // Z-exit has no on-screen line to draw (its ⊙/⊗ head already says
      // where it goes).
      if (head.z != activeLayer || direction.dz != 0) continue;
      final distance = board.shape.distanceToExit(head, direction);
      if (distance <= 0) continue;

      final startX = (head.x - minX) * cellSize +
          cellSize / 2 +
          direction.dx * cellSize * 0.3;
      final startY = (head.y - minY) * cellSize +
          cellSize / 2 +
          direction.dy * cellSize * 0.3;
      final endX = startX + direction.dx * cellSize * distance;
      final endY = startY + direction.dy * cellSize * distance;

      final paint = Paint()
        ..color = color.withAlpha((gridOverlayOpacity * 200).round())
        ..strokeWidth = max(1.5, cellSize * 0.04)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  /// Hammer power-up: shrinks and fades each smashing arrow in place
  /// (rather than sliding it off the board like a normal exit), plus a
  /// small impact burst at its head.
  void _drawSmashingArrows(Canvas canvas) {
    final smashing = smashingArrows;
    if (smashing == null) return;

    for (final smash in smashing) {
      if (smash.cells.isNotEmpty && smash.cells.first.z != activeLayer) {
        continue;
      }
      final color = Color(
        int.parse(smash.color.replaceFirst('#', ''), radix: 16) |
            0xFF000000,
      );
      final cellCenters = smash.cells.map((pos) {
        final x = pos.x - minX;
        final y = pos.y - minY;
        return Offset(
            x * cellSize + cellSize / 2, y * cellSize + cellSize / 2);
      }).toList();

      final scale = (1 - smash.progress).clamp(0.0, 1.0);
      if (scale <= 0) continue;

      final centroid = cellCenters.reduce((a, b) => a + b) /
          cellCenters.length.toDouble();

      canvas.save();
      canvas.translate(centroid.dx, centroid.dy);
      canvas.scale(scale);
      canvas.translate(-centroid.dx, -centroid.dy);
      _drawArrowAtOffsets(
          canvas, cellCenters, smash.direction, color, scale, null);
      canvas.restore();

      _drawImpactBurst(canvas, cellCenters.last, color, smash.progress);
    }
  }

  void _drawImpactBurst(
      Canvas canvas, Offset center, Color color, double progress) {
    const rays = 6;
    final maxLen = cellSize * 0.9;
    final len = maxLen * progress;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withAlpha((alpha * 255).round())
      ..strokeWidth = max(1.5, cellSize * 0.05)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rays; i++) {
      final angle = 2 * pi * i / rays;
      final offset = Offset(cos(angle) * len, sin(angle) * len);
      canvas.drawLine(center, center + offset, paint);
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
        oldDelegate.board != board ||
        oldDelegate.highlightArrowId != highlightArrowId ||
        oldDelegate.highlightPulse != highlightPulse ||
        oldDelegate.gridOverlayOpacity != gridOverlayOpacity ||
        oldDelegate.smashingArrows != smashingArrows ||
        oldDelegate.activeLayer != activeLayer;
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

/// A snapshot of an arrow mid-smash (Hammer power-up), taken before it was
/// removed from the board. [progress] is 0..1 over the smash's lifetime —
/// 0 at full size, 1 fully shrunk/faded away.
class SmashingArrowAnim {
  final List<Position> cells;
  final Direction direction;
  final String color;
  final double progress;

  SmashingArrowAnim({
    required this.cells,
    required this.direction,
    required this.color,
    required this.progress,
  });
}
