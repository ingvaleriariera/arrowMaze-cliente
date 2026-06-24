import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  void _loadLevels() {
    final levelSelectNotifier = ref.read(levelSelectNotifierProvider.notifier);
    final authState = ref.read(authNotifierProvider);
    if (authState.userId != null) {
      levelSelectNotifier.loadSummaries(authState.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final levelSelectState = ref.watch(levelSelectNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('levelSelect')),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => context.go('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authNotifier.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: levelSelectState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0)))
          : levelSelectState.error != null
              ? Center(child: Text(levelSelectState.error!))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: levelSelectState.levels.length,
                  itemBuilder: (context, index) {
                    final level = levelSelectState.levels[index];
                    return GestureDetector(
                      onTap: () => context.go('/game/${level.levelId}'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a2e),
                          border: Border.all(color: const Color(0xFF00F5A0), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (level.completed)
                              const Icon(Icons.check_circle, color: Colors.green, size: 32)
                            else
                              Text(
                                'Level ${index + 1}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 8),
                            if (level.completed)
                              Text('Score: ${level.bestScore}')
                            else
                              Text(level.difficulty),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
