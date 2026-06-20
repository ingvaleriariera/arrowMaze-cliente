class LevelSummaryDTO {
  final String levelId;
  final String difficulty;
  final bool completed;
  final int bestScore;
  final bool isTimed;

  LevelSummaryDTO(
    this.levelId,
    this.difficulty,
    this.completed,
    this.bestScore,
    this.isTimed,
  );
}
