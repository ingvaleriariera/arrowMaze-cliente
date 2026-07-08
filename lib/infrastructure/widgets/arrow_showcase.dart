import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/arrow_painter.dart';

/// Same hex order as `BoardBuilder._getColorForIndex`, so the decorative
/// arrows here read as the same "family" as the ones players see in-game.
const _showcaseColors = [
  Color(0xFF00F5A0),
  Color(0xFF0088FF),
  Color(0xFFFF3366),
  Color(0xFFFFB800),
  Color(0xFFCC44FF),
  Color(0xFF00DDFF),
];

/// A handful of different-sized arrows in different arrow directions,
/// each with its own phase and speed, so they never move in lockstep.
const _arrowSizes = [22.0, 40.0, 30.0, 48.0, 26.0, 36.0];

/// Purely decorative backdrop for the Home screen's play button: the
/// game's own arrows drifting slowly across the lane. Tapping one (or
/// tapping anywhere in the lane) jumps straight into the current level,
/// same as the play button below it.
class ArrowShowcase extends StatefulWidget {
  final VoidCallback onTap;

  const ArrowShowcase({required this.onTap, super.key});

  @override
  State<ArrowShowcase> createState() => _ArrowShowcaseState();
}

class _ArrowShowcaseState extends State<ArrowShowcase> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 16),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.translucent,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Stack(
                  children: List.generate(_showcaseColors.length, (i) {
                    final arrowSize = _arrowSizes[i % _arrowSizes.length];
                    // Slightly different speeds per arrow (via a per-arrow
                    // multiplier on the shared clock) so the lane feels
                    // organic instead of a single rigid conveyor belt.
                    final speed = 0.7 + (i % 3) * 0.2;
                    final phase = i / _showcaseColors.length;
                    final t = (_controller.value * speed + phase) % 1.0;
                    final laneWidth = constraints.maxWidth + arrowSize * 2;
                    final left = t * laneWidth - arrowSize;
                    final wobble = math.sin((t + phase) * 2 * math.pi * 2) * 10;
                    final baseTop = (constraints.maxHeight - arrowSize) / 2 + (i.isEven ? -14 : 14);

                    return Positioned(
                      left: left,
                      top: baseTop + wobble,
                      child: SizedBox(
                        width: arrowSize,
                        height: arrowSize,
                        child: CustomPaint(
                          painter: ArrowPainter(
                            direction: Direction.right,
                            color: _showcaseColors[i],
                            cellSize: arrowSize,
                            isActivatable: true,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
