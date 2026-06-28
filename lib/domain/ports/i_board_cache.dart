import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';

/// Caches already-generated [Board]s by level id so a level the player is
/// about to enter doesn't have to pay BoardBuilder's generation cost again.
abstract class IBoardCache {
  /// True if a board for [levelId] is currently cached.
  bool has(String levelId);

  /// Stores [board] for [levelId], replacing any previous entry.
  void put(String levelId, Board board);

  /// Returns and removes the cached board for [levelId], or null if there
  /// isn't one. Removing on read matters: a [Board] is mutated in place as
  /// arrows are cleared during play, so a cached entry must only ever be
  /// handed out once.
  Board? take(String levelId);
}
