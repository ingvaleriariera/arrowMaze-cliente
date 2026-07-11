import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/lives/buy_life_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/player_lives.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

String formatLifeCountdown(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Lives dialog, shared by every entry point: blocking "out of lives"
/// message when the pool is empty, or a status view (current pool + regen
/// countdown) when opened voluntarily from the Home heart counter. Buying
/// a life with coins is offered whenever the pool isn't full.
Future<void> showNoLivesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      // Consumer keeps the whole dialog live while open — LivesNotifier
      // re-emits every second while a life regenerates, and a successful
      // purchase updates the count/actions in place.
      return Consumer(
        builder: (context, ref, _) {
          final livesState = ref.watch(livesNotifierProvider);
          final countdown = livesState.timeUntilNextLife;
          final outOfLives = !livesState.canPlay;
          final isFull = livesState.lives?.isFull ?? true;

          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            title: Row(
              children: [
                Icon(
                  outOfLives ? Icons.heart_broken : Icons.favorite,
                  color: const Color(0xFFFF3366),
                ),
                const SizedBox(width: 8),
                Text(l10n.translate(outOfLives ? 'noLivesTitle' : 'livesRemaining')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (outOfLives)
                  Text(l10n.translate('noLivesMessage'))
                else
                  Row(
                    children: List.generate(
                      PlayerLives.maxLives,
                      (i) => Icon(
                        i < livesState.count ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFFF3366),
                        size: 22,
                      ),
                    ),
                  ),
                if (countdown != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF00F5A0)),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.translate('nextLifeIn')}: ${formatLifeCountdown(countdown)}',
                        style: const TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.translate('cancel')),
              ),
              if (!isFull)
                ElevatedButton.icon(
                  onPressed: () async {
                    final bought =
                        await ref.read(livesNotifierProvider.notifier).buyLife();
                    if (!dialogContext.mounted) return;
                    if (bought) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(l10n.translate('lifePurchaseFailed'))),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5A0),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.favorite, size: 16),
                  label: Text(
                      '${l10n.translate('buyLife')} (${BuyLifeUseCase.lifeCostInCoins} 🪙)'),
                ),
            ],
          );
        },
      );
    },
  );
}
