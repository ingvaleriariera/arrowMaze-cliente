import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/game_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/game_state.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/grid_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/hammer_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/hint_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/magnet_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up_result.dart';
import 'package:arrow_maze_cliente_copy/domain/states/victory_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/defeat_state.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_painter.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/power_up_bar.dart';

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

/// A Hammer power-up smash in flight, snapshotted before the arrow was
/// removed from the board — same pattern as [_PendingExit], different
/// (in-place shrink/fade instead of slide-off) visual.
class _PendingSmash {
  final List<Position> cells;
  final Direction direction;
  final String color;
  final AnimationController controller;

  _PendingSmash({
    required this.cells,
    required this.direction,
    required this.color,
    required this.controller,
  });
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  bool _showPause = false;

  // Set right before programmatically popping after the player confirmed
  // leaving mid-run, so PopScope lets that one pop through.
  bool _exitConfirmed = false;
  bool _loadInitiated = false;
  final Map<String, _PendingExit> _pendingExits = {};
  final Map<String, _PendingSmash> _pendingSmashes = {};
  late TransformationController _transformationController;

  // Power-up UI state. `_pendingPowerUp` is non-null while waiting for the
  // player to tap a target arrow (currently only 'HAMMER' needs this —
  // Hint/Grid/Magnet act immediately on purchase).
  String? _pendingPowerUp;
  String? _hintArrowId;
  AnimationController? _hintController;
  double _gridOverlayOpacity = 0;
  AnimationController? _gridController;

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

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
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
    // Leaving the screen mid-game (back gesture) must stop a timed
    // level's countdown, or the abandoned session keeps ticking toward a
    // TIME_UP defeat in the background. Safe here: stopTimer only cancels
    // the Timer, it never touches notifier state during dispose.
    ref.read(gameNotifierProvider.notifier).stopTimer();
    for (final exit in _pendingExits.values) {
      exit.controller.dispose();
    }
    for (final smash in _pendingSmashes.values) {
      smash.controller.dispose();
    }
    _hintController?.dispose();
    _gridController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _loadLevel() {
    debugPrint('🎯 GameScreen._loadLevel: Starting load for levelId=${widget.levelId}');
    _resetPowerUpUiState();
    final gameNotifier = ref.read(gameNotifierProvider.notifier);
    gameNotifier.loadLevel(widget.levelId, _currentUserId());
  }

  /// Clears any power-up UI state left over from the previous level (or
  /// attempt) — without this, a Hammer targeting-mode left active, or a
  /// hint/grid overlay animation still running, would bleed into the next
  /// level load/restart.
  void _resetPowerUpUiState() {
    _pendingPowerUp = null;
    _hintController?.dispose();
    _hintController = null;
    _hintArrowId = null;
    _gridController?.dispose();
    _gridController = null;
    _gridOverlayOpacity = 0;
    for (final smash in _pendingSmashes.values) {
      smash.controller.dispose();
    }
    _pendingSmashes.clear();
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

  /// Hammer power-up: shrink-and-fade the struck arrow in place. [arrow]
  /// must be snapshotted by the caller before usePowerUp() runs — by the
  /// time that Future resolves, the arrow is already gone from
  /// `board.arrows`.
  void _startSmashAnimation(Arrow arrow) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    final smash = _PendingSmash(
      cells: arrow.segments.map((s) => s.position).toList(),
      direction: arrow.getDirection(),
      color: arrow.color.value,
      controller: controller,
    );
    _pendingSmashes[arrow.id] = smash;

    controller.addListener(() => setState(() {}));
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _pendingSmashes.remove(arrow.id));
        controller.dispose();
      }
    });
    controller.forward();
  }

  List<SmashingArrowAnim> _buildSmashingAnimList() {
    return _pendingSmashes.values.map((smash) {
      return SmashingArrowAnim(
        cells: smash.cells,
        direction: smash.direction,
        color: smash.color,
        progress: Curves.easeIn.transform(smash.controller.value),
      );
    }).toList();
  }

  /// Hint power-up: pulse [arrowId]'s glow for a few seconds, then clear.
  void _startHintAnimation(String arrowId) {
    _hintController?.dispose();
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..repeat(reverse: true);
    _hintController = controller;
    setState(() => _hintArrowId = arrowId);
    controller.addListener(() => setState(() {}));

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted || _hintController != controller) return;
      controller.stop();
      controller.dispose();
      setState(() {
        _hintArrowId = null;
        _hintController = null;
      });
    });
  }

  /// Grid power-up: fade the exit-direction lines in, hold, then fade out.
  void _startGridOverlayAnimation() {
    _gridController?.dispose();
    final controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _gridController = controller;
    controller.addListener(() {
      final t = controller.value;
      setState(() {
        if (t < 0.15) {
          _gridOverlayOpacity = t / 0.15;
        } else if (t < 0.7) {
          _gridOverlayOpacity = 1.0;
        } else {
          _gridOverlayOpacity = (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
        }
      });
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        if (_gridController == controller) {
          setState(() {
            _gridOverlayOpacity = 0;
            _gridController = null;
          });
        }
      }
    });
    controller.forward();
  }

  void _handlePowerUpResult(PowerUpResult? result) {
    if (result != null && !result.success && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  /// Reacts to a power-up purchase confirmed in [PowerUpBar]'s info sheet.
  /// Hint/Grid/Magnet take effect immediately; Hammer instead arms
  /// target-selection mode — its actual usePowerUp() call happens from
  /// the board's onTapDown once a target is chosen.
  Future<void> _onPowerUpSelected(
    String type,
    GameNotifier gameNotifier,
    Board board,
    Set<String> activatableSet,
  ) async {
    switch (type) {
      case 'HINT':
        final result = await gameNotifier.usePowerUp(HintPowerUp());
        _handlePowerUpResult(result);
        if (result != null && result.success && result.affectedArrowIds.isNotEmpty) {
          _startHintAnimation(result.affectedArrowIds.first);
        }
        break;
      case 'GRID':
        final result = await gameNotifier.usePowerUp(GridPowerUp());
        _handlePowerUpResult(result);
        if (result != null && result.success) {
          _startGridOverlayAnimation();
        }
        break;
      case 'MAGNET':
        // Snapshot every currently activatable arrow before usePowerUp()
        // mutates the board — afterwards, only the ids it actually picked
        // (affectedArrowIds) are still worth animating.
        final snapshots = <String, Arrow>{
          for (final id in activatableSet)
            if (board.arrows[id] != null) id: board.arrows[id]!,
        };
        final result = await gameNotifier.usePowerUp(MagnetPowerUp());
        _handlePowerUpResult(result);
        if (result != null && result.success) {
          for (final id in result.affectedArrowIds) {
            final arrow = snapshots[id];
            if (arrow != null) _startExitAnimation(arrow, board.shape);
          }
        }
        break;
      case 'HAMMER':
        setState(() => _pendingPowerUp = 'HAMMER');
        break;
    }
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
          // Guarded by the previous state so repeated emissions of the
          // same over-session (e.g. the state copy right after this one)
          // can never deduct more than one life per defeat.
          if (previous?.session?.state is! DefeatState) {
            ref.read(livesNotifierProvider.notifier).loseLife();
          }
          context.go('/defeat');
        }
      }
    });

    final difficultyLabel = _difficultyLabel(l10n);
    final hudTitle = difficultyLabel.isEmpty
        ? '${l10n.translate('level')} $_levelNumber'
        : '${l10n.translate('level')} $_levelNumber · $difficultyLabel';

    final session = gameState.session;
    final isTimed = session != null && session.isTimedLevel();
    final timeLeft = isTimed ? (session.timeRemaining ?? 0) : 0;

    // Leaving mid-run counts as a defeat (costs a life), so both exit
    // routes — the back button/swipe and the pause overlay's menu button —
    // must go through the confirmation dialog while a session is live.
    final sessionInProgress =
        !gameState.isLoading && session != null && !session.isOver();

    return PopScope(
      canPop: !sessionInProgress || _exitConfirmed,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit(onConfirmed: () {
          setState(() => _exitConfirmed = true);
          // Deferred one frame: PopScope's canPop only picks up
          // _exitConfirmed after this rebuild, so popping synchronously
          // here would still be blocked and re-open the dialog.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        });
      },
      child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hudTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.translate('moves')}: ${session?.moves ?? 0}/${session?.maxMoves ?? 0}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                ),
                if (isTimed) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.timer_outlined,
                    size: 12,
                    color: timeLeft <= 30 ? const Color(0xFFFF3366) : Colors.white70,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatTime(timeLeft),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: timeLeft <= 30 ? FontWeight.bold : FontWeight.normal,
                      color: timeLeft <= 30 ? const Color(0xFFFF3366) : null,
                    ),
                  ),
                ],
              ],
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
      body: _buildBody(gameState, gameNotifier, l10n),
      ),
    );
  }

  /// Shows the leave-the-level confirmation. [onConfirmed] runs after the
  /// life has been deducted; the caller decides how to actually navigate
  /// (pop for the back gesture, go('/levels') for the pause overlay).
  void _confirmExit({required VoidCallback onConfirmed}) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(l10n.translate('exitLevelTitle')),
        content: Text(l10n.translate('exitLevelMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.translate('keepPlaying')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(livesNotifierProvider.notifier).loseLife();
              onConfirmed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3366),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('leaveAnyway')),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(GameState gameState, GameNotifier gameNotifier, AppLocalizations l10n) {
    if (gameState.error != null) {
      return Center(child: Text('Error: ${gameState.error}'));
    }

    // Also spin for the one frame between navigating here and loadLevel()
    // actually setting isLoading=true (it only runs from a postFrameCallback
    // in initState) — without this, that gap briefly showed "Failed to
    // load game" instead of a loading indicator.
    if (gameState.isLoading || gameState.session == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00F5A0)),
      );
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
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      boundaryMargin: const EdgeInsets.all(200),
                      constrained: true,
                      panEnabled: true,
                      scaleEnabled: true,
                      transformationController: _transformationController,
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
                              if (arrowId == null) return;
                              debugPrint('🎯 Arrow tapped: $arrowId');

                              // Hammer targeting mode: any arrow can be the
                              // target, blocked or not — that's the whole
                              // point of the hammer, unlike a normal tap.
                              if (_pendingPowerUp == 'HAMMER') {
                                final arrow = board.arrows[arrowId];
                                setState(() => _pendingPowerUp = null);
                                if (arrow == null) return;
                                gameNotifier
                                    .usePowerUp(HammerPowerUp(targetArrowId: arrowId))
                                    .then((result) {
                                  _handlePowerUpResult(result);
                                  if (result != null && result.success) {
                                    _startSmashAnimation(arrow);
                                  }
                                });
                                return;
                              }

                              if (activatableSet.contains(arrowId) && !board.graph.hasVoidReentry(arrowId, board.arrows, board.grid, board.shape)) {
                                final arrow = board.arrows[arrowId];
                                if (arrow != null) {
                                  _startExitAnimation(arrow, shape);
                                }
                              }
                              gameNotifier.activateArrow(arrowId);
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
                                highlightArrowId: _hintArrowId,
                                highlightPulse: _hintController?.value ?? 0,
                                gridOverlayOpacity: _gridOverlayOpacity,
                                smashingArrows: _buildSmashingAnimList(),
                              ),
                              size: Size(gridWidth, gridHeight),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            PowerUpBar(
              coins: gameState.progress?.coins ?? 0,
              pendingType: _pendingPowerUp,
              onSelect: (type) =>
                  _onPowerUpSelected(type, gameNotifier, board, activatableSet),
            ),
          ],
        ),
        // Hammer targeting banner
        if (_pendingPowerUp == 'HAMMER')
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.translate('tapArrowToDestroy'),
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _pendingPowerUp = null),
                      child: Text(l10n.translate('cancel'),
                          style: const TextStyle(
                              color: Color(0xFFFF3366),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
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
                  value: settingsState.musicEnabled,
                  onChanged: (_) => settingsNotifier.toggleMusic(),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration, color: Color(0xFF00F5A0)),
                  title: Text(l10n.translate('vibration')),
                  value: settingsState.vibrationEnabled,
                  onChanged: (_) => settingsNotifier.toggleVibration(),
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
                    setState(() {
                      _showPause = false;
                      _resetPowerUpUiState();
                    });
                    gameNotifier.restart(widget.levelId, _currentUserId());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text(l10n.translate('restart')),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _confirmExit(
                    onConfirmed: () => context.go('/levels'),
                  ),
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
