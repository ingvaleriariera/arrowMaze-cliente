import 'package:dio/dio.dart';
import 'package:arrow_maze_cliente_copy/domain/exceptions/app_exceptions.dart';

class ErrorInterceptor extends Interceptor {
  String? _extractErrorMessage(DioException err) {
    try {
      if (err.response?.data is Map<String, dynamic>) {
        final data = err.response!.data as Map<String, dynamic>;
        if (data['message'] is String) {
          return data['message'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final serverMessage = _extractErrorMessage(err) ?? err.message;

    final exception = switch (err.type) {
      DioExceptionType.badResponse => switch (err.response?.statusCode) {
        400 => BadRequestException(serverMessage ?? 'Bad request'),
        401 => UnauthorizedException(serverMessage ?? 'Unauthorized'),
        404 => NotFoundException(serverMessage ?? 'Not found'),
        500 => ServerException(serverMessage ?? 'Server error'),
        _ => ServerException(serverMessage ?? 'Unknown error'),
      },
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        NetworkException('Timeout de conexión'),
      DioExceptionType.unknown => NetworkException(serverMessage ?? 'Error de red'),
      _ => AppException(serverMessage ?? 'Unknown error'),
    };

    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: exception,
      message: err.message,
    ));
  }
}
