import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/domain/states/victory_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/defeat_state.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String levelId;

  const GameScreen({required this.levelId, Key? key}) : super(key: key);

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showPause = false;

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  void _loadLevel() {
    final gameNotifier = ref.read(gameNotifierProvider.notifier);
    gameNotifier.loadLevel(widget.levelId, 'user_123');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gameState = ref.watch(gameNotifierProvider);
    final gameNotifier = ref.read(gameNotifierProvider.notifier);

    // Check for game state transitions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (gameState.session != null) {
        if (gameState.session!.state is VictoryState) {
          context.go('/victory');
        } else if (gameState.session!.state is DefeatState) {
          context.go('/defeat');
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.translate('moves')}: ${gameState.session?.movesUsed ?? 0}/${gameState.session?.maxMoves ?? 0}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => setState(() => _showPause = true),
          ),
        ],
      ),
      body: gameState.session == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0)))
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: const Color(0xFF0d0d18),
                        child: Center(
                          child: Text(
                            'Game Board\n${gameState.session?.levelId}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF1a1a2e),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5A0),
                              foregroundColor: Colors.black,
                            ),
                            child: Text(l10n.translate('hint')),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5A0),
                              foregroundColor: Colors.black,
                            ),
                            child: Text(l10n.translate('hammer')),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5A0),
                              foregroundColor: Colors.black,
                            ),
                            child: Text(l10n.translate('magnet')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_showPause)
                  Scaffold(
                    backgroundColor: Colors.black54,
                    body: Center(
                      child: Card(
                        color: const Color(0xFF1a1a2e),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.translate('pause'),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: () {
                                  gameNotifier.resume();
                                  setState(() => _showPause = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00F5A0),
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(l10n.translate('resume')),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/levels'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                                child: const Text('Exit'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
