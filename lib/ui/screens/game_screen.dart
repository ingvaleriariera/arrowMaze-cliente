import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/state/defeat_state.dart';
import '../../domain/state/paused_state.dart';
import '../../domain/state/victory_state.dart';
import '../../domain/value_objects/direction.dart';
import '../providers/providers.dart';
import '../widgets/board_widget.dart';

/// GameScreen — observa GameNotifier, renderiza el tablero con BoardWidget.
/// Navega a VictoryScreen/DefeatScreen cuando el estado del juego cambia.
class GameScreen extends ConsumerStatefulWidget {
  final String levelId;

  const GameScreen({super.key, required this.levelId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final GlobalKey<BoardWidgetState> _boardKey = GlobalKey<BoardWidgetState>();
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLevel());
  }

  Future<void> _loadLevel() async {
    final userId = ref.read(authNotifierProvider).userId;
    await ref.read(gameNotifierProvider.notifier).loadLevel(
          widget.levelId,
          userId: userId,
        );
  }

  void _onArrowTapped(String arrowId) {
    final gameState = ref.read(gameNotifierProvider);
    final session = gameState.session;
    if (session == null || !session.getState().isPlaying()) return;

    final wasActivatable = session.board.isActivatable(arrowId);
    final arrow = session.board.getArrows()[arrowId];

    // Activar flecha vía notifier
    ref.read(gameNotifierProvider.notifier).activateArrow(arrowId);

    // Disparar animación correspondiente
    if (wasActivatable && arrow != null) {
      final segments = arrow.getSegments();
      // segments está cabeza→cola; cells = de cola a cabeza
      // (el painter las espera en ese orden, igual que cells en el HTML).
      final cells = segments.reversed.map((s) => s.getPosition()).toList();
      final anim = ExitAnimation(
        cells: cells,
        direction: arrow.getDirection(),
        color: _hexToColor(arrow.getColor().getValue()),
        arrowId: arrowId,
      );
      _boardKey.currentState?.triggerExitAnimation(anim);
    } else if (arrow != null && !wasActivatable) {
      _boardKey.currentState?.triggerFailFlash(arrowId);
    }
  }

  void _onPause() {
    ref.read(gameNotifierProvider.notifier).pause();
    _showPauseDialog();
  }

  void _showPauseDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F0F1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1A1A2E)),
          ),
          title: const Text(
            'PAUSA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF00F5A0),
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogButton(
                'CONTINUAR',
                const Color(0xFF00F5A0),
                () {
                  Navigator.of(ctx).pop();
                  ref.read(gameNotifierProvider.notifier).resume();
                },
              ),
              const SizedBox(height: 12),
              _dialogButton(
                'REINICIAR',
                const Color(0xFFFFB800),
                () {
                  Navigator.of(ctx).pop();
                  ref.read(gameNotifierProvider.notifier).restart();
                },
              ),
              const SizedBox(height: 12),
              _dialogButton(
                'SALIR',
                const Color(0xFFFF3366),
                () {
                  Navigator.of(ctx).pop();
                  context.go('/levels');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Navegación automática a Victory/Defeat
  // ─────────────────────────────────────────────────────────
  void _checkNavigation(dynamic session) {
    if (session == null || _navigated) return;
    final state = session.getState();
    if (state is VictoryState) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/victory', extra: {
            'score': session.getScore(),
            'levelId': widget.levelId,
          });
        }
      });
    } else if (state is DefeatState) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/defeat', extra: {
            'score': session.getScore(),
            'levelId': widget.levelId,
          });
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider);
    final session = gameState.session;

    // Check game over navigation
    if (session != null) _checkNavigation(session);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D18),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ────────────────────────────────────────
            _Header(
              levelId: widget.levelId,
              difficulty: session?.board.getShape() != null
                  ? widget.levelId.contains('easy')
                      ? 'EASY'
                      : widget.levelId.contains('hard')
                          ? 'HARD'
                          : 'MEDIUM'
                  : '—',
              onPause: _onPause,
            ),

            // ─── Stats bar ──────────────────────────────────────
            if (session != null)
              _StatsBar(
                score: session.getScore(),
                arrowsLeft: session.board.getArrows().length,
                moves: session.getMoves(),
                maxMoves: session.maxMoves,
                timeRemaining: session.timeRemaining,
              ),

            // ─── Progress bar ────────────────────────────────────
            if (session != null)
              _MovesProgressBar(
                moves: session.getMoves(),
                maxMoves: session.maxMoves,
              ),

            // ─── Tablero ─────────────────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: session == null
                      ? const CircularProgressIndicator(
                          color: Color(0xFF00F5A0),
                        )
                      : session.board.getArrows().isEmpty &&
                              session.getState() is! VictoryState
                          ? const CircularProgressIndicator(
                              color: Color(0xFF00F5A0),
                            )
                          : BoardWidget(
                              key: _boardKey,
                              board: session.board,
                              onArrowTapped: _onArrowTapped,
                              interactive: session.getState() is! PausedState,
                            ),
                ),
              ),
            ),

            // ─── Power-ups ───────────────────────────────────────
            if (session != null)
              _PowerUpBar(
                onHint: () =>
                    ref.read(gameNotifierProvider.notifier).useHint(),
                onHammer: () {
                  // Selección de flecha para el martillo — implementación simple:
                  // usa la primera flecha bloqueada disponible
                  final arrows = session.board.getArrows();
                  if (arrows.isNotEmpty) {
                    ref
                        .read(gameNotifierProvider.notifier)
                        .useHammer(arrows.keys.first);
                  }
                },
                onMagnet: () => ref
                    .read(gameNotifierProvider.notifier)
                    .useMagnet(Direction.right()),
                coins: gameState.progress?.getCoins() ?? 0,
              ),
          ],
        ),
      ),
    );
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGETS INTERNOS DE GAMESCREEN
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String levelId;
  final String difficulty;
  final VoidCallback onPause;

  const _Header({
    required this.levelId,
    required this.difficulty,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1E),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A2E))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ARROW MAZE',
            style: TextStyle(
              color: Color(0xFF00F5A0),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              fontFamily: 'monospace',
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00F5A0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              difficulty,
              style: const TextStyle(
                color: Color(0xFF00F5A0),
                fontSize: 10,
                letterSpacing: 1,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            onPressed: onPause,
            icon: const Icon(Icons.pause, color: Color(0xFF555555)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final int score;
  final int arrowsLeft;
  final int moves;
  final int maxMoves;
  final int? timeRemaining;

  const _StatsBar({
    required this.score,
    required this.arrowsLeft,
    required this.moves,
    required this.maxMoves,
    this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1E),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A2E))),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(label: 'SCORE', value: '$score'),
            const VerticalDivider(width: 1, color: Color(0xFF1A1A2E)),
            _StatCell(label: 'FLECHAS', value: '$arrowsLeft'),
            const VerticalDivider(width: 1, color: Color(0xFF1A1A2E)),
            _StatCell(label: 'MOVIMIENTOS', value: '$moves'),
            if (timeRemaining != null) ...[
              const VerticalDivider(width: 1, color: Color(0xFF1A1A2E)),
              _StatCell(
                label: 'TIEMPO',
                value: '${timeRemaining}s',
                valueColor: timeRemaining! <= 10
                    ? const Color(0xFFFF3366)
                    : const Color(0xFF00F5A0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF00F5A0),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 8,
                letterSpacing: 1,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovesProgressBar extends StatelessWidget {
  final int moves;
  final int maxMoves;

  const _MovesProgressBar({required this.moves, required this.maxMoves});

  @override
  Widget build(BuildContext context) {
    final pct = maxMoves == 0 ? 0.0 : (moves / maxMoves).clamp(0.0, 1.0);
    final barColor = pct > 0.8
        ? const Color(0xFFFF3366)
        : pct > 0.6
            ? const Color(0xFFFF9500)
            : const Color(0xFF00F5A0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      color: const Color(0xFF0F0F1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MOVES',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 9,
                  letterSpacing: 1,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '$moves/$maxMoves',
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFF1A1A2E),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerUpBar extends StatelessWidget {
  final VoidCallback onHint;
  final VoidCallback onHammer;
  final VoidCallback onMagnet;
  final int coins;

  const _PowerUpBar({
    required this.onHint,
    required this.onHammer,
    required this.onMagnet,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1E),
        border: Border(top: BorderSide(color: Color(0xFF1A1A2E))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PowerUpButton(
              icon: '💡',
              label: 'HINT',
              cost: 5,
              onTap: onHint,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PowerUpButton(
              icon: '🔨',
              label: 'HAMMER',
              cost: 10,
              onTap: onHammer,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PowerUpButton(
              icon: '🧲',
              label: 'MAGNET',
              cost: 15,
              onTap: onMagnet,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'COINS',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 8,
                  letterSpacing: 1,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '$coins',
                style: const TextStyle(
                  color: Color(0xFFFFB800),
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  final String icon;
  final String label;
  final int cost;
  final VoidCallback onTap;

  const _PowerUpButton({
    required this.icon,
    required this.label,
    required this.cost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF141420),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFF1A1A2E)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 8,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '-$cost',
              style: const TextStyle(
                color: Color(0xFFFFB800),
                fontSize: 8,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
