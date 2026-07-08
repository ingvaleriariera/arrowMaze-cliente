abstract class IScoreRepository {
  Future<void> submitScore(String userId, String levelId, int score);
}
