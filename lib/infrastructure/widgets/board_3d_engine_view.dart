import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:ditredi/ditredi.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_painter.dart' show ExitingArrowAnim, FlashType, SmashingArrowAnim;

class Board3DEngineView extends StatefulWidget {
  final Board board;
  final Set<String> activatableArrows;
  final Function(String) onArrowTapped;
  final int cols;
  final int rows;
  final List<ExitingArrowAnim> exitingArrows;
  final Map<String, FlashType> flashMap;

  /// Hint power-up target + pulse (0..1), mirrors BoardPainter's fields.
  final String? highlightArrowId;
  final double highlightPulse;

  /// Grid power-up fade (0..1): draws a faint line from every arrow's head
  /// to its exit point, same distance BoardPainter's exit lines use.
  final double gridOverlayOpacity;

  /// Hammer power-up: arrows shrinking/fading in place, snapshotted before
  /// removal — same pattern as [exitingArrows].
  final List<SmashingArrowAnim> smashingArrows;

  const Board3DEngineView({
    Key? key,
    required this.board,
    required this.activatableArrows,
    required this.onArrowTapped,
    required this.cols,
    required this.rows,
    this.exitingArrows = const [],
    this.flashMap = const {},
    this.highlightArrowId,
    this.highlightPulse = 0,
    this.gridOverlayOpacity = 0,
    this.smashingArrows = const [],
  }) : super(key: key);

  @override
  State<Board3DEngineView> createState() => _Board3DEngineViewState();
}

class _Board3DEngineViewState extends State<Board3DEngineView> {
  late DiTreDiController _controller;
  final double cellSize = 2.0;

  final Map<String, vector.Vector3> _arrowHeadPositions = {};

  // Cache for the normal (non-animating) arrows' geometry. board_3d's per-
  // frame cost used to be dominated by re-running _smoothPath's Bezier
  // subdivision for every arrow on every rebuild — including rebuilds
  // that only exist because a hint pulse/grid overlay/exit animation
  // ticked, where nothing about the arrows themselves changed. Reusing
  // this list on those ticks and only rebuilding it when the board or
  // flash colors actually change turns an O(arrows x frame) cost back
  // into O(arrows x real update) — the fix that made boards with many
  // corners (e.g. level 3's concave cross shape) stop stalling once the
  // curve-smoothing subdivision count went up to close rendering gaps.
  List<Model3D>? _cachedStaticFigures;
  Board? _cachedBoard;
  Map<String, FlashType>? _cachedFlashMap;

  // Holds the same figures as _cachedStaticFigures, but as a ValueNotifier
  // consumed by its own ValueListenableBuilder further down — so the ~5000
  // static Model3D list is only rebuilt into a fresh DiTreDi/CanvasModelPainter
  // on an actual cache miss (a real board change), not on every one of the
  // ~2000+ animation-frame rebuilds a single level can trigger (hint pulse,
  // grid overlay fade, exit/smash animations). Before this split, every one
  // of those frames re-copied and re-painted the entire static figure list
  // regardless of whether anything in it changed, which is what was piling
  // up enough per-frame garbage to OOM-crash large boards (level 3+) on both
  // iOS and web after enough elapsed animation time.
  final ValueNotifier<List<Model3D>> _staticFiguresNotifier = ValueNotifier(const []);
  // Hammer/Magnet remove arrows straight from `board` without ever
  // touching flashMap (GameNotifier.usePowerUp doesn't set any flash
  // color), and `board` itself is mutated in place rather than replaced —
  // so neither of the two checks above would notice those removals on
  // their own. Arrow count catches every mutator Board actually exposes
  // (removeArrow/forceRemoveArrow), since nothing in this codebase edits
  // an arrow in place without removing it first.
  int _cachedArrowCount = -1;

  @override
  void initState() {
    super.initState();
    _controller = DiTreDiController(
      rotationX: -20,
      rotationY: -30,
      userScale: 3.0,
      minUserScale: 0.05,
      maxUserScale: 100.0,
      light: vector.Vector3(0, 1, 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _staticFiguresNotifier.dispose();
    super.dispose();
  }

  // Smooths a path by replacing 90-degree corners with rounded curves
  List<vector.Vector3> _smoothPath(List<vector.Vector3> points) {
    if (points.length <= 2) return points;
    
    final smoothed = <vector.Vector3>[];
    smoothed.add(points.first);
    
    // Small radius → straight segments with tight rounded corners,
    // like a rectangle with rounded edges, not a swooping curve.
    final double cornerRadius = 0.15 * cellSize;
    
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];

      final dPrev = (prev - curr).normalized();
      final dNext = (next - curr).normalized();

      // Colinear points (prev/curr/next in a straight line — dPrev and
      // dNext point opposite each other) aren't a turn, so leave them
      // straight instead of rounding; only real corners get the curve.
      if ((dPrev + dNext).length2 < 1e-6) {
        smoothed.add(curr);
        continue;
      }

      final p1 = curr + (dPrev * cornerRadius);
      final p2 = curr + (dNext * cornerRadius);

      smoothed.add(p1);

      // Each pair of consecutive subdivision points is drawn as its own
      // flat quad (ditredi's Line3D has no mitered joints between
      // segments), so the angle between them leaves a small wedge-shaped
      // gap of background color at the joint — worse with fewer, wider
      // angle steps. 6 subdivisions keeps the exact same curve shape
      // (same cornerRadius) but shrinks that per-joint angle enough for
      // the gaps to be imperceptible, without making the corner itself
      // bigger, smaller, curvier or straighter. (Was 10 — cut back after
      // that turned out to be expensive enough, recomputed every single
      // animation frame with no caching, to visibly stall concave/many-
      // cornered boards like level 3's cross shape. See _buildScene's
      // static-figure cache for the other half of that fix.)
      for (int j = 1; j < 6; j++) {
        final t = j / 6.0;
        final invT = 1.0 - t;
        final curvePoint = (p1 * (invT * invT)) + (curr * (2 * invT * t)) + (p2 * (t * t));
        smoothed.add(curvePoint);
      }
      
      smoothed.add(p2);
    }
    
    smoothed.add(points.last);
    return smoothed;
  }

  vector.Vector3 _posToVec(double x, double y, double z) {
    final offsetX = -(widget.cols * cellSize) / 2;
    final offsetZ = -(widget.rows * cellSize) / 2;
    return vector.Vector3(
      x * cellSize + offsetX,
      z * cellSize * 1.5 + 0.1,
      y * cellSize + offsetZ,
    );
  }

  vector.Vector3 _getInterpPos(List<Position> cells, Direction dir, double s) {
    if (cells.isEmpty) return _posToVec(0, 0, 0);
    
    if (s <= 0) {
      return _posToVec(cells.first.x.toDouble(), cells.first.y.toDouble(), cells.first.z.toDouble());
    }
    if (s < cells.length - 1) {
      int idx = s.floor();
      double t = s - idx;
      final p1 = cells[idx];
      final p2 = cells[idx + 1];
      return _posToVec(
        p1.x + (p2.x - p1.x) * t,
        p1.y + (p2.y - p1.y) * t,
        p1.z + (p2.z - p1.z) * t,
      );
    }
    
    // Extrapolate beyond the end
    double overshoot = s - (cells.length - 1);
    final last = cells.last;
    return _posToVec(
      last.x + dir.dx * overshoot,
      last.y + dir.dy * overshoot,
      last.z + dir.dz * overshoot,
    );
  }

  void _drawArrowModel(List<Model3D> models, List<vector.Vector3> rawPoints, Color arrowColor, Direction dir, {String? hitTestId, double scale = 1.0}) {
    if (rawPoints.isEmpty) return;

    // Add a neck for single-cell arrows
    if (rawPoints.length == 1) {
      final headPos = rawPoints.first;
      final tailPos = headPos - vector.Vector3(dir.dx.toDouble(), dir.dz.toDouble() * 1.5, dir.dy.toDouble()) * cellSize * 0.8;
      rawPoints.insert(0, tailPos);
    }

    final pathPoints = _smoothPath(rawPoints);

    final currentHeadPos = pathPoints.last;
    vector.Vector3 currentDir = vector.Vector3(-dir.dx.toDouble(), -dir.dz.toDouble(), -dir.dy.toDouble()).normalized();
    if (pathPoints.length > 1) {
      final prev = pathPoints[pathPoints.length - 2];
      currentDir = (prev - currentHeadPos).normalized();
    }

    if (hitTestId != null) {
      _arrowHeadPositions[hitTestId] = currentHeadPos;
    }

    // Draw 3D Pyramid for the head
    final headSize = 0.7 * scale;
    final baseCenter = currentHeadPos + (currentDir * headSize);

    // Body lines stop at the pyramid's base, not the tip — otherwise the
    // neck's own width pokes straight through the sharp point and reads
    // as a little square nub sticking out of it.
    for (int i = 0; i < pathPoints.length - 2; i++) {
      models.add(Line3D(pathPoints[i], pathPoints[i+1], width: 4.0, color: arrowColor));
    }
    if (pathPoints.length > 1) {
      models.add(Line3D(pathPoints[pathPoints.length - 2], baseCenter, width: 4.0, color: arrowColor));
    }

    vector.Vector3 up = vector.Vector3(0, 1, 0);
    if (currentDir.x == 0 && currentDir.z == 0) {
      up = vector.Vector3(1, 0, 0);
    }

    final right = currentDir.cross(up).normalized();
    final realUp = right.cross(currentDir).normalized();

    final radius = 0.5 * headSize;
    // 4 corners of the pyramid base
    final b1 = baseCenter + right * radius;
    final b2 = baseCenter - right * radius;
    final b3 = baseCenter + realUp * radius;
    final b4 = baseCenter - realUp * radius;

    // Draw 4 faces of the pyramid
    models.add(Face3D(vector.Triangle.points(currentHeadPos, b1, b3), color: arrowColor));
    models.add(Face3D(vector.Triangle.points(currentHeadPos, b3, b2), color: arrowColor));
    models.add(Face3D(vector.Triangle.points(currentHeadPos, b2, b4), color: arrowColor));
    models.add(Face3D(vector.Triangle.points(currentHeadPos, b4, b1), color: arrowColor));

    // Draw the base (2 triangles) to close the pyramid
    models.add(Face3D(vector.Triangle.points(b1, b2, b3), color: arrowColor));
    models.add(Face3D(vector.Triangle.points(b1, b4, b2), color: arrowColor));
  }

  static const Color _hintColor = Color(0xFFFFD700);

  /// All 6 axis directions plus the 8 cube-diagonal directions — a denser
  /// starburst reads as a glowing spark even at a glance, where a plain
  /// 6-line cross was easy to lose among the other floating arrows.
  static final List<vector.Vector3> _starburstAxes = [
    vector.Vector3(1, 0, 0), vector.Vector3(-1, 0, 0),
    vector.Vector3(0, 1, 0), vector.Vector3(0, -1, 0),
    vector.Vector3(0, 0, 1), vector.Vector3(0, 0, -1),
    vector.Vector3(1, 1, 1).normalized(), vector.Vector3(-1, 1, 1).normalized(),
    vector.Vector3(1, -1, 1).normalized(), vector.Vector3(-1, -1, 1).normalized(),
    vector.Vector3(1, 1, -1).normalized(), vector.Vector3(-1, 1, -1).normalized(),
    vector.Vector3(1, -1, -1).normalized(), vector.Vector3(-1, -1, -1).normalized(),
  ];

  /// Hint power-up: a glowing overlay traced over the target arrow's
  /// entire body (so it reads clearly even in a cluttered scene, not just
  /// a small marker at the tip) plus a pulsing starburst at its head.
  /// [bodyPoints] are the raw (pre-smoothing) points of the same arrow
  /// drawn earlier this frame in [_buildScene].
  void _drawHintGizmo(List<Model3D> models, List<vector.Vector3>? bodyPoints) {
    final id = widget.highlightArrowId;
    if (id == null) return;
    final center = _arrowHeadPositions[id];
    if (center == null) return;

    final pulse = widget.highlightPulse;

    if (bodyPoints != null && bodyPoints.length > 1) {
      final glowWidth = 9.0 + 4.0 * pulse;
      final glowColor = _hintColor.withAlpha((130 + 90 * pulse).round());
      final smoothed = _smoothPath(List<vector.Vector3>.from(bodyPoints));
      for (int i = 0; i < smoothed.length - 1; i++) {
        models.add(Line3D(smoothed[i], smoothed[i + 1], width: glowWidth, color: glowColor));
      }
    }

    final len = cellSize * (0.55 + 0.3 * pulse);
    final rayColor = _hintColor.withAlpha((200 + 55 * pulse).round());
    for (final axis in _starburstAxes) {
      models.add(Line3D(center, center + axis * len, width: 4.0, color: rayColor));
    }
  }

  /// Grid power-up: a faint line from every arrow's head to the cell
  /// where it would exit, same distance [Board.shape.distanceToExit]
  /// gives the 2D exit animation.
  void _drawExitLines(List<Model3D> models) {
    if (widget.gridOverlayOpacity <= 0) return;

    for (final arrow in widget.board.arrows.values) {
      final colorValue = int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) | 0xFF000000;
      final arrowColor = Color(colorValue)
          .withAlpha((widget.gridOverlayOpacity * 200).round());
      final head = arrow.getHead().position;
      final dir = arrow.getDirection();
      final distance = widget.board.shape.distanceToExit(head, dir);
      if (distance <= 0) continue;

      final start = _posToVec(head.x.toDouble(), head.y.toDouble(), head.z.toDouble());
      final end = _posToVec(
        (head.x + dir.dx * distance).toDouble(),
        (head.y + dir.dy * distance).toDouble(),
        (head.z + dir.dz * distance).toDouble(),
      );
      models.add(Line3D(start, end, width: 2.5, color: arrowColor));
    }
  }

  /// Hammer power-up: shrinks each smashed arrow toward its own centroid
  /// as it fades, plus a small radiating burst at the point of impact.
  void _drawSmashingArrows(List<Model3D> models) {
    for (final smash in widget.smashingArrows) {
      final colorValue = int.parse(smash.color.replaceFirst('#', ''), radix: 16) | 0xFF000000;
      final baseColor = Color(colorValue);
      final scale = (1 - smash.progress).clamp(0.0, 1.0);
      if (scale <= 0) continue;

      final points = smash.cells
          .map((p) => _posToVec(p.x.toDouble(), p.y.toDouble(), p.z.toDouble()))
          .toList();
      final centroid = points.reduce((a, b) => a + b) / points.length.toDouble();
      final shrunk = points.map((p) => centroid + (p - centroid) * scale).toList();

      _drawArrowModel(models, shrunk, baseColor, smash.direction, scale: scale);

      final burstColor = baseColor.withAlpha(((1 - smash.progress) * 255).round());
      final burstLen = cellSize * 0.9 * smash.progress;
      const rays = 6;
      for (int i = 0; i < rays; i++) {
        final angle = 2 * pi * i / rays;
        final offset = vector.Vector3(cos(angle), 0, sin(angle)) * burstLen;
        models.add(Line3D(centroid, centroid + offset, width: 2.5, color: burstColor));
      }
    }
  }

  /// The expensive part: builds every normal arrow's smoothed body/head
  /// geometry from scratch. Only called when the board or flash colors
  /// actually changed — see [_buildScene]'s cache check.
  List<Model3D> _buildStaticFigures() {
    final models = <Model3D>[];
    _arrowHeadPositions.clear();

    for (final entry in widget.board.arrows.entries) {
      final arrowId = entry.key;
      final arrow = entry.value;

      final colorValue = int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) | 0xFF000000;
      final baseColor = Color(colorValue);
      final flash = widget.flashMap[arrowId];
      final arrowColor = flash == FlashType.fail
          ? const Color(0xFFFF3366)
          : flash == FlashType.ok
              ? const Color(0xFF00F5A0)
              : baseColor;
      final dir = arrow.getDirection();

      List<vector.Vector3> rawPoints = [];
      for (final seg in arrow.segments) {
        rawPoints.add(_posToVec(seg.position.x.toDouble(), seg.position.y.toDouble(), seg.position.z.toDouble()));
      }

      _drawArrowModel(models, rawPoints, arrowColor, dir, hitTestId: arrowId);
    }

    return models;
  }

  /// Cheap re-derivation of the hinted arrow's raw (pre-smoothing) points
  /// from the board directly — used on cache hits, where [_buildStaticFigures]
  /// didn't run this frame so it never captured them.
  List<vector.Vector3>? _highlightBodyPoints() {
    final id = widget.highlightArrowId;
    if (id == null) return null;
    final arrow = widget.board.arrows[id];
    if (arrow == null) return null;
    return arrow.segments
        .map((s) => _posToVec(s.position.x.toDouble(), s.position.y.toDouble(), s.position.z.toDouble()))
        .toList();
  }

  /// Rebuilds the static figure list and pushes it into [_staticFiguresNotifier]
  /// only when the board/flash/arrow-count cache key actually changed —
  /// otherwise leaves the notifier (and the ValueListenableBuilder consuming
  /// it in [build]) completely untouched, so no repaint of the ~5000-model
  /// static layer happens on frames where nothing about the board changed.
  /// Returns the hinted arrow's raw body points either way, since the hint
  /// gizmo itself is part of the dynamic layer and needs them every frame.
  List<vector.Vector3>? _refreshStaticFiguresIfNeeded() {
    final cacheHit = _cachedStaticFigures != null &&
        identical(widget.board, _cachedBoard) &&
        identical(widget.flashMap, _cachedFlashMap) &&
        widget.board.arrows.length == _cachedArrowCount;

    if (cacheHit) {
      return _highlightBodyPoints();
    }

    final staticFigures = _buildStaticFigures();
    _cachedStaticFigures = staticFigures;
    _cachedBoard = widget.board;
    _cachedFlashMap = widget.flashMap;
    _cachedArrowCount = widget.board.arrows.length;
    _staticFiguresNotifier.value = staticFigures;
    return widget.highlightArrowId != null ? _highlightBodyPoints() : null;
  }

  /// Builds only the DYNAMIC layer (exiting/smashing arrows, hint gizmo,
  /// grid overlay lines) — the handful of models that actually change
  /// every animation frame. The static ~5000-model board layer is handled
  /// separately by [_refreshStaticFiguresIfNeeded] + [_staticFiguresNotifier]
  /// so it isn't rebuilt on frames where nothing about the board changed.
  List<Model3D> _buildScene() {
    final highlightBodyPoints = _refreshStaticFiguresIfNeeded();

    final models = <Model3D>[];

    // Exiting arrows (Animation)
    for (final exiting in widget.exitingArrows) {
      final colorValue = int.parse(exiting.color.replaceFirst('#', ''), radix: 16) | 0xFF000000;
      final arrowColor = Color(colorValue);
      final dir = exiting.direction;

      final n = exiting.cells.length;
      final totalDistance = exiting.edgeDistance + n;
      final headTravel = exiting.progress * totalDistance;

      // The snake moves forward. The tail is at s = headTravel, the head is at s = n - 1 + headTravel
      List<vector.Vector3> rawPoints = [];
      // Generate points along the snake body
      for (double i = 0; i < n; i++) {
        final s = i + headTravel;
        rawPoints.add(_getInterpPos(exiting.cells, dir, s));
      }

      _drawArrowModel(models, rawPoints, arrowColor, dir);
    }

    _drawSmashingArrows(models);
    _drawExitLines(models);
    _drawHintGizmo(models, highlightBodyPoints);

    return models;
  }

  void _handleTap(Offset localPosition, Size canvasSize) {
    final scale = _controller.scale;

    // Mirrors CanvasModelPainter.paint's matrix exactly (see
    // third_party/ditredi/lib/src/painter/canvas_model_painter.dart) —
    // including the perspective row, which the previous version of this
    // method omitted. DiTreDiConfig.perspective defaults to true, and
    // ditredi's own per-vertex painters project with
    // Matrix4.perspectiveTransform (divides x/y by the transformed w),
    // not the plain affine Matrix4.transform3 this method used before.
    // Skipping that division meant the hit-test position silently drifted
    // away from the arrow's actual on-screen position as it moved off
    // dead-center or the camera rotated — the tap target and the visible
    // arrowhead were never quite the same point, which is what made
    // clicks feel like they needed to land "a bit above" or "to the side",
    // and made tapping more reliable dead-on the head where the drift is
    // smallest. Our board's `bounds` is always centered at the origin
    // (see build()'s `Aabb3.centerAndHalfExtents(Vector3.zero(), ...)`),
    // so the bounds-center translate terms in the original cancel out and
    // are omitted here rather than duplicated.
    final matrix = vector.Matrix4.identity();
    matrix.setEntry(3, 2, -0.001);
    matrix
      ..translate(_controller.translation.dx, _controller.translation.dy, 0.0)
      ..scale(scale, -scale, -scale)
      ..rotateX(vector.radians(_controller.rotationX))
      ..rotateY(vector.radians(_controller.rotationY))
      ..rotateZ(vector.radians(_controller.rotationZ));

    String? closestArrowId;
    double minDistanceSq = double.infinity;
    final double thresholdSq = 40.0 * 40.0;

    for (final entry in _arrowHeadPositions.entries) {
      final pos3D = entry.value.clone();
      matrix.perspectiveTransform(pos3D);

      final screenX = canvasSize.width / 2 + pos3D.x;
      final screenY = canvasSize.height / 2 + pos3D.y;

      final dx = screenX - localPosition.dx;
      final dy = screenY - localPosition.dy;
      final distSq = dx * dx + dy * dy;

      if (distSq < minDistanceSq && distSq < thresholdSq) {
        minDistanceSq = distSq;
        closestArrowId = entry.key;
      }
    }

    if (closestArrowId != null) {
      widget.onArrowTapped(closestArrowId);
    }
  }

  var _lastX = 0.0;
  var _lastY = 0.0;
  var _scaleBase = 0.0;

  void _handleScaleStart(ScaleStartDetails details) {
    _scaleBase = _controller.userScale;
    _lastX = details.localFocalPoint.dx;
    _lastY = details.localFocalPoint.dy;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final dx = details.localFocalPoint.dx - _lastX;
    final dy = details.localFocalPoint.dy - _lastY;

    _lastX = details.localFocalPoint.dx;
    _lastY = details.localFocalPoint.dy;

    _controller.update(
      userScale: _scaleBase * details.scale,
      rotationX: _controller.rotationX - dy / 2,
      rotationY: (_controller.rotationY - dx / 2 + 360) % 360,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              final scaledDy = pointerSignal.scrollDelta.dy / _controller.viewScale;
              _controller.update(
                userScale: _controller.userScale - scaledDy,
              );
            }
          },
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details.localPosition, size),
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: Stack(
              children: [
                // Static layer: the board's ~thousands of non-animating
                // arrow models. ValueListenableBuilder only rebuilds this
                // DiTreDi (and its CanvasModelPainter) when
                // _staticFiguresNotifier's value actually changes — i.e. on
                // a real cache miss — instead of on every animation frame.
                ValueListenableBuilder<List<Model3D>>(
                  valueListenable: _staticFiguresNotifier,
                  builder: (context, staticFigures, _) {
                    return DiTreDi(
                      figures: staticFigures,
                      controller: _controller,
                      bounds: vector.Aabb3.centerAndHalfExtents(
                        vector.Vector3.zero(), vector.Vector3.all(100),
                      ),
                    );
                  },
                ),
                // Dynamic layer: exiting/smashing arrows, hint gizmo, grid
                // overlay lines — a handful of models, rebuilt every frame
                // like before.
                DiTreDi(
                  figures: _buildScene(),
                  controller: _controller,
                  bounds: vector.Aabb3.centerAndHalfExtents(
                     vector.Vector3.zero(), vector.Vector3.all(100)
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
