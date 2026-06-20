import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/dtos/level_summary_dto.dart';
import '../providers/providers.dart';

/// Pantalla de selección de niveles — observa LevelSelectNotifier y AuthNotifier.
class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLevels());
  }

  Future<void> _loadLevels() async {
    final userId = ref.read(authNotifierProvider).userId ?? '';
    await ref.read(levelSelectNotifierProvider.notifier).loadSummaries(userId);
  }

  @override
  Widget build(BuildContext context) {
    final levels = ref.watch(levelSelectNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D18),
      appBar: AppBar(
        title: const Text('ARROW MAZE'),
        backgroundColor: const Color(0xFF0F0F1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF555555)),
            tooltip: 'Ajustes',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF555555)),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: levels.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F5A0)),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: levels.length,
                itemBuilder: (context, index) =>
                    _LevelCard(summary: levels[index]),
              ),
            ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LevelSummaryDTO summary;

  const _LevelCard({required this.summary});

  Color get _difficultyColor {
    switch (summary.difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF00F5A0);
      case 'medium':
        return const Color(0xFFFFB800);
      case 'hard':
        return const Color(0xFFFF3366);
      default:
        return const Color(0xFF00DDFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/game/${summary.levelId}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: summary.completed ? _difficultyColor : const Color(0xFF1A1A2E),
            width: summary.completed ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: _difficultyColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      summary.difficulty.toUpperCase(),
                      style: TextStyle(
                        color: _difficultyColor,
                        fontSize: 9,
                        letterSpacing: 1,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (summary.isTimed)
                    const Icon(Icons.timer_outlined, color: Color(0xFFFF3366), size: 14),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.levelId.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (summary.completed) ...[
                Text(
                  'BEST: ${summary.bestScore}',
                  style: TextStyle(
                    color: _difficultyColor,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: _difficultyColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'COMPLETADO',
                      style: TextStyle(
                        color: _difficultyColor,
                        fontSize: 8,
                        letterSpacing: 1,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ] else
                const Text(
                  'TAP PARA JUGAR',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 9,
                    letterSpacing: 1,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
