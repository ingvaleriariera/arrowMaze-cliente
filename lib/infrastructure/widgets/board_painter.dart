import 'dart:math';
import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_projection.dart';

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

  /// 3D game: cascade projection drawing every layer simultaneously —
  /// see BoardProjection. On flat boards it degenerates to the plain 2D
  /// math this painter always used.
  late final BoardProjection projection = BoardProjection(
    cellSize: cellSize,
    minX: minX,
    minY: minY,
    maxZ: board.shape.maxZ(),
  );

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
  });

  /// Floor identity colors for the cell dots, one per layer (adapted to
  /// the dark background from the Forge reference palette: gray, blue,
  /// green, yellow pastels).
  static const List<Color> _layerDotColors = [
    Color(0xFF252535),
    Color(0xFF1E3A55),
    Color(0xFF1E4638),
    Color(0xFF4A4322),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Black background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D0D18),
    );

    // 1b. Prism lateral faces — the "fat" 3D body of the shape.
    // Drawn before cell dots and arrows so everything on top renders
    // over the faces correctly. Skipped entirely on flat (2D) boards.
    _drawPrismFaces(canvas);

    // 2. Draw valid cell dots — every layer at once, bottom (z=0) first
    // so upper floors paint over lower ones, each floor with its own
    // identity color.
    final dotRadius = max(2.0, cellSize * 0.07);
    final cells = board.shape.getCells()
      ..sort((a, b) => a.z.compareTo(b.z));

    for (final pos in cells) {
      final dotPaint = Paint()
        ..color = _layerDotColors[pos.z % _layerDotColors.length];
      canvas.drawCircle(projection.centerOf(pos), dotRadius, dotPaint);
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
        final color = Color(
          int.parse(exiting.color.replaceFirst('#', ''), radix: 16) |
              0xFF000000,
        );

        final n = exiting.cells.length;
        final totalDistance = exiting.edgeDistance + n;
        final headTravel = exiting.progress * totalDistance;

        final cellCenters = List<Offset>.generate(n, (i) {
          final pos = _posOnPath(exiting.cells, exiting.direction, i + headTravel);
          // The interpolation is planar (Z exits skip this animation);
          // each sample keeps the layer of the nearest original cell so
          // cross-layer bodies stay on their floors while sliding out.
          final z = exiting.cells[min(i, n - 1)].z;
          return projection.centerOfXYZ(pos.dx, pos.dy, z);
        });

        _drawArrowAtOffsets(canvas, cellCenters, exiting.direction, color, 1.0, null);
      }
    }
  }

  /// Draws the visible lateral faces of the extruded prism that gives the
  /// board its 3D "fat" appearance. Each face is a quadrilateral spanning
  /// from the bottom layer (z=0) to the top layer (z=maxZ):
  ///
  ///   • South face (front): drawn for every cell whose southern neighbour
  ///     is outside the shape. Painted in a mid-dark navy.
  ///   • East face (right): drawn for every cell whose eastern neighbour is
  ///     outside the shape. Painted slightly darker (shadow effect).
  ///
  /// Both faces are outlined with a purple-ish stroke that echoes the
  /// neon aesthetic of the game without clashing with arrow colors.
  ///
  /// Returns immediately when [projection.maxZ] == 0 (flat / 2D boards)
  /// so the 2D rendering path is completely unaffected.
  void _drawPrismFaces(Canvas canvas) {
    final mz = projection.maxZ;
    if (mz <= 0) return;

    final half = projection.cellSize / 2;

    // South face — slightly lit (this is the "front" of the prism,
    // closest to the viewer in the cascade isometric view).
    final southPaint = Paint()..color = const Color(0xFF1C1C3C);
    // East face — darker (side face catches less "light").
    final eastPaint = Paint()..color = const Color(0xFF111128);
    // Shared edge outline — blue-purple neon hint, same aesthetic family
    // as the arrow colors.
    final edgePaint = Paint()
      ..color = const Color(0xFF30307A)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Iterate the base (z=0) silhouette only — every (x,y) that exists
    // at z=0 also exists at every upper layer (extrusion is uniform), so
    // the boundary check is the same for all layers.
    final baseCells = board.shape.getCells()
        .where((p) => p.z == 0)
        .toList();

    // ── South faces (bottom edge exposed) ──────────────────────────────
    for (final pos in baseCells) {
      final gx = pos.x;
      final gy = pos.y;
      if (board.shape.contains(Position(gx, gy + 1, 0))) continue;

      // Bottom edge of cell (gx, gy) at z=0 (lowest layer)
      final c0 = projection.centerOf(Position(gx, gy, 0));
      final bl0 = c0 + Offset(-half, half);
      final br0 = c0 + Offset(half, half);

      // Bottom edge of same cell at z=mz (top layer)
      final cM = projection.centerOf(Position(gx, gy, mz));
      final blM = cM + Offset(-half, half);
      final brM = cM + Offset(half, half);

      final path = Path()
        ..moveTo(bl0.dx, bl0.dy)
        ..lineTo(br0.dx, br0.dy)
        ..lineTo(brM.dx, brM.dy)
        ..lineTo(blM.dx, blM.dy)
        ..close();

      canvas.drawPath(path, southPaint);
      canvas.drawPath(path, edgePaint);
    }

    // ── East faces (right edge exposed) ────────────────────────────────
    for (final pos in baseCells) {
      final gx = pos.x;
      final gy = pos.y;
      if (board.shape.contains(Position(gx + 1, gy, 0))) continue;

      // Right edge of cell (gx, gy) at z=0
      final c0 = projection.centerOf(Position(gx, gy, 0));
      final tr0 = c0 + Offset(half, -half);
      final br0 = c0 + Offset(half, half);

      // Right edge at z=mz
      final cM = projection.centerOf(Position(gx, gy, mz));
      final trM = cM + Offset(half, -half);
      final brM = cM + Offset(half, half);

      final path = Path()
        ..moveTo(tr0.dx, tr0.dy)
        ..lineTo(br0.dx, br0.dy)
        ..lineTo(brM.dx, brM.dy)
        ..lineTo(trM.dx, trM.dy)
        ..close();

      canvas.drawPath(path, eastPaint);
      canvas.drawPath(path, edgePaint);
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
    // The whole snake body, projected through the cascade: segments on
    // different layers land at different diagonal offsets, so a body that
    // climbs between floors is drawn as one continuous stroke with a
    // visible diagonal "in the air" — no per-layer slicing.
    final cellCenters = arrow.segments
        .map((segment) => projection.centerOf(segment.position))
        .toList();

    _drawArrowAtOffsets(canvas, cellCenters, arrow.getDirection(), color,
        alpha, flash, glowBoost: glowBoost);
  }

  void _drawArrowAtOffsets(Canvas canvas, List<Offset> cellCenters,
      Direction direction, Color color, double alpha, FlashType? flash,
      {double glowBoost = 0}) {
    // Screen-space direction: planar arrows keep their axis; Z arrows
    // point along the cascade diagonal toward their destination layer.
    final (vx, vy) = projection.screenVector(
        direction.dx, direction.dy, direction.dz);
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
      final startX = c.dx - vx * cellSize * 0.28;
      final startY = c.dy - vy * cellSize * 0.28;
      final path = Path()..moveTo(startX, startY)..lineTo(c.dx, c.dy);

      _drawGradientPath(canvas, path, col, glowAlpha, bw, glowBlur);
      _drawGradientPath(canvas, path, col, alpha, bw, null);
      _drawHead(canvas, c.dx, c.dy, vx, vy, hw, hl, col, alpha);
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
      _drawHead(canvas, last.dx, last.dy, vx, vy, hw, hl, col, alpha);
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

    final center = projection.centerOf(arrow.getHead().position);
    final cx = center.dx;
    final cy = center.dy;

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
      final distance = board.shape.distanceToExit(head, direction);
      if (distance <= 0) continue;

      // Both endpoints go through the cascade projection, so Z exits get
      // a diagonal line toward their destination layer, same as any
      // planar exit gets its straight one.
      final headCenter = projection.centerOf(head);
      final exitCenter = projection.centerOf(Position(
        head.x + direction.dx * distance,
        head.y + direction.dy * distance,
        head.z + direction.dz * distance,
      ));
      final (vx, vy) = projection.screenVector(
          direction.dx, direction.dy, direction.dz);
      final startX = headCenter.dx + vx * cellSize * 0.3;
      final startY = headCenter.dy + vy * cellSize * 0.3;
      final endX = exitCenter.dx;
      final endY = exitCenter.dy;

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
      final color = Color(
        int.parse(smash.color.replaceFirst('#', ''), radix: 16) |
            0xFF000000,
      );
      final cellCenters =
          smash.cells.map(projection.centerOf).toList();

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

  /// Draws the triangular head pointing along the screen-space unit
  /// vector (vx, vy) — an axis for planar arrows, the cascade diagonal
  /// for Z-axis ones.
  void _drawHead(Canvas canvas, double hx, double hy, double vx, double vy,
      double hw, double hl, Color col, double alpha) {
    final tx = hx + vx * hl * 0.65;
    final ty = hy + vy * hl * 0.65;

    final bx = hx - vx * hl * 0.40;
    final by = hy - vy * hl * 0.40;

    final ppx = -vy;
    final ppy = vx;

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
        oldDelegate.smashingArrows != smashingArrows;
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
