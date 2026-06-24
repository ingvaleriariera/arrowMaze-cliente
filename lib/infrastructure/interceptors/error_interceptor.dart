import 'package:dio/dio.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/exceptions/app_exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = switch (err.type) {
      DioExceptionType.badResponse => switch (err.response?.statusCode) {
        400 => BadRequestException(err.message ?? 'Bad request'),
        401 => UnauthorizedException(err.message ?? 'Unauthorized'),
        404 => NotFoundException(err.message ?? 'Not found'),
        500 => ServerException(err.message ?? 'Server error'),
        _ => ServerException(err.message ?? 'Unknown error'),
      },
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        NetworkException('Connection timeout'),
      DioExceptionType.unknown => NetworkException(err.message ?? 'Network error'),
      _ => AppException(err.message ?? 'Unknown error'),
    };

    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: exception,
      message: err.message,
    ));
  }
}
