import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

class DefeatScreen extends ConsumerWidget {
  const DefeatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final livesState = ref.watch(livesNotifierProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, size: 100, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              l10n.translate('defeat'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(l10n.translate('gameOver')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3366).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.heart_broken, color: Color(0xFFFF3366), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.translate('lifeLost')} · ${livesState.count}/${PlayerLives.maxLives}',
                    style: const TextStyle(
                      color: Color(0xFFFF3366),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Restart logic would go here
                context.go('/levels');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: Colors.black,
              ),
              child: Text(l10n.translate('retry')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/levels'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: Text(l10n.translate('backToLevels')),
            ),
          ],
        ),
      ),
    );
  }
}
