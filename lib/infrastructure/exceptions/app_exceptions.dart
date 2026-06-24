class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

class BadRequestException extends AppException {
  BadRequestException(String message) : super('Bad request: $message');
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super('Unauthorized: $message');
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super('Not found: $message');
}

class ServerException extends AppException {
  ServerException(String message) : super('Server error: $message');
}

class NetworkException extends AppException {
  NetworkException(String message) : super('Network error: $message');
}
