import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de victoria.
class VictoryScreen extends StatefulWidget {
  final int score;
  final String levelId;

  const VictoryScreen({super.key, required this.score, required this.levelId});

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título CLEAR!
              ScaleTransition(
                scale: _scaleAnim,
                child: const Text(
                  'CLEAR!',
                  style: TextStyle(
                    color: Color(0xFF00F5A0),
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'BOARD CLEARED',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 11,
                  letterSpacing: 3,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 32),

              // Score
              ScaleTransition(
                scale: _scaleAnim,
                child: Text(
                  '${widget.score}',
                  style: const TextStyle(
                    color: Color(0xFF00F5A0),
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
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

              // Botón siguiente nivel
              _NeonButton(
                label: 'SIGUIENTE →',
                color: const Color(0xFF00F5A0),
                onTap: () => context.go('/levels'),
              ),
              const SizedBox(height: 16),

              // Leaderboard
              _NeonButton(
                label: '🏆 RANKING',
                color: const Color(0xFF00DDFF),
                onTap: () => context.push('/leaderboard/${widget.levelId}'),
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
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NeonButton({required this.label, required this.color, required this.onTap});

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
