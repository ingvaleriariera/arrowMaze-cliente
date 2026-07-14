import 'dart:math';
import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_painter.dart'
    show ExitingArrowAnim, FlashType, SmashingArrowAnim;
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_projection.dart';

/// Paints ONE horizontal layer (z = [targetZ]) of a 3D extruded board using
/// flat (non-cascaded) grid coordinates.
///
/// This painter is used by [Board3DLayeredView], which wraps each layer in a
/// [Transform] that places it at a physically distinct depth in 3D space.
/// Because the 3D position is handled by the Transform, this painter works
/// entirely in the flat 2D plane of its canvas — no cascade diagonal offsets.
///
/// Drawing contract:
///   • Background: only layer z=0 paints a solid fill; upper layers are
///     transparent so lower layers remain visible during rotation.
///   • Cell tiles: rounded rectangles in the layer's identity colour.
///   • Arrows: only arrows whose HEAD is at [targetZ]; the full body is drawn
///     flat on this canvas, and the Transform positions the canvas at the
///     correct depth.
///   • Animations: exit and smash animations belonging to this layer.
class LayerBoardPainter extends CustomPainter {
  final Board board;
  final int targetZ;
  final int maxZ;
  final Set<String> activatableArrows;
  final Map<String, FlashType> flashMap;
  final double cellSize;
  final int minX;
  final int minY;
  final List<ExitingArrowAnim>? exitingArrows;
  final String? highlightArrowId;
  final double highlightPulse;
  final double gridOverlayOpacity;
  final List<SmashingArrowAnim>? smashingArrows;

  /// Flat projection (maxZ=0): resolves every position to its raw grid (x,y)
  /// screen position without any cascade diagonal shift.  The Z component of
  /// each [Position] is intentionally ignored here — the [Transform] in
  /// [Board3DLayeredView] provides the actual depth.
  late final BoardProjection _proj;

  LayerBoardPainter({
    required this.board,
    required this.targetZ,
    required this.maxZ,
    required this.activatableArrows,
    required this.flashMap,
    required this.cellSize,
    required this.minX,
    required this.minY,
    this.exitingArrows,
    this.highlightArrowId,
    this.highlightPulse = 0,
    this.gridOverlayOpacity = 0,
    this.smashingArrows,
  }) {
    _proj = BoardProjection(
      cellSize: cellSize,
      minX: minX,
      minY: minY,
      maxZ: 0, // flat — no diagonal offset
    );
  }

  /// Per-layer tile fill colours: darker at the base, progressively
  /// lighter for upper floors to give an elevation cue.
  static const List<Color> _layerFill = [
    Color(0xFF181830),
    Color(0xFF1A1E3A),
    Color(0xFF1C2444),
    Color(0xFF1E2A4E),
  ];

  /// Flat screen-centre for grid cell (gx, gy).  Z is not used here.
  Offset _flat(double gx, double gy) => Offset(
        (gx - minX) * cellSize + cellSize / 2,
        (gy - minY) * cellSize + cellSize / 2,
      );

  // ── paint ────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background — only the base layer; upper layers are transparent so
    //    you can see through them to the layers below when rotating.
    if (targetZ == 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF0D0D18),
      );
    }

    // 2. Cell tiles for this layer only.
    final fill =
        _layerFill[targetZ.clamp(0, _layerFill.length - 1)];
    final tilePaint = Paint()..color = fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF2A2A6A).withAlpha(180)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final pos in board.shape.getCells()) {
      if (pos.z != targetZ) continue;
      final c = _flat(pos.x.toDouble(), pos.y.toDouble());
      final half = cellSize / 2 - 1;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: half * 2, height: half * 2),
        Radius.circular(cellSize * 0.15),
      );
      canvas.drawRRect(rrect, tilePaint);
      canvas.drawRRect(rrect, borderPaint);
    }

    // 3. Arrows whose HEAD is at this layer (full body drawn flat).
    for (final arrow in board.arrows.values) {
      if (arrow.getHead().position.z != targetZ) continue;
      final col = Color(
        int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) |
            0xFF000000,
      );
      final flash = flashMap[arrow.id];
      final boost = arrow.id == highlightArrowId ? highlightPulse : 0.0;
      _drawArrow(canvas, arrow, col, 1.0, flash, glowBoost: boost);
    }

    // 3a. Hint ring.
    _drawHintRing(canvas);

    // 3b. Grid power-up exit lines.
    _drawExitLines(canvas);

    // 3c. Hammer smash animations.
    _drawSmashingArrows(canvas);

    // 4. Exit animations (worm) for arrows at this layer.
    _drawExitingArrows(canvas);
  }

  // ── private drawing methods ───────────────────────────────────────────────

  void _drawArrow(Canvas canvas, Arrow arrow, Color col, double alpha,
      FlashType? flash, {double glowBoost = 0}) {
    // Project all segments using flat (z-ignored) coordinates.
    final centres = arrow.segments
        .map((s) => _flat(s.position.x.toDouble(), s.position.y.toDouble()))
        .toList();
    _drawArrowAtOffsets(
        canvas, centres, arrow.getDirection(), col, alpha, flash,
        glowBoost: glowBoost);
  }

  void _drawHintRing(Canvas canvas) {
    final id = highlightArrowId;
    if (id == null) return;
    final arrow = board.arrows[id];
    if (arrow == null || arrow.getHead().position.z != targetZ) return;

    final c = _flat(arrow.getHead().position.x.toDouble(),
        arrow.getHead().position.y.toDouble());
    final radius = cellSize * (0.55 + 0.15 * highlightPulse);
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = const Color(0xFFFFD700)
            .withAlpha((140 + 100 * highlightPulse).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2.0, cellSize * 0.07),
    );
  }

  void _drawExitLines(Canvas canvas) {
    if (gridOverlayOpacity <= 0) return;
    for (final arrow in board.arrows.values) {
      if (arrow.getHead().position.z != targetZ) continue;
      final col = Color(
        int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) |
            0xFF000000,
      );
      final head = arrow.getHead().position;
      final dir = arrow.getDirection();
      final dist = board.shape.distanceToExit(head, dir);
      if (dist <= 0) continue;

      final headCentre = _flat(head.x.toDouble(), head.y.toDouble());
      // For Z exits dz!=0: dx=dy=0 so exitCentre == headCentre; the
      // screenVector diagonal gives a short stub showing the exit direction.
      final exitCentre = _flat(
        (head.x + dir.dx * dist).toDouble(),
        (head.y + dir.dy * dist).toDouble(),
      );
      final (vx, vy) =
          _proj.screenVector(dir.dx, dir.dy, dir.dz);

      canvas.drawLine(
        Offset(headCentre.dx + vx * cellSize * 0.3,
            headCentre.dy + vy * cellSize * 0.3),
        exitCentre,
        Paint()
          ..color = col.withAlpha((gridOverlayOpacity * 200).round())
          ..strokeWidth = max(1.5, cellSize * 0.04)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSmashingArrows(Canvas canvas) {
    final smashing = smashingArrows;
    if (smashing == null) return;

    for (final smash in smashing) {
      // Only smashes whose original head was on this layer.
      if (smash.cells.isEmpty || smash.cells.last.z != targetZ) continue;

      final col = Color(
        int.parse(smash.color.replaceFirst('#', ''), radix: 16) | 0xFF000000,
      );
      final centres =
          smash.cells.map((p) => _flat(p.x.toDouble(), p.y.toDouble())).toList();
      final scale = (1 - smash.progress).clamp(0.0, 1.0);
      if (scale <= 0) continue;

      final centroid =
          centres.reduce((a, b) => a + b) / centres.length.toDouble();
      canvas.save();
      canvas.translate(centroid.dx, centroid.dy);
      canvas.scale(scale);
      canvas.translate(-centroid.dx, -centroid.dy);
      _drawArrowAtOffsets(canvas, centres, smash.direction, col, scale, null);
      canvas.restore();

      _drawImpactBurst(canvas, centres.last, col, smash.progress);
    }
  }

  void _drawExitingArrows(Canvas canvas) {
    final exiting = exitingArrows;
    if (exiting == null) return;

    for (final exit in exiting) {
      // Only planar exits at this layer (Z exits have no meaningful flat
      // animation — the arrow simply disappears from its layer as it crosses
      // into the next, which is handled by the other layer's painter).
      if (exit.direction.dz != 0) continue;
      if (exit.cells.isEmpty || exit.cells.last.z != targetZ) continue;

      final col = Color(
        int.parse(exit.color.replaceFirst('#', ''), radix: 16) | 0xFF000000,
      );
      final n = exit.cells.length;
      final totalDist = exit.edgeDistance + n;
      final headTravel = exit.progress * totalDist;

      final centres = List<Offset>.generate(n, (i) {
        final pos = _posOnPath(exit.cells, exit.direction, i + headTravel);
        return _flat(pos.dx, pos.dy);
      });
      _drawArrowAtOffsets(canvas, centres, exit.direction, col, 1.0, null);
    }
  }

  // ── shared drawing utilities (mirrors BoardPainter exactly) ──────────────

  void _drawArrowAtOffsets(
      Canvas canvas,
      List<Offset> centres,
      Direction direction,
      Color color,
      double alpha,
      FlashType? flash, {
      double glowBoost = 0,
    }) {
    final (vx, vy) =
        _proj.screenVector(direction.dx, direction.dy, direction.dz);
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

    if (centres.length == 1) {
      final c = centres[0];
      final path = Path()
        ..moveTo(c.dx - vx * cellSize * 0.28, c.dy - vy * cellSize * 0.28)
        ..lineTo(c.dx, c.dy);
      _drawGradientPath(canvas, path, col, glowAlpha, bw, glowBlur);
      _drawGradientPath(canvas, path, col, alpha, bw, null);
      _drawHead(canvas, c.dx, c.dy, vx, vy, hw, hl, col, alpha);
    } else {
      final r = cellSize * 0.38;
      final path = Path()..moveTo(centres[0].dx, centres[0].dy);

      for (int i = 1; i < centres.length - 1; i++) {
        final prev = centres[i - 1];
        final curr = centres[i];
        final next = centres[i + 1];

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
      path.lineTo(centres.last.dx, centres.last.dy);

      _drawGradientPath(canvas, path, col, glowAlpha, bw, glowBlur);
      _drawGradientPath(canvas, path, col, alpha, bw, null);
      _drawHead(canvas, centres.last.dx, centres.last.dy,
          vx, vy, hw, hl, col, alpha);
    }
  }

  void _drawGradientPath(Canvas canvas, Path path, Color col, double alpha,
      double strokeWidth, double? blurSigma) {
    Paint makeP(Color c) => Paint()
      ..color = c
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = blurSigma != null
          ? MaskFilter.blur(BlurStyle.normal, blurSigma)
          : null;

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
        canvas.drawPath(
            metric.extractPath(from, to), makeP(Color.lerp(base, base, frac)!));
      }
      traveled += segLen;
    }
  }

  void _drawHead(Canvas canvas, double hx, double hy, double vx, double vy,
      double hw, double hl, Color col, double alpha) {
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

  void _drawImpactBurst(
      Canvas canvas, Offset centre, Color col, double progress) {
    const rays = 6;
    final len = cellSize * 0.9 * progress;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = col.withAlpha((alpha * 255).round())
      ..strokeWidth = max(1.5, cellSize * 0.05)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rays; i++) {
      final angle = 2 * pi * i / rays;
      canvas.drawLine(
          centre, centre + Offset(cos(angle) * len, sin(angle) * len), paint);
    }
  }

  /// Mirrors [BoardPainter._posOnPath]: fractional position along [cells]
  /// extended past the last cell in [direction].
  Offset _posOnPath(List<Position> cells, Direction direction, double s) {
    final n = cells.length;
    if (s <= 0) return Offset(cells[0].x.toDouble(), cells[0].y.toDouble());
    if (s >= n - 1) {
      final last = cells[n - 1];
      final over = s - (n - 1);
      return Offset(last.x + direction.dx * over, last.y + direction.dy * over);
    }
    final i = s.floor();
    final f = s - i;
    return Offset(
      cells[i].x + (cells[i + 1].x - cells[i].x) * f,
      cells[i].y + (cells[i + 1].y - cells[i].y) * f,
    );
  }

  @override
  bool shouldRepaint(LayerBoardPainter old) =>
      old.board != board ||
      old.flashMap != flashMap ||
      old.exitingArrows != exitingArrows ||
      old.highlightArrowId != highlightArrowId ||
      old.highlightPulse != highlightPulse ||
      old.gridOverlayOpacity != gridOverlayOpacity ||
      old.smashingArrows != smashingArrows;
}
