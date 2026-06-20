import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// AOP — Aspecto de Logging.
/// Solo activo en modo debug.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ [${options.method}] ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← [${response.statusCode}] ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '✗ [${err.response?.statusCode}] ${err.requestOptions.path}: ${err.message}',
      );
    }
    handler.next(err);
  }
}
