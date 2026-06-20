import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de derrota.
class DefeatScreen extends StatefulWidget {
  final int score;
  final String levelId;

  const DefeatScreen({super.key, required this.score, required this.levelId});

  @override
  State<DefeatScreen> createState() => _DefeatScreenState();
}

class _DefeatScreenState extends State<DefeatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080812),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FAIL título con shake
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              ),
              child: const Text(
                'FAIL',
                style: TextStyle(
                  color: Color(0xFFFF3366),
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'SIN MOVIMIENTOS',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 11,
                letterSpacing: 3,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 32),

            // Score
            Text(
              '${widget.score}',
              style: const TextStyle(
                color: Color(0xFFFF3366),
                fontSize: 64,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'PUNTOS',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 10,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 48),

            // Reintentar
            _FailButton(
              label: 'REINTENTAR ↺',
              color: const Color(0xFFFF3366),
              onTap: () {
                context.go('/game/${widget.levelId}');
              },
            ),
            const SizedBox(height: 16),

            // Menú
            TextButton(
              onPressed: () => context.go('/levels'),
              child: const Text(
                'MENÚ',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FailButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
