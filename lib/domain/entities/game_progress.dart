class GameProgress {
  final String userId;
  final List<String> completedLevels;
  final Map<String, int> bestScores;
  int coins;

  // The player's chosen avatar emoji. Deliberately local-only (never sent
  // through ProgressMapper's toMap()/fromMap() — the backend User entity
  // has no avatar field, and adding one means touching login/register/JWT,
  // out of scope for now). Lives in the same in-memory cache as coins, so
  // it's lost on a full app restart same as everything else here until
  // GameProgressRepositoryImpl gets real local persistence.
  String avatarEmoji;

  GameProgress({
    required this.userId,
    List<String>? completedLevels,
    Map<String, int>? bestScores,
    this.coins = 0,
    this.avatarEmoji = '🎮',
  })
      : completedLevels = completedLevels ?? [],
        bestScores = bestScores ?? {};

  bool isCompleted(String levelId) => completedLevels.contains(levelId);

  int? getBestScore(String levelId) => bestScores[levelId];

  /// Fraction of the score awarded as coins when replaying an
  /// already-completed level. Full score on first completion keeps the
  /// big reward tied to progression; the reduced replay award keeps every
  /// win worth something without making coin farming trivial.
  static const double replayCoinFactor = 0.25;

  void recordCompletion(String levelId, int score) {
    final isFirstCompletion = !completedLevels.contains(levelId);

    if (isFirstCompletion) {
      completedLevels.add(levelId);
      addCoins(score);
    } else {
      addCoins((score * replayCoinFactor).round());
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

  void setAvatar(String emoji) {
    avatarEmoji = emoji;
  }

  int get totalScore => bestScores.values.fold(0, (sum, score) => sum + score);

  @override
  String toString() =>
      'GameProgress(user: $userId, completed: ${completedLevels.length}, coins: $coins)';
}
