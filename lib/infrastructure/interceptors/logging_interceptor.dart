import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final fullUrl = '${options.baseUrl}${options.path}';
      debugPrint('═════════════════════════════════════════');
      debugPrint('📤 REQUEST');
      debugPrint('Method: ${options.method}');
      debugPrint('URL: $fullUrl');
      if (options.headers.isNotEmpty) {
        debugPrint('Headers: ${options.headers}');
      }
      if (options.data != null) {
        debugPrint('Body: ${options.data}');
      }
      debugPrint('═════════════════════════════════════════');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final fullUrl = '${response.requestOptions.baseUrl}${response.requestOptions.path}';
      debugPrint('═════════════════════════════════════════');
      debugPrint('📥 RESPONSE');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('URL: $fullUrl');
      if (response.data != null) {
        debugPrint('Body: ${response.data}');
      }
      debugPrint('═════════════════════════════════════════');
    }
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final fullUrl = '${err.requestOptions.baseUrl}${err.requestOptions.path}';
      debugPrint('═════════════════════════════════════════');
      debugPrint('❌ ERROR');
      debugPrint('Method: ${err.requestOptions.method}');
      debugPrint('URL: $fullUrl');
      debugPrint('Status Code: ${err.response?.statusCode}');
      debugPrint('Error Message: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('Response Body: ${err.response?.data}');
      }
      debugPrint('Error Type: ${err.type}');
      debugPrint('═════════════════════════════════════════');
    }
    handler.next(err);
  }
}
