import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint('📤 REQUEST: ${options.method} ${options.path}');
      if (options.data != null) {
        debugPrint('📦 Body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint('📥 RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
      if (response.data != null) {
        debugPrint('📦 Body: ${response.data}');
      }
    }
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: ${err.message}');
      debugPrint('📝 Details: ${err.error}');
    }
    handler.next(err);
  }
}
