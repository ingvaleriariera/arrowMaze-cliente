class GlobalLeaderboardEntryDTO {
  final int rank;
  final String username;
  final int totalScore;

  GlobalLeaderboardEntryDTO({
    required this.rank,
    required this.username,
    required this.totalScore,
  });

  @override
  String toString() =>
      'GlobalLeaderboardEntryDTO(rank: $rank, username: $username, totalScore: $totalScore)';
}
