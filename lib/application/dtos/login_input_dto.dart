class LoginInputDTO {
  final String emailOrUsername;
  final String password;

  LoginInputDTO({
    required this.emailOrUsername,
    required this.password,
  });

  @override
  String toString() => 'LoginInputDTO(emailOrUsername: $emailOrUsername)';
}
