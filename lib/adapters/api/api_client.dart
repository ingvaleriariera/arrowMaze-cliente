import 'package:dio/dio.dart';
import 'package:arrow_maze_cliente_copy/domain/exceptions/app_exceptions.dart';

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

  Never _throwIfCustomException(DioException dioErr) {
    if (dioErr.error is AppException) {
      throw dioErr.error as AppException;
    }
    throw dioErr;
  }

  Future<Map<String, dynamic>> get(String path, {Options? options}) async {
    try {
      final response = await _dio.get(path, options: options);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _throwIfCustomException(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(path, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _throwIfCustomException(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(path, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _throwIfCustomException(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      _throwIfCustomException(e);
    }
  }
}
