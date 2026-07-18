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
    final localeNotifier = ref.read(localeNotifierProvider.notifier);
    final currentLocale = ref.watch(localeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('settings'))),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.volume_up, color: Color(0xFF00F5A0)),
            title: Text(l10n.translate('sound')),
            value: !settingsState.isMuted,
            onChanged: (_) => settingsNotifier.toggleMute(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration, color: Color(0xFF00F5A0)),
            title: Text(l10n.translate('vibration')),
            value: settingsState.vibrationEnabled,
            onChanged: (_) => settingsNotifier.toggleVibration(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.threed_rotation, color: Color(0xFF00F5A0)),
            title: Text(l10n.translate('board3d')),
            subtitle: Text(l10n.translate('board3dDescription')),
            value: settingsState.board3DEnabled,
            onChanged: (_) => settingsNotifier.toggleBoard3D(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.layers, color: Color(0xFF00DDFF)),
            title: Text(l10n.translate('game3d')),
            subtitle: Text(l10n.translate('game3dDescription')),
            value: settingsState.game3DEnabled,
            onChanged: (_) => settingsNotifier.toggleGame3D(),
          ),
          ListTile(
            leading: const Icon(Icons.hexagon_outlined, color: Color(0xFFFFB800)),
            title: Text(l10n.translate('hexBoard')),
            subtitle: Text(l10n.translate('hexBoardDescription')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/hex-board'),
          ),
          ListTile(
            title: Text(l10n.translate('language')),
            subtitle: Text(l10n.translate('languageSubtitle')),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text(l10n.translate('language')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('English'),
                        value: 'en',
                        groupValue: currentLocale.languageCode,
                        onChanged: (value) {
                          if (value == 'en') {
                            localeNotifier.setLocale(const Locale('en', ''));
                          }
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Español'),
                        value: 'es',
                        groupValue: currentLocale.languageCode,
                        onChanged: (value) {
                          if (value == 'es') {
                            localeNotifier.setLocale(const Locale('es', ''));
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
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
