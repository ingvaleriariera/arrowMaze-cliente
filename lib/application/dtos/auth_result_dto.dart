class AuthResultDTO {
  final String token;
  final String userId;

  AuthResultDTO({
    required this.token,
    required this.userId,
  });

  @override
  String toString() => 'AuthResultDTO(userId: $userId, token: ${token.substring(0, 10)}...)';
}
