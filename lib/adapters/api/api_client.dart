import 'package:dio/dio.dart';

class ApiClient {
  final String baseUrl;
  final Dio _dio;
  String? _token;

  ApiClient({
    required this.baseUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _token = null;
    _dio.options.headers.remove('Authorization');
  }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Future<Map<String, dynamic>> get(String path, {Options? options}) async {
    final response = await _dio.get(path, options: options);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await _dio.post(path, data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final response = await _dio.put(path, data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
