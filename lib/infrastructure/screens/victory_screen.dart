import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';

class VictoryScreen extends ConsumerWidget {
  const VictoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gameState = ref.watch(gameNotifierProvider);
    final score = gameState.session?.score ?? 0;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              l10n.translate('victory'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text('${l10n.translate('score')}: $score'),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => context.go('/levels'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: Colors.black,
              ),
              child: Text(l10n.translate('levelSelect')),
            ),
          ],
        ),
      ),
    );
  }
}
