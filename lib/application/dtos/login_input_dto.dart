class LoginInputDTO {
  final String email;
  final String password;

  LoginInputDTO({
    required this.email,
    required this.password,
  });

  @override
  String toString() => 'LoginInputDTO(email: $email)';
}
