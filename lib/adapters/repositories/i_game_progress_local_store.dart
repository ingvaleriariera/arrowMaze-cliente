/// Port abstracting the on-device storage backend behind
/// [GameProgressRepositoryImpl]. sqflite (used by [GameProgressDatabase])
/// has no web implementation, so this lets the repository stay agnostic
/// between that and a shared_preferences-backed store on Flutter Web,
/// without changing any of the cache/sync logic that sits on top of it.
///
/// Methods mirror the raw row shape sqflite already returns:
/// completedLevels/bestScores travel as JSON-encoded TEXT, exactly as
/// GameProgressRepositoryImpl._reconstructProgressFromDatabase expects.
abstract class IGameProgressLocalStore {
  Future<Map<String, dynamic>?> getProgress(String userId);

  Future<void> saveProgress(
    String userId,
    List<String> completedLevels,
    Map<String, int> bestScores,
    int coins,
    String avatarEmoji,
  );

  Future<void> deleteProgress(String userId);

  Future<void> closeDatabase();
}
