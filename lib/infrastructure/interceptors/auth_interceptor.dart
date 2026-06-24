import 'package:dio/dio.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_auth_repository.dart';

class AuthInterceptor extends Interceptor {
  final IAuthRepository authRepository;

  AuthInterceptor({required this.authRepository});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await authRepository.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await authRepository.logout();
      // Router navigation would be handled by the app
    }
    handler.next(err);
  }
}
