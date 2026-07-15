import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_generation_request.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_session.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_board_cache.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_time_limit_policy.dart';

class LoadLevelUseCase {
  final ILevelRepository levelRepository;
  final IBoardCache boardCache;
  final ITimeLimitPolicy timeLimitPolicy;

  /// Extrusion depth for every board this use case builds (1 = flat,
  /// kBoardDepth3D = 6-connection prisms). Injected so the setting is a
  /// provider-level concern, not something the use case reads itself.
  final int boardDepth;

  LoadLevelUseCase({
    required this.levelRepository,
    required this.boardCache,
    required this.timeLimitPolicy,
    this.boardDepth = kBoardDepth,
  });

  /// Cached layouts are only valid for the depth they were generated at —
  /// a flat layout replayed onto a prism (or vice versa) would desync the
  /// graph from the arrows, so the cache key carries the depth.
  String _cacheKey(String levelId) => '$levelId#d$boardDepth';

  Future<GameSession> execute(String levelId) async {
    debugPrint('🎮 LoadLevelUseCase.execute: Loading levelId=$levelId (depth $boardDepth)');

    final level = await levelRepository.getLevel(levelId);
    debugPrint('   Level loaded: ${level.id}');

    // The arrow layout for a level is deterministic (seeded by levelId),
    // so BoardBuilder's expensive randomized search for a valid puzzle
    // only ever needs to run once per level for the app's lifetime — not
    // once per visit. A cache hit (whether from a previous play of this
    // level or from PreloadLevelsUseCase) skips straight to the cheap,
    // synchronous step of building a fresh, unplayed Board from the
    // already-known layout.
    final cachedLayout = boardCache.get(_cacheKey(levelId));
    final Board board;
    final int calculatedMaxMoves;
    if (cachedLayout != null) {
      debugPrint('⚡ LoadLevelUseCase: Reusing cached arrow layout for $levelId');
      // Same extrusion as the generation path (generateBoard): cached
      // arrows were generated on the extruded shape, so the graph must be
      // rebuilt on the extruded shape too — a flat shape here would strip
      // the upper layers from the blocking rules.
      board = BoardBuilder.fromArrows(
        BoardShape.extrude(level.getBoardShape(), boardDepth),
        cachedLayout,
      );
      calculatedMaxMoves =
          BoardBuilder.calculateMaxMoves(board.arrows.length, level.difficulty.toUpperCase());
    } else {
      // Deterministic seed from levelId so every player sees the same
      // arrow layout for a given level (keeps leaderboard scores comparable).
      // Generation runs on a background isolate (a real OS thread on
      // native; on web it currently still runs inline — see compute()'s
      // web implementation — but caching the result means it only ever
      // costs once per level either way).
      debugPrint('   Generating arrows with difficulty=${level.difficulty} (background isolate)...');
      final result = await compute(
        generateBoard,
        BoardGenerationRequest(
          seed: level.id.hashCode,
          boardLayoutJson: level.boardLayout,
          difficulty: level.difficulty,
          depth: boardDepth,
        ),
      );
      board = result.board;
      calculatedMaxMoves = result.maxMoves;
      boardCache.put(_cacheKey(levelId), board.arrows.values.toList());
    }
    debugPrint('✅ LoadLevelUseCase: Board built with ${board.arrows.length} arrows');
    debugPrint('   Calculated maxMoves: $calculatedMaxMoves (margin for ${level.difficulty})');

    // DEBUG: Print each arrow's blockedBy
    debugPrint('🔍 COLLISION DEBUG:');
    for (final arrow in board.arrows.values) {
      final node = board.graph.nodes[arrow.id];
      final blockedBy = node?.blockedBy ?? {};
      final pos = arrow.getHead().position;
      debugPrint('   Arrow ${arrow.id}: pos=(${pos.x},${pos.y}) blockedBy=$blockedBy');
    }

    final activatable = board.graph.getActivatable();
    debugPrint('🎯 Activatable at start: $activatable (${activatable.length}/${board.arrows.length})');

    // An explicit backend-provided time limit wins; otherwise the policy
    // decides from difficulty + how many arrows were actually generated
    // (only known client-side — the backend never sees the arrows).
    final timeLimit = level.isTimed()
        ? level.timeLimit
        : timeLimitPolicy.forLevel(
            difficulty: level.difficulty,
            totalArrows: board.arrows.length,
          );
    debugPrint(
        '⏱️  LoadLevelUseCase: timeLimit=${timeLimit.hasLimit() ? '${timeLimit.getValue()}s' : 'none'} (${level.difficulty}, ${board.arrows.length} arrows)');

    final session = GameSession(
      board: board,
      levelId: level.id,
      maxMoves: calculatedMaxMoves,
      timeRemaining: timeLimit.hasLimit() ? timeLimit.getValue() : null,
    );

    return session;
  }
}
