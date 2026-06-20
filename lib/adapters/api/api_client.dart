import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const String baseUrl = 'http://localhost:3000/api/v1';

  final Dio _dio;
  String? _token;

  ApiClient([Dio? dio]) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get(path, options: _options());
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(path, data: body, options: _options());
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(path, data: body, options: _options());
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path, options: _options());
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Options _options() {
    final token = _token;
    return Options(
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  ApiException _toApiException(DioException e) {
    return ApiException(e.response?.statusCode, e.message ?? 'Unknown network error');
  }
}
