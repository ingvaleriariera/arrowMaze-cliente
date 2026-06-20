import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Pantalla de ajustes — observa SettingsNotifier.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(settingsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D18),
      appBar: AppBar(
        title: const Text('AJUSTES'),
        backgroundColor: const Color(0xFF0F0F1E),
        leading: const BackButton(color: Color(0xFF00F5A0)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Mute toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A1A2E)),
              ),
              child: ListTile(
                leading: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                  color: isMuted ? const Color(0xFF555555) : const Color(0xFF00F5A0),
                ),
                title: const Text(
                  'SONIDO',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                subtitle: Text(
                  isMuted ? 'SILENCIADO' : 'ACTIVO',
                  style: TextStyle(
                    color: isMuted ? const Color(0xFF555555) : const Color(0xFF00F5A0),
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                trailing: Switch(
                  value: !isMuted,
                  onChanged: (_) =>
                      ref.read(settingsNotifierProvider.notifier).toggleMute(),
                  activeThumbColor: const Color(0xFF00F5A0),
                  inactiveTrackColor: const Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Versión
            const Spacer(),
            const Text(
              'ARROW MAZE v1.0',
              style: TextStyle(
                color: Color(0xFF252535),
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
