class LevelSummaryDTO {
  final String levelId;
  final String difficulty;
  final bool completed;
  final int bestScore;
  final bool isTimed;
  final bool unlocked;

  /// Display name override for entries that aren't numbered levels —
  /// adopted community boards show their board name instead of "Level N".
  final String? displayName;

  LevelSummaryDTO({
    required this.levelId,
    required this.difficulty,
    required this.completed,
    required this.bestScore,
    required this.isTimed,
    required this.unlocked,
    this.displayName,
  });

  @override
  String toString() =>
      'LevelSummaryDTO(levelId: $levelId, difficulty: $difficulty, completed: $completed, bestScore: $bestScore, unlocked: $unlocked)';
}
