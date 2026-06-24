class GameProgress {
  final String userId;
  final List<String> completedLevels;
  final Map<String, int> bestScores;
  int coins;

  GameProgress({
    required this.userId,
    List<String>? completedLevels,
    Map<String, int>? bestScores,
    this.coins = 0,
  })
      : completedLevels = completedLevels ?? [],
        bestScores = bestScores ?? {};

  bool isCompleted(String levelId) => completedLevels.contains(levelId);

  int? getBestScore(String levelId) => bestScores[levelId];

  void recordCompletion(String levelId, int score) {
    if (!completedLevels.contains(levelId)) {
      completedLevels.add(levelId);
    }
    final currentBest = bestScores[levelId] ?? 0;
    if (score > currentBest) {
      bestScores[levelId] = score;
    }
  }

  void addCoins(int amount) {
    coins += amount;
  }

  bool spendCoins(int amount) {
    if (coins < amount) return false;
    coins -= amount;
    return true;
  }

  @override
  String toString() =>
      'GameProgress(user: $userId, completed: ${completedLevels.length}, coins: $coins)';
}
