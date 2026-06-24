class LeaderboardEntryDTO {
  final int rank;
  final String username;
  final int score;
  final String levelId;

  LeaderboardEntryDTO({
    required this.rank,
    required this.username,
    required this.score,
    required this.levelId,
  });

  @override
  String toString() =>
      'LeaderboardEntryDTO(rank: $rank, username: $username, score: $score, levelId: $levelId)';
}
