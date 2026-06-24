import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/level_select_state.dart';
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
    debugPrint('🔧 LevelSelectScreen.initState: Initializing');
    
    // Load levels after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('📋 LevelSelectScreen: Post-frame callback executing');
      
      final authState = ref.read(authNotifierProvider);
      final userId = authState.userId;
      
      if (userId != null) {
        debugPrint('🎯 LevelSelectScreen: userId=$userId, calling loadSummaries()');
        ref.read(levelSelectNotifierProvider.notifier).loadSummaries(userId);
      } else {
        debugPrint('⚠️  LevelSelectScreen: userId is null, not calling loadSummaries()');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final levelSelectState = ref.watch(levelSelectNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    debugPrint('🎨 LevelSelectScreen.build: isLoading=${levelSelectState.isLoading}, levels=${levelSelectState.levels.length}');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('levelSelect')),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: levelSelectState.levels.isEmpty
                ? null
                : () => context.go('/leaderboard/${levelSelectState.levels.first.levelId}'),
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
      body: _buildBody(context, levelSelectState),
    );
  }

  Widget _buildBody(BuildContext context, LevelSelectState state) {
    debugPrint('🎨 LevelSelectScreen._buildBody: isLoading=${state.isLoading}, levels=${state.levels.length}');

    if (state.isLoading) {
      debugPrint('   → Showing spinner');
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00F5A0)),
      );
    }

    if (state.error != null) {
      debugPrint('   → Showing error: ${state.error}');
      return Center(child: Text(state.error!));
    }

    if (state.levels.isEmpty) {
      debugPrint('   → No levels (empty list)');
      return const Center(child: Text('No levels available'));
    }

    debugPrint('   → Showing ${state.levels.length} levels in grid');
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.levels.length,
      itemBuilder: (context, index) {
        final level = state.levels[index];
        return GestureDetector(
          onTap: () {
            debugPrint('👆 LevelSelectScreen: Level tapped - ${level.levelId}');
            
            // Call loadLevel BEFORE navigating
            debugPrint('   → Calling gameNotifier.loadLevel(${level.levelId})');
            ref.read(gameNotifierProvider.notifier).loadLevel(level.levelId, 'user_123');
            
            // Now navigate to game screen
            debugPrint('   → Navigating to /game/${level.levelId}');
            context.go('/game/${level.levelId}');
          },
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
    );
  }
}
