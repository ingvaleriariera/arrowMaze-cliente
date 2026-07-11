import 'package:flutter/material.dart';

/// Presentation-layer strategy for how the board is shown: when [enabled],
/// the (unchanged) 2D-painted board is projected in perspective like a
/// physical table the player can tilt and spin with one finger; when
/// disabled it renders the child untouched, exactly as before.
///
/// Deliberately knows nothing about Board/GameSession — it transforms
/// whatever child it's given. Taps keep landing on the right cells in both
/// modes because Flutter routes pointer events through the inverse of
/// ancestor transforms (perspective included), so the tap handler inside
/// still receives coordinates in flat board space.
class Board3DViewport extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const Board3DViewport({required this.enabled, required this.child, super.key});

  @override
  State<Board3DViewport> createState() => _Board3DViewportState();
}

class _Board3DViewportState extends State<Board3DViewport> {
  // Resting pose: enough tilt to read as "a table in front of you"
  // without foreshortening the far rows into unreadability.
  static const double _defaultTilt = 0.55;

  // Rotations are clamped short of edge-on (~72°). Beyond that the board
  // is unreadable anyway, and blur effects rasterized under near-singular
  // perspective allocate enormous offscreen buffers — steep angles are
  // exactly where big boards (level 15) used to freeze the raster thread.
  static const double _maxAngle = 1.25;

  // In 3D mode the board is ALWAYS shown as a
  // flat-rasterized GPU image, and the perspective transform is applied
  // to that image. This is the load-bearing design decision: expensive
  // paint effects (the blur glows on ~116 arrows in level 15) are only
  // ever rasterized in flat space — the same cost as 2D mode, which every
  // device already handles — and never through a perspective matrix,
  // where their offscreen buffers blow up and wedge the raster thread.
  // The snapshot is refreshed (cleared) whenever the parent rebuilds the
  // board (moves, flashes, timer ticks, exit animations), so gameplay
  // feedback stays live; pure rotation reuses the cached image untouched.
  final SnapshotController _snapshotController = SnapshotController();

  double _rotationX = _defaultTilt;
  double _rotationY = 0;

  void _resetPose() {
    setState(() {
      _rotationX = _defaultTilt;
      _rotationY = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    _snapshotController.allowSnapshotting = widget.enabled;
  }

  @override
  void didUpdateWidget(Board3DViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    _snapshotController.allowSnapshotting = widget.enabled;
    // Re-entering 3D mode always starts from the readable resting pose,
    // not whatever orientation the board was abandoned in.
    if (widget.enabled && !oldWidget.enabled) {
      _rotationX = _defaultTilt;
      _rotationY = 0;
    }
    // The parent rebuilt us — the board content may have changed (a move,
    // a flash, a timer tick), so drop the cached image and re-rasterize
    // it flat on the next frame. Our own setState (rotation) doesn't come
    // through here, so dragging keeps reusing the cached image for free.
    if (widget.enabled) {
      _snapshotController.clear();
    }
  }

  @override
  void dispose() {
    _snapshotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      // Trackball-style handling of a physical object: horizontal drag
      // turns the board (Y axis), vertical drag tilts it toward/away
      // (X axis). Long-press snaps back to the resting pose. Taps are
      // untouched (they resolve deeper, on the cell tap handler), and
      // two-finger pinch still reaches the InteractiveViewer's zoom.
      onPanUpdate: (details) {
        setState(() {
          _rotationY =
              (_rotationY + details.delta.dx * 0.01).clamp(-_maxAngle, _maxAngle);
          _rotationX =
              (_rotationX + details.delta.dy * 0.008).clamp(-_maxAngle, _maxAngle);
        });
      },
      onLongPress: _resetPose,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          // Perspective term: gives depth to the rotations below. Small
          // values keep the far edge readable; 0 would be isometric.
          ..setEntry(3, 2, 0.0012)
          ..rotateX(_rotationX)
          ..rotateY(_rotationY),
        child: SnapshotWidget(
          controller: _snapshotController,
          mode: SnapshotMode.permissive,
          child: widget.child,
        ),
      ),
    );
  }
}
