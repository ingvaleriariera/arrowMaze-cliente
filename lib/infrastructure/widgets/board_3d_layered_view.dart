import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_painter.dart'
    show ExitingArrowAnim, FlashType, SmashingArrowAnim;
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/layer_board_painter.dart';

/// True 3D renderer for a multi-layer game board.
///
/// Unlike the snapshot-based [Board3DViewport] (which applies a perspective
/// matrix to a single flat image), this widget positions each Z layer as an
/// independent [CustomPaint] at a distinct physical depth in 3D space:
///
/// ```
/// Camera
///   │  z=3 layer  ←  closest, physicalGap=0
///   │  z=2 layer  ←  physicalGap × 1
///   │  z=1 layer  ←  physicalGap × 2
///   └  z=0 layer  ←  furthest,  physicalGap × maxZ
/// ```
///
/// Because the depth is real — each canvas IS at a different Z — rotating
/// the board always reveals the actual volumetric structure. There is no
/// viewing angle at which the board collapses to a flat image.
///
/// Usage: swap in for `Board3DViewport(child: …)` when both `game3DEnabled`
/// (4-layer board) and `board3DEnabled` (perspective view) are active.
class Board3DLayeredView extends StatefulWidget {
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

  /// Called when the user taps a cell that contains an arrow.
  /// The caller (GameScreen) receives the arrow ID and applies game logic
  /// (normal activation, hammer targeting, etc.).
  final void Function(String arrowId) onArrowTapped;

  const Board3DLayeredView({
    required this.board,
    required this.activatableArrows,
    required this.flashMap,
    required this.cellSize,
    required this.minX,
    required this.minY,
    required this.cols,
    required this.rows,
    required this.onArrowTapped,
    this.exitingArrows,
    this.highlightArrowId,
    this.highlightPulse = 0,
    this.gridOverlayOpacity = 0,
    this.smashingArrows,
    super.key,
  });

  @override
  State<Board3DLayeredView> createState() => _Board3DLayeredViewState();
}

class _Board3DLayeredViewState extends State<Board3DLayeredView> {
  /// Slight top-down angle so the board reads as "a table in front of you"
  /// from the first frame.
  static const double _defaultTiltX = 0.40;

  double _rotX = _defaultTiltX;
  double _rotY = 0.0;

  /// Physical distance between consecutive layers in logical pixels.
  /// 1.2 × cellSize gives a clearly fat appearance when rotated while
  /// keeping the overall stack compact enough to read the arrows.
  double get _layerGap => widget.cellSize * 1.2;

  /// Perspective strength.  0.0015 balances visible foreshortening against
  /// readability: the back layer (z=0) appears about 80% of the front
  /// layer's (z=maxZ) apparent size for a typical 4-layer board.
  static const double _perspF = 0.0015;

  @override
  Widget build(BuildContext context) {
    final maxZ = widget.board.shape.maxZ();
    final w = widget.cols * widget.cellSize;
    final h = widget.rows * widget.cellSize;

    return GestureDetector(
      // One-finger drag rotates the board.
      onPanUpdate: (d) => setState(() {
        _rotY += d.delta.dx * 0.01;
        _rotX = (_rotX + d.delta.dy * 0.008).clamp(-pi, pi);
      }),
      // Long-press snaps back to the resting pose.
      onLongPress: () => setState(() {
        _rotX = _defaultTiltX;
        _rotY = 0;
      }),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, _perspF) // perspective term
          ..rotateX(_rotX)
          ..rotateY(_rotY),
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              // Layers rendered back→front so upper floors paint over lower
              // ones where they overlap in screen space.
              for (int z = 0; z <= maxZ; z++)
                Transform(
                  // z=0  → furthest from camera: translateZ = maxZ * gap
                  // z=mz → closest to camera:    translateZ = 0
                  // (In Flutter +Z goes INTO the screen with perspective > 0,
                  //  so larger translateZ = further away / appears smaller.)
                  transform:
                      Matrix4.translationValues(0, 0, (maxZ - z) * _layerGap),
                  child: RepaintBoundary(
                    // RepaintBoundary lets Flutter cache each layer's GPU
                    // texture independently.  Rotation only changes the
                    // parent Transform → Flutter repositions the cached
                    // textures without re-running the painter.  Layers
                    // re-render only when their board state actually changes.
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (d) => _onLayerTap(d.localPosition, z),
                      child: CustomPaint(
                        painter: LayerBoardPainter(
                          board: widget.board,
                          targetZ: z,
                          maxZ: maxZ,
                          activatableArrows: widget.activatableArrows,
                          flashMap: widget.flashMap,
                          cellSize: widget.cellSize,
                          minX: widget.minX,
                          minY: widget.minY,
                          exitingArrows: widget.exitingArrows,
                          highlightArrowId: widget.highlightArrowId,
                          highlightPulse: widget.highlightPulse,
                          gridOverlayOpacity: widget.gridOverlayOpacity,
                          smashingArrows: widget.smashingArrows,
                        ),
                        size: Size(w, h),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hit-test a tap at [local] on layer [z].
  ///
  /// Because this [GestureDetector] lives INSIDE the parent [Transform],
  /// Flutter automatically applies the inverse of the perspective+rotation
  /// matrix when routing pointer events, so [local] is already in the flat
  /// coordinate space of this layer's canvas — no manual un-projection
  /// needed.
  void _onLayerTap(Offset local, int z) {
    final gx = (local.dx / widget.cellSize).floor() + widget.minX;
    final gy = (local.dy / widget.cellSize).floor() + widget.minY;
    final pos = Position(gx, gy, z);
    final arrowId = widget.board.grid[pos.toKey()];
    debugPrint('🎯 3D layer $z tap ($gx,$gy) → $arrowId');
    if (arrowId != null) widget.onArrowTapped(arrowId);
  }
}
