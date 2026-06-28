import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';

/// Caches the generated arrow layout for a level, by level id, so the
/// expensive randomized search BoardBuilder does to find a valid puzzle
/// only ever has to run once per level for the life of the app — not once
/// per visit. [Arrow]s are immutable value objects (segments/color never
/// change), so unlike a [Board] (whose arrows/grid get mutated in place as
/// the player clears them) the same cached layout can be handed out and
/// rebuilt into a fresh, unplayed [Board] every single time a level loads.
abstract class IBoardCache {
  /// True if an arrow layout for [levelId] is currently cached.
  bool has(String levelId);

  /// Stores [arrows] for [levelId], replacing any previous entry.
  void put(String levelId, List<Arrow> arrows);

  /// The cached arrow layout for [levelId], or null if there isn't one.
  /// Does NOT remove the entry — the whole point is to reuse it forever.
  List<Arrow>? get(String levelId);
}
