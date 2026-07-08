class AuthResultDTO {
  final String token;
  final String userId;
  final String username;

  AuthResultDTO({
    required this.token,
    required this.userId,
    required this.username,
  });

  @override
  String toString() => 'AuthResultDTO(userId: $userId, username: $username, token: ${token.substring(0, 10)}...)';
}
