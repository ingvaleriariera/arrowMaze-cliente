import 'package:dio/dio.dart';

/// Excepción tipada para errores de red.
class AppNetworkException implements Exception {
  final int? statusCode;
  final String message;

  const AppNetworkException({this.statusCode, required this.message});

  @override
  String toString() => 'AppNetworkException($statusCode): $message';
}

/// AOP — Aspecto de Excepciones.
/// Convierte errores HTTP (400, 404, 500, timeout, sin conexión)
/// en excepciones tipadas que los notifiers pueden manejar.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final String message;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        message = 'La conexión tardó demasiado. Intenta de nuevo.';
      case DioExceptionType.connectionError:
        message = 'Sin conexión a internet.';
      default:
        final responseMessage = err.response?.data;
        if (responseMessage is Map && responseMessage.containsKey('message')) {
          message = responseMessage['message'] as String;
        } else {
          message = err.message ?? 'Error desconocido.';
        }
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: AppNetworkException(statusCode: statusCode, message: message),
      ),
    );
  }
}
