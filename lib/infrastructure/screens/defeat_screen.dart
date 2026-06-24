import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

class DefeatScreen extends ConsumerWidget {
  const DefeatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gameNotifier = ref.read(gameNotifierProvider.notifier);

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
            const Text('Game Over'),
            const SizedBox(height: 48),
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
              child: const Text('Back to Levels'),
            ),
          ],
        ),
      ),
    );
  }
}
