class GameProgress {
  final String userId;
  final List<String> completedLevels;
  final Map<String, int> bestScores;
  int coins;

  GameProgress(this.userId, this.completedLevels, this.bestScores, this.coins);

  bool isCompleted(String levelId) => completedLevels.contains(levelId);

  int getBestScore(String levelId) => bestScores[levelId] ?? 0;

  void recordCompletion(String levelId, int score) {
    if (!completedLevels.contains(levelId)) {
      completedLevels.add(levelId);
    }
    if (score > getBestScore(levelId)) {
      bestScores[levelId] = score;
    }
  }

  int getCoins() => coins;

  void addCoins(int amount) {
    coins += amount;
  }

  bool spendCoins(int amount) {
    if (coins < amount) return false;
    coins -= amount;
    return true;
  }
}
