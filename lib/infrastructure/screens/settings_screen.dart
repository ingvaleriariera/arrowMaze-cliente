import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsState = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('settings'))),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Mute Sound'),
            value: settingsState.isMuted,
            onChanged: (_) => settingsNotifier.toggleMute(),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('English / Español'),
            onTap: () {
              // Language switching logic
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () async {
                await authNotifier.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.translate('logout')),
            ),
          ),
        ],
      ),
    );
  }
}
