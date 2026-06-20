import 'package:dio/dio.dart';

import '../../application/ports/i_auth_repository.dart';

/// AOP — Aspecto de Seguridad.
/// Inyecta "Authorization: Bearer $token" en cada request automáticamente.
/// Si recibe 401, limpia la sesión.
class AuthInterceptor extends Interceptor {
  final IAuthRepository authRepository;

  AuthInterceptor(this.authRepository);

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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      authRepository.logout();
    }
    handler.next(err);
  }
}
