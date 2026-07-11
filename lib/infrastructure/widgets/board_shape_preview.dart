import 'package:flutter/material.dart';

/// Tiny, cheap preview of a board SHAPE: active cells as bright dots,
/// inactive as faint ones. No arrows, no board generation — just the 0/1
/// grid, so lists of community boards stay light no matter how many
/// previews are on screen. Wrapped in a RepaintBoundary because the
/// content is static per board.
class BoardShapePreview extends StatelessWidget {
  final List<List<int>> grid;
  final double size;
  final Color activeColor;

  const BoardShapePreview({
    required this.grid,
    this.size = 56,
    this.activeColor = const Color(0xFF00F5A0),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF0d0d18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: _ShapeDotsPainter(grid: grid, activeColor: activeColor),
        ),
      ),
    );
  }
}

class _ShapeDotsPainter extends CustomPainter {
  final List<List<int>> grid;
  final Color activeColor;

  _ShapeDotsPainter({required this.grid, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty || grid.first.isEmpty) return;
    final rows = grid.length;
    final cols = grid.first.length;
    final cell = size.width < size.height ? size.width / cols : size.height / rows;
    final radius = (cell * 0.32).clamp(0.8, 4.0);

    final activePaint = Paint()..color = activeColor;
    final inactivePaint = Paint()..color = const Color(0xFF2A2A3E);

    // Center the grid inside the box for non-square shapes.
    final offsetX = (size.width - cell * cols) / 2;
    final offsetY = (size.height - cell * rows) / 2;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        final center = Offset(
          offsetX + (x + 0.5) * cell,
          offsetY + (y + 0.5) * cell,
        );
        canvas.drawCircle(
          center,
          radius,
          grid[y][x] == 1 ? activePaint : inactivePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ShapeDotsPainter oldDelegate) =>
      oldDelegate.grid != grid || oldDelegate.activeColor != activeColor;
}
