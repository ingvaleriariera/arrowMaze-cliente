import 'package:dio/dio.dart';

class MockDio extends Dio {
  final Map<String, dynamic> mockResponses = {};
  String? lastPostPath;
  Map<String, dynamic>? lastPostBody;

  void setMockResponse(String path, Map<String, dynamic> response) {
    mockResponses[path] = response;
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = mockResponses[path];
    if (response != null) {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data: response as T,
        statusCode: 200,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      error: 'Mock response not found for $path',
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPostPath = path;
    lastPostBody = data as Map<String, dynamic>?;
    
    final response = mockResponses[path];
    if (response != null) {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data: response as T,
        statusCode: 200,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      error: 'Mock response not found for $path',
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 204,
    );
  }
}
