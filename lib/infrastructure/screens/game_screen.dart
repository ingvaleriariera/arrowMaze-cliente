import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/game_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/game_state.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/states/victory_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/defeat_state.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_painter.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String levelId;
  final String? difficulty;
  final int? levelNumber;

  const GameScreen({
    required this.levelId,
    this.difficulty,
    this.levelNumber,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

/// An exit animation in flight, driven by its own [controller]. The cells,
/// direction and color are snapshotted from the arrow at the moment it
/// left the board, since by then it's already gone from `board.arrows`.
class _PendingExit {
  final List<Position> cells;
  final Direction direction;
  final String color;
  final int edgeDistance;
  final AnimationController controller;

  _PendingExit({
    required this.cells,
    required this.direction,
    required this.color,
    required this.edgeDistance,
    required this.controller,
  });
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  bool _showPause = false;
  bool _loadInitiated = false;
  final Map<String, _PendingExit> _pendingExits = {};

  // Music/vibration are presentation-only toggles for now — no backing
  // service exists yet (sound reuses the already-wired SettingsNotifier).
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;

  int get _levelNumber {
    if (widget.levelNumber != null) return widget.levelNumber!;
    final match = RegExp(r'(\d+)$').firstMatch(widget.levelId);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  String _difficultyLabel(AppLocalizations l10n) {
    final raw = widget.difficulty?.toLowerCase();
    if (raw == null) return '';
    return l10n.translate(raw);
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🎮 GameScreen.initState: levelId=${widget.levelId}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_loadInitiated) {
        _loadInitiated = true;
        debugPrint('📋 GameScreen: Post-frame callback, calling loadLevel');
        _loadLevel();
      }
    });
  }

  @override
  void dispose() {
    for (final exit in _pendingExits.values) {
      exit.controller.dispose();
    }
    super.dispose();
  }

  void _loadLevel() {
    debugPrint('🎯 GameScreen._loadLevel: Starting load for levelId=${widget.levelId}');
    final gameNotifier = ref.read(gameNotifierProvider.notifier);
    gameNotifier.loadLevel(widget.levelId, _currentUserId());
  }

  // GameNotifier saves completion progress keyed by this id, and
  // LevelSelectScreen later reads it back keyed by the same auth user id
  // to decide what's unlocked — using a different (hardcoded) id here
  // would silently break that link.
  String _currentUserId() => ref.read(authNotifierProvider).userId ?? 'guest';

  void _startExitAnimation(Arrow arrow, BoardShape shape) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final exit = _PendingExit(
      cells: arrow.segments.map((s) => s.position).toList(),
      direction: arrow.getDirection(),
      color: arrow.color.value,
      edgeDistance: shape.distanceToExit(arrow.getHead().position, arrow.getDirection()),
      controller: controller,
    );
    _pendingExits[arrow.id] = exit;

    controller.addListener(() => setState(() {}));
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _pendingExits.remove(arrow.id));
        controller.dispose();
      }
    });
    controller.forward();
  }

  /// Eased (1-(1-t)^3) progress for every exit in flight, matching the
  /// easeOut curve used by the HTML reference's worm-exit animation.
  List<ExitingArrowAnim> _buildExitingAnimList() {
    return _pendingExits.values.map((exit) {
      final t = exit.controller.value;
      final eased = 1 - pow(1 - t, 3).toDouble();
      return ExitingArrowAnim(
        cells: exit.cells,
        direction: exit.direction,
        color: exit.color,
        edgeDistance: exit.edgeDistance,
        progress: eased,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gameState = ref.watch(gameNotifierProvider);
    final gameNotifier = ref.read(gameNotifierProvider.notifier);

    debugPrint('🎨 GameScreen.build:');
    debugPrint('   isLoading=${gameState.isLoading}');
    debugPrint('   session=${gameState.session != null ? "exists" : "null"}');

    // React to actual state transitions from the notifier, not to a
    // snapshot captured by an arbitrary intermediate build(). A
    // postFrameCallback closure here would capture whatever `gameState`
    // was at the time of that particular build, including stale sessions
    // from the previous level that are still in flight when this screen
    // first mounts.
    ref.listen<GameState>(gameNotifierProvider, (previous, next) {
      if (!next.isLoading && next.session != null) {
        if (next.session!.state is VictoryState) {
          debugPrint('🏆 GameScreen: Victory');
          context.go('/victory');
        } else if (next.session!.state is DefeatState) {
          debugPrint('💀 GameScreen: Defeat');
          context.go('/defeat');
        }
      }
    });

    final difficultyLabel = _difficultyLabel(l10n);
    final hudTitle = difficultyLabel.isEmpty
        ? '${l10n.translate('level')} $_levelNumber'
        : '${l10n.translate('level')} $_levelNumber · $difficultyLabel';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hudTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '${l10n.translate('moves')}: ${gameState.session?.moves ?? 0}/${gameState.session?.maxMoves ?? 0}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: gameState.session == null ? null : () => setState(() => _showPause = true),
          ),
        ],
      ),
      body: _buildBody(gameState, gameNotifier),
    );
  }

  Widget _buildBody(GameState gameState, GameNotifier gameNotifier) {
    if (gameState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00F5A0)),
      );
    }

    if (gameState.error != null) {
      return Center(child: Text('Error: ${gameState.error}'));
    }

    if (gameState.session == null) {
      return const Center(child: Text('Failed to load game'));
    }

    final session = gameState.session!;
    final board = session.board;
    final shape = board.shape;
    final validCells = shape.getCells();

    // Get activatable arrows
    final activatableSet = <String>{};
    for (final arrowId in board.graph.getActivatable()) {
      activatableSet.add(arrowId);
    }

    // Calculate grid dimensions
    int minX = 0, maxX = 0, minY = 0, maxY = 0;
    for (final cell in validCells) {
      if (cell == validCells.first) {
        minX = cell.x;
        maxX = cell.x;
        minY = cell.y;
        maxY = cell.y;
      } else {
        minX = cell.x < minX ? cell.x : minX;
        maxX = cell.x > maxX ? cell.x : maxX;
        minY = cell.y < minY ? cell.y : minY;
        maxY = cell.y > maxY ? cell.y : maxY;
      }
    }
    final cols = maxX - minX + 1;
    final rows = maxY - minY + 1;

    return Stack(
      children: [
        Column(
          children: [
            // Board area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = (constraints.maxWidth / cols).clamp(20.0, 200.0);
                  final gridWidth = cellSize * cols;
                  final gridHeight = cellSize * rows;

                  return Container(
                    color: const Color(0xFF0d0d18),
                    child: Center(
                      child: SizedBox(
                        width: gridWidth,
                        height: gridHeight,
                        child: GestureDetector(
                          onTapDown: (details) {
                            final gridX = (details.localPosition.dx / cellSize).floor() + minX;
                            final gridY = (details.localPosition.dy / cellSize).floor() + minY;
                            debugPrint('🖱️ Tap at ($gridX, $gridY)');

                            final arrowId = board.grid['$gridX,$gridY'];
                            if (arrowId != null) {
                              debugPrint('🎯 Arrow tapped: $arrowId');
                              if (activatableSet.contains(arrowId)) {
                                final arrow = board.arrows[arrowId];
                                if (arrow != null) {
                                  _startExitAnimation(arrow, shape);
                                }
                              }
                              gameNotifier.activateArrow(arrowId);
                            }
                          },
                          child: CustomPaint(
                            painter: BoardPainter(
                              board: board,
                              activatableArrows: activatableSet,
                              cellSize: cellSize,
                              minX: minX,
                              minY: minY,
                              flashMap: gameState.flashMap,
                              exitingArrows: _buildExitingAnimList(),
                            ),
                            size: Size(gridWidth, gridHeight),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Controls
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
                    child: const Text('Hint'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F5A0),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Hammer'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F5A0),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Magnet'),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Pause overlay
        if (_showPause) _buildPauseOverlay(gameNotifier),
      ],
    );
  }

  Widget _buildPauseOverlay(GameNotifier gameNotifier) {
    final l10n = AppLocalizations.of(context);
    final settingsState = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
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
                  l10n.translate('paused'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up, color: Color(0xFF00F5A0)),
                  title: Text(l10n.translate('sound')),
                  value: !settingsState.isMuted,
                  onChanged: (_) => settingsNotifier.toggleMute(),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.music_note, color: Color(0xFF00F5A0)),
                  title: Text(l10n.translate('music')),
                  value: _musicEnabled,
                  onChanged: (value) => setState(() => _musicEnabled = value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration, color: Color(0xFF00F5A0)),
                  title: Text(l10n.translate('vibration')),
                  value: _vibrationEnabled,
                  onChanged: (value) => setState(() => _vibrationEnabled = value),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _showPause = false);
                    gameNotifier.restart(widget.levelId, _currentUserId());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text(l10n.translate('restart')),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go('/levels'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text(l10n.translate('backToMenu')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
