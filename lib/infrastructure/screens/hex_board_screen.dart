import 'dart:math';
import 'package:flutter/material.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/grid_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/hammer_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/hint_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/magnet_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/states/defeat_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/victory_state.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/hex_board_painter.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/hex_projection.dart';

/// A free-play hexagonal board: every cell connects in 6 directions
/// (Direction.hexAll) instead of the usual 4. [GameSession] drives
/// moves/score/victory-defeat exactly like a normal level — it's
/// coordinate-system-agnostic, so the real domain engine runs unmodified —
/// and the 4 real PowerUp classes are wired directly against it.
///
/// Deliberately scoped as a standalone practice mode, not a numbered
/// level: no coin cost on power-ups and no coin/progress sync (there's no
/// backend level or GameProgress entry behind it), so it stays reachable
/// any time from Settings without touching lives or the level chain. A
/// tapped/Magnet-cleared arrow gets the real worm-style exit animation;
/// Hammer still vanishes its target instantly (a "smash", not an "exit",
/// same distinction the real GameScreen makes).
enum _HexBoardKind { simple, complex }

/// Snapshot of an arrow that just left the board, plus enough geometry to
/// slide it off-canvas over the animation's lifetime.
class _PendingHexExit {
  final List<Position> cells;
  final Direction direction;
  final Color color;
  final int edgeDistance;
  final AnimationController controller;

  _PendingHexExit({
    required this.cells,
    required this.direction,
    required this.color,
    required this.edgeDistance,
    required this.controller,
  });
}

class HexBoardScreen extends StatefulWidget {
  const HexBoardScreen({super.key});

  @override
  State<HexBoardScreen> createState() => _HexBoardScreenState();
}

class _HexBoardScreenState extends State<HexBoardScreen> with TickerProviderStateMixin {
  _HexBoardKind _kind = _HexBoardKind.simple;
  late GameSession _session;
  final Map<String, Color> _flash = {};

  String? _pendingPowerUp;
  String? _hintArrowId;
  AnimationController? _hintController;
  double _gridOverlayOpacity = 0;
  AnimationController? _gridController;
  final Map<String, _PendingHexExit> _pendingExits = {};

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _hintController?.dispose();
    _gridController?.dispose();
    for (final exit in _pendingExits.values) {
      exit.controller.dispose();
    }
    super.dispose();
  }

  HexProjection get _projection => _kind == _HexBoardKind.simple
      ? const HexProjection(hexSize: 26)
      : const HexProjection(hexSize: 15);

  BoardShape _shapeFor(_HexBoardKind kind) =>
      kind == _HexBoardKind.simple ? BoardShape.hexagon(4) : BoardShape.hexagonRing(7, 3);

  String _difficultyFor(_HexBoardKind kind) =>
      kind == _HexBoardKind.simple ? 'EASY' : 'HARD';

  void _resetPowerUpState() {
    _pendingPowerUp = null;
    _hintController?.dispose();
    _hintController = null;
    _hintArrowId = null;
    _gridController?.dispose();
    _gridController = null;
    _gridOverlayOpacity = 0;
    for (final exit in _pendingExits.values) {
      exit.controller.dispose();
    }
    _pendingExits.clear();
  }

  void _generate() {
    _resetPowerUpState();
    _flash.clear();
    final difficulty = _difficultyFor(_kind);
    final builder = BoardBuilder.create(
      seed: Random().nextInt(1 << 31),
      useHexDirections: true,
    )
      ..setShape(_shapeFor(_kind))
      ..setDifficulty(difficulty);
    final board = builder.build();
    final maxMoves = builder.getCalculatedMaxMoves() ??
        BoardBuilder.calculateMaxMoves(board.arrows.length, difficulty);
    _session = GameSession(
      board: board,
      levelId: 'hex-${_kind.name}',
      maxMoves: maxMoves,
    );
  }

  void _switchBoard(_HexBoardKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _generate();
    });
  }

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

  /// Snapshots [arrow] (its shape/direction/color are gone from the board
  /// the instant the move that removed it returns) and slides it off the
  /// board along its own direction — the same "worm" interpolation the
  /// real exit animation uses, just fed through the hex projection.
  void _startExitAnimation(Arrow arrow) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final exit = _PendingHexExit(
      cells: arrow.segments.map((s) => s.position).toList(),
      direction: arrow.getDirection(),
      color: Color(
        int.parse(arrow.color.value.replaceFirst('#', ''), radix: 16) | 0xFF000000,
      ),
      edgeDistance: _session.board.shape
          .distanceToExit(arrow.getHead().position, arrow.getDirection()),
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
  /// easeOut curve the real exit animations use.
  List<HexExitingArrowAnim> _buildExitingAnimList() {
    return _pendingExits.values.map((exit) {
      final t = exit.controller.value;
      final eased = 1 - pow(1 - t, 3).toDouble();
      return HexExitingArrowAnim(
        cells: exit.cells,
        direction: exit.direction,
        color: exit.color,
        edgeDistance: exit.edgeDistance,
        progress: eased,
      );
    }).toList();
  }

  void _onTapCell(Offset canvasLocal, Offset originOffset) {
    if (_session.isOver()) return;
    final unbounded = canvasLocal - originOffset;
    final cell = _projection.cellAt(unbounded);
    final arrowId = _session.board.grid[cell.toKey()];
    if (arrowId == null) return;

    if (_pendingPowerUp == 'HAMMER') {
      final result = _session.applyPowerUp(HammerPowerUp(targetArrowId: arrowId));
      setState(() => _pendingPowerUp = null);
      if (!result.success) _showSnack(result.message);
      _afterMutation();
      return;
    }

    // Snapshot before executeMove() — PlayingState.handle already removed
    // the arrow from board.arrows by the time it returns.
    final arrowSnapshot = _session.board.arrows[arrowId];
    final result = _session.executeMove(arrowId);
    if (!result.success) {
      setState(() => _flash[arrowId] = const Color(0xFFFF3366));
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _flash.remove(arrowId));
      });
      return;
    }

    setState(() => _flash.remove(arrowId));
    if (arrowSnapshot != null) _startExitAnimation(arrowSnapshot);
    _afterMutation();
  }

  void _onPowerUp(String type) {
    switch (type) {
      case 'HINT':
        final result = _session.applyPowerUp(HintPowerUp());
        if (result.success && result.affectedArrowIds.isNotEmpty) {
          _startHintAnimation(result.affectedArrowIds.first);
        } else {
          _showSnack(result.message);
        }
        break;
      case 'GRID':
        final result = _session.applyPowerUp(GridPowerUp());
        if (result.success) {
          _startGridOverlayAnimation();
        } else {
          _showSnack(result.message);
        }
        break;
      case 'HAMMER':
        setState(() => _pendingPowerUp = 'HAMMER');
        return;
      case 'MAGNET':
        // Snapshot every currently activatable arrow before applyPowerUp()
        // mutates the board — afterwards only the ids it actually picked
        // (affectedArrowIds) are still worth animating.
        final snapshots = <String, Arrow>{
          for (final id in _session.board.getActivatableArrows())
            if (_session.board.arrows[id] != null) id: _session.board.arrows[id]!,
        };
        final result = _session.applyPowerUp(MagnetPowerUp());
        if (result.success) {
          for (final id in result.affectedArrowIds) {
            final arrow = snapshots[id];
            if (arrow != null) _startExitAnimation(arrow);
          }
        } else {
          _showSnack(result.message);
        }
        break;
    }
    setState(() {});
    _afterMutation();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _afterMutation() {
    setState(() {});
    if (_session.isOver()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOverDialog());
    }
  }

  void _showGameOverDialog() {
    final l10n = AppLocalizations.of(context);
    final isVictory = _session.state is VictoryState;
    if (isVictory) _session.calculateFinalScore();
    final reason = _session.state is DefeatState
        ? (_session.state as DefeatState).reason
        : null;
    final movesLine = '${_session.moves}/${_session.maxMoves} ${l10n.translate('hexBoardMovesLeft')}';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          l10n.translate(isVictory ? 'hexBoardCleared' : 'hexBoardStuck'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isVictory
              ? '${l10n.translate('hexBoardScoreLabel')}: ${_session.score} — $movesLine'
              : '${l10n.translate('hexBoardReasonLabel')}: $reason — $movesLine',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(_generate);
            },
            child: Text(l10n.translate('newBoard')),
          ),
        ],
      ),
    );
  }

  Widget _boardSelector(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: Text(
                '${l10n.translate('hexBoardSimple')} — ${l10n.translate('hexBoardSimpleSubtitle')}',
              ),
              selected: _kind == _HexBoardKind.simple,
              onSelected: (_) => _switchBoard(_HexBoardKind.simple),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: Text(
                '${l10n.translate('hexBoardComplex')} — ${l10n.translate('hexBoardComplexSubtitle')}',
              ),
              selected: _kind == _HexBoardKind.complex,
              onSelected: (_) => _switchBoard(_HexBoardKind.complex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerUpBar(AppLocalizations l10n) {
    final buttons = <(String type, IconData icon, String labelKey)>[
      ('HINT', Icons.lightbulb, 'hint'),
      ('GRID', Icons.grid_on, 'gridName'),
      ('HAMMER', Icons.gavel, 'hammer'),
      ('MAGNET', Icons.filter_center_focus, 'magnet'),
    ];

    return Container(
      color: const Color(0xFF14141f),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.translate('freePowerUpsNote'),
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buttons.map((b) {
              final (type, icon, labelKey) = b;
              final pending = _pendingPowerUp == type;
              return InkWell(
                onTap: _session.isOver() ? null : () => _onPowerUp(type),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          color: pending ? const Color(0xFFFFD700) : const Color(0xFF00F5A0)),
                      Text(l10n.translate(labelKey),
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final board = _session.board;
    final projection = _projection;
    final cells = board.shape.getCells();
    final centers = cells.map(projection.centerOf).toList();
    final minX = centers.map((c) => c.dx).reduce(min) - projection.hexSize;
    final maxX = centers.map((c) => c.dx).reduce(max) + projection.hexSize;
    final minY = centers.map((c) => c.dy).reduce(min) - projection.hexSize;
    final maxY = centers.map((c) => c.dy).reduce(max) + projection.hexSize;
    final canvasSize = Size(maxX - minX, maxY - minY);
    final originOffset = Offset(-minX, -minY);

    final activatable = board.getActivatableArrows().toSet();
    final movesLeft = _session.maxMoves - _session.moves;

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d18),
      appBar: AppBar(
        title: Text(
          '${l10n.translate('hexBoard')} — ${board.arrows.length} ${l10n.translate('hexBoardArrowsLeft')} · '
          '$movesLeft ${l10n.translate('hexBoardMovesLeft')}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.translate('newBoard'),
            onPressed: () => setState(_generate),
          ),
        ],
      ),
      body: Column(
        children: [
          _boardSelector(l10n),
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.4,
                maxScale: 3,
                boundaryMargin: const EdgeInsets.all(200),
                child: GestureDetector(
                  onTapDown: (details) => _onTapCell(details.localPosition, originOffset),
                  child: CustomPaint(
                    size: canvasSize,
                    painter: HexBoardPainter(
                      board: board,
                      projection: projection,
                      originOffset: originOffset,
                      activatableArrows: activatable,
                      exitingArrows: _buildExitingAnimList(),
                      highlightArrowId: _hintArrowId,
                      highlightPulse: _hintController?.value ?? 0,
                      gridOverlayOpacity: _gridOverlayOpacity,
                      flashOverrides: _flash,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_pendingPowerUp == 'HAMMER')
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.translate('tapArrowToDestroy'),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _pendingPowerUp = null),
                    child: Text(l10n.translate('cancel'),
                        style: const TextStyle(color: Color(0xFFFF3366))),
                  ),
                ],
              ),
            ),
          _powerUpBar(l10n),
        ],
      ),
    );
  }
}
