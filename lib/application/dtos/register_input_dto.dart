class RegisterInputDTO {
  final String email;
  final String username;
  final String password;

  RegisterInputDTO({
    required this.email,
    required this.username,
    required this.password,
  });

  @override
  String toString() => 'RegisterInputDTO(email: $email, username: $username)';
}
