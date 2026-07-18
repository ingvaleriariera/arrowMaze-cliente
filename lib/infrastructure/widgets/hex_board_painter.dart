import 'dart:math';
import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/hex_projection.dart';

/// A snapshot of an arrow that just exited, plus enough geometry to slide
/// it off the board over the animation's lifetime — mirrors the real
/// BoardPainter's ExitingArrowAnim, coordinate-system-agnostic (Position
/// doesn't care whether it's square or axial-hex).
class HexExitingArrowAnim {
  final List<Position> cells;
  final Direction direction;
  final Color color;
  final int edgeDistance;
  final double progress;

  const HexExitingArrowAnim({
    required this.cells,
    required this.direction,
    required this.color,
    required this.edgeDistance,
    required this.progress,
  });
}

/// Draws a hexagonal board using the same visual language as
/// the real BoardPainter: a thin glowing body with rounded corners, a
/// proportional triangular head, a hint ring, grid-power-up exit lines,
/// and a worm-style exit animation. The hex cells themselves are drawn as
/// a faint translucent watermark behind everything else, instead of the
/// square board's small per-cell dots (a full hex outline reads better at
/// this cell size).
class HexBoardPainter extends CustomPainter {
  final Board board;
  final HexProjection projection;
  final Offset originOffset;
  final Set<String> activatableArrows;
  final List<HexExitingArrowAnim> exitingArrows;

  final String? highlightArrowId;
  final double highlightPulse;
  final double gridOverlayOpacity;

  /// arrowId -> override color for a brief flash (red = blocked tap).
  final Map<String, Color> flashOverrides;

  HexBoardPainter({
    required this.board,
    required this.projection,
    required this.originOffset,
    required this.activatableArrows,
    this.exitingArrows = const [],
    this.highlightArrowId,
    this.highlightPulse = 0,
    this.gridOverlayOpacity = 0,
    this.flashOverrides = const {},
  });

  Offset _toCanvas(Offset unbounded) => unbounded + originOffset;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCells(canvas);
    for (final arrow in board.arrows.values) {
      _drawArrow(canvas, arrow);
    }
    _drawExitingArrows(canvas);
    _drawHintRing(canvas);
    _drawExitLines(canvas);
  }

  void _drawCells(Canvas canvas) {
    // "Un poquito mas transparentes": low-alpha fill + faint border, so
    // the hex grid reads as a watermark behind the vivid arrows instead
    // of competing with them.
    final cellPaint = Paint()
      ..color = const Color(0xFF2a2a45).withAlpha(70)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF3d3d5c).withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final cell in board.shape.getCells()) {
      final center = _toCanvas(projection.centerOf(cell));
      final corners =
          projection.cornersOf(Offset.zero).map((c) => center + c).toList();
      final path = Path()..addPolygon(corners, true);
      canvas.drawPath(path, cellPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  void _drawArrow(Canvas canvas, Arrow arrow) {
    final override = flashOverrides[arrow.id];
    final baseColor = override ??
        Color(
          int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) |
              0xFF000000,
        );
    final isActivatable = activatableArrows.contains(arrow.id);
    final alpha = isActivatable ? 1.0 : 0.55;

    final centers = arrow.segments
        .map((s) => _toCanvas(projection.centerOf(s.position)))
        .toList();
    final direction = arrow.getDirection();
    final isHinted = arrow.id == highlightArrowId;
    final glowBoost = isHinted ? highlightPulse : 0.0;

    _drawArrowAtOffsets(canvas, centers, direction, baseColor, alpha, glowBoost: glowBoost);

    if (isActivatable) {
      final ring = Paint()
        ..color = Colors.white.withAlpha(140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(centers.first, projection.hexSize * 0.5, ring);
    }
  }

  /// Every exiting arrow slides along its own direction as a continuous
  /// worm: the tail catches up to where the head was, cell by cell, past
  /// the board's edge — same interpolation the real 3D/2D exit animations
  /// use, just fed through the hex projection instead.
  void _drawExitingArrows(Canvas canvas) {
    for (final exiting in exitingArrows) {
      final n = exiting.cells.length;
      final totalDistance = exiting.edgeDistance + n;
      final headTravel = exiting.progress * totalDistance;

      final centers = <Offset>[];
      for (int i = 0; i < n; i++) {
        final s = i + headTravel;
        centers.add(_toCanvas(_interpCenter(exiting.cells, exiting.direction, s)));
      }

      _drawArrowAtOffsets(canvas, centers, exiting.direction, exiting.color, 1.0);
    }
  }

  /// Position along a snake's path at fractional distance [s] (0 = tail's
  /// starting cell index, cells.length-1 = head's cell) — extrapolates
  /// past the last cell along [dir] once s overshoots it, which is how a
  /// fully-exited head keeps sliding off-canvas.
  Offset _interpCenter(List<Position> cells, Direction dir, double s) {
    if (s <= 0) {
      final first = cells.first;
      return projection.centerOfFractional(first.x.toDouble(), first.y.toDouble());
    }
    if (s < cells.length - 1) {
      final idx = s.floor();
      final t = s - idx;
      final p1 = cells[idx];
      final p2 = cells[idx + 1];
      return projection.centerOfFractional(
        p1.x + (p2.x - p1.x) * t,
        p1.y + (p2.y - p1.y) * t,
      );
    }
    final overshoot = s - (cells.length - 1);
    final last = cells.last;
    return projection.centerOfFractional(
      last.x + dir.dx * overshoot,
      last.y + dir.dy * overshoot,
    );
  }

  /// Shared body+head rendering for both a live arrow's real segments and
  /// an exiting arrow's interpolated ones — [centers] are already in
  /// canvas space.
  void _drawArrowAtOffsets(Canvas canvas, List<Offset> centers, Direction direction,
      Color col, double alpha, {double glowBoost = 0}) {
    if (centers.isEmpty) return;
    final vec = projection.screenVector(direction.dx, direction.dy);

    // SayGames-style slender body: thin stroke, head sized proportionally
    // to it — same ratios the real BoardPainter uses.
    final size = projection.hexSize;
    final bw = size * 0.16;
    final hw = bw * 3.2;
    final hl = bw * 4.2;
    final glowBlur = 10.0 + glowBoost * 20.0;
    final glowAlpha = (alpha * (0.55 + glowBoost * 0.4)).clamp(0.0, 1.0);

    if (centers.length == 1) {
      final c = centers[0];
      final start = c - vec * size * 0.55;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(c.dx, c.dy);
      _strokeGlow(canvas, path, col, glowAlpha, bw, glowBlur);
      _strokePath(canvas, path, col, alpha, bw);
      _drawHead(canvas, c, vec, hw, hl, col, alpha);
      return;
    }

    final r = size * 0.42;
    final path = Path()..moveTo(centers.first.dx, centers.first.dy);

    for (int i = 1; i < centers.length - 1; i++) {
      final prev = centers[i - 1];
      final curr = centers[i];
      final next = centers[i + 1];

      final inVec = curr - prev;
      final inLen = inVec.distance;
      final outVec = next - curr;
      final outLen = outVec.distance;
      final cr = min(r, min(inLen / 2, outLen / 2));

      final inUnit = inLen == 0 ? Offset.zero : inVec / inLen;
      final outUnit = outLen == 0 ? Offset.zero : outVec / outLen;

      path.lineTo(curr.dx - inUnit.dx * cr, curr.dy - inUnit.dy * cr);
      path.quadraticBezierTo(
          curr.dx, curr.dy, curr.dx + outUnit.dx * cr, curr.dy + outUnit.dy * cr);
    }

    path.lineTo(centers.last.dx, centers.last.dy);

    _strokeGlow(canvas, path, col, glowAlpha, bw, glowBlur);
    _strokePath(canvas, path, col, alpha, bw);
    _drawHead(canvas, centers.last, vec, hw, hl, col, alpha);
  }

  void _strokeGlow(Canvas canvas, Path path, Color col, double alpha,
      double strokeWidth, double blurSigma) {
    final paint = Paint()
      ..color = col.withAlpha((alpha * 255).round())
      ..strokeWidth = strokeWidth * 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawPath(path, paint);
  }

  void _strokePath(
      Canvas canvas, Path path, Color col, double alpha, double strokeWidth) {
    final paint = Paint()
      ..color = col.withAlpha((alpha * 255).round())
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  void _drawHead(Canvas canvas, Offset headCenter, Offset vec, double hw,
      double hl, Color col, double alpha) {
    final tip = headCenter + vec * hl * 0.65;
    final base = headCenter - vec * hl * 0.40;
    final perp = Offset(-vec.dy, vec.dx);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx * hw / 2, base.dy + perp.dy * hw / 2)
      ..lineTo(base.dx - perp.dx * hw / 2, base.dy - perp.dy * hw / 2)
      ..close();

    canvas.drawPath(path, Paint()..color = col.withAlpha((alpha * 255).round()));
  }

  /// Hint power-up: a bright ring around the suggested arrow's head.
  void _drawHintRing(Canvas canvas) {
    final id = highlightArrowId;
    if (id == null) return;
    final arrow = board.arrows[id];
    if (arrow == null) return;

    final center = _toCanvas(projection.centerOf(arrow.getHead().position));
    final radius = projection.hexSize * (0.6 + 0.2 * highlightPulse);
    final paint = Paint()
      ..color =
          const Color(0xFFFFD700).withAlpha((140 + 100 * highlightPulse).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, projection.hexSize * 0.1);

    canvas.drawCircle(center, radius, paint);
  }

  /// Grid power-up: a thin line from each arrow's head to where it would
  /// exit the board (board.shape.distanceToExit).
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

      final headCenter = _toCanvas(projection.centerOf(head));
      final exitPos = Position(
        head.x + direction.dx * distance,
        head.y + direction.dy * distance,
      );
      final exitCenter = _toCanvas(projection.centerOf(exitPos));
      final vec = projection.screenVector(direction.dx, direction.dy);
      final start = headCenter + vec * projection.hexSize * 0.4;

      final paint = Paint()
        ..color = color.withAlpha((gridOverlayOpacity * 200).round())
        ..strokeWidth = max(1.5, projection.hexSize * 0.06)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, exitCenter, paint);
    }
  }

  @override
  bool shouldRepaint(HexBoardPainter oldDelegate) =>
      oldDelegate.board != board ||
      oldDelegate.activatableArrows != activatableArrows ||
      oldDelegate.exitingArrows != exitingArrows ||
      oldDelegate.highlightArrowId != highlightArrowId ||
      oldDelegate.highlightPulse != highlightPulse ||
      oldDelegate.gridOverlayOpacity != gridOverlayOpacity ||
      oldDelegate.flashOverrides != flashOverrides;
}
