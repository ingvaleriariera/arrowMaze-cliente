import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/lives/buy_life_use_case.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

String formatLifeCountdown(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Blocking "out of lives" dialog: shows the live countdown to the next
/// regenerated life and offers buying one with coins. Shared by every
/// entry point into a level (Home play button, level select grid).
Future<void> showNoLivesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      return AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Row(
          children: [
            const Icon(Icons.heart_broken, color: Color(0xFFFF3366)),
            const SizedBox(width: 8),
            Text(l10n.translate('noLivesTitle')),
          ],
        ),
        // Consumer keeps the countdown ticking while the dialog is open —
        // LivesNotifier re-emits every second while a life regenerates.
        content: Consumer(
          builder: (context, ref, _) {
            final livesState = ref.watch(livesNotifierProvider);
            final countdown = livesState.timeUntilNextLife;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('noLivesMessage')),
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
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.translate('cancel')),
          ),
          Consumer(
            builder: (context, ref, _) => ElevatedButton.icon(
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
          ),
        ],
      );
    },
  );
}
