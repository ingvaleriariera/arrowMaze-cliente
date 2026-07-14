import 'package:arrow_maze_cliente_copy/domain/builders/board_builder.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';

/// Default extrusion depth: flat boards, today's game byte-for-byte.
const int kBoardDepth = 1;

/// Depth used when the "Juego 3D" setting is on: boards become
/// 6-connection prisms of this many layers (see BoardShape.extrude),
/// played one layer at a time through GameScreen's layer selector.
const int kBoardDepth3D = 4;

/// Input for [generateBoard]. Plain data only (no closures, no Flutter
/// types) so it can cross an isolate boundary via `compute()`.
class BoardGenerationRequest {
  final int seed;
  final String boardLayoutJson;
  final String difficulty;

  /// Extrusion depth (layers along Z) applied to the 2D silhouette.
  final int depth;

  const BoardGenerationRequest({
    required this.seed,
    required this.boardLayoutJson,
    required this.difficulty,
    this.depth = kBoardDepth,
  });
}

/// Output of [generateBoard]: the generated board plus the maxMoves
/// BoardBuilder computed for it (board generation already runs the
/// margin calculation internally; recomputing it from arrow count alone
/// after the fact would mean duplicating BoardBuilder's difficulty rules).
class BoardGenerationResult {
  final Board board;
  final int maxMoves;

  const BoardGenerationResult({required this.board, required this.maxMoves});
}

/// Top-level function (required by `compute()`/`Isolate.run`) that runs
/// BoardBuilder's generation off the calling isolate. Arrow generation is
/// the expensive part of loading a level — running it on a background
/// isolate (a real OS thread on native platforms, a Web Worker on web)
/// keeps the UI thread free to keep rendering and responding to taps
/// while it runs, instead of freezing for however long generation takes.
BoardGenerationResult generateBoard(BoardGenerationRequest request) {
  // The backend only ever sends flat 0/1 grids; extrusion into a prism
  // happens here, client-side, right before generation. depth=1 returns
  // the shape untouched.
  final shape = BoardShape.extrude(
    BoardShape.fromJson(request.boardLayoutJson),
    request.depth,
  );
  final builder = BoardBuilder.create(seed: request.seed)
      .setShape(shape)
      .setDifficulty(request.difficulty);
  final board = builder.build();
  final maxMoves = builder.getCalculatedMaxMoves() ??
      BoardBuilder.calculateMaxMoves(board.arrows.length, request.difficulty.toUpperCase());

  return BoardGenerationResult(board: board, maxMoves: maxMoves);
}
