class LevelSummaryDTO {
  final String levelId;
  final String difficulty;
  final bool completed;
  final int bestScore;
  final bool isTimed;
  final bool unlocked;

  LevelSummaryDTO({
    required this.levelId,
    required this.difficulty,
    required this.completed,
    required this.bestScore,
    required this.isTimed,
    required this.unlocked,
  });

  @override
  String toString() =>
      'LevelSummaryDTO(levelId: $levelId, difficulty: $difficulty, completed: $completed, bestScore: $bestScore, unlocked: $unlocked)';
}
