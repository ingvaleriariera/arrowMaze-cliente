class LevelSummaryDTO {
  final String levelId;
  final String difficulty;
  final bool completed;
  final int bestScore;
  final bool isTimed;

  LevelSummaryDTO({
    required this.levelId,
    required this.difficulty,
    required this.completed,
    required this.bestScore,
    required this.isTimed,
  });

  @override
  String toString() =>
      'LevelSummaryDTO(levelId: $levelId, difficulty: $difficulty, completed: $completed, bestScore: $bestScore)';
}
