import 'package:dio/dio.dart';
Dio createAuthenticatedApiClient({
  required String baseUrl,
  required String? Function() getAccessToken,
}) {
  final backendUri =Uri.parse(baseUrl);
  final dio = Dio(
    BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Accept' : 'application/json',
          'Content-type' : 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),

        followRedirects: false
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options,handler) {
        final requestUri = options.uri;
        if(requestUri.scheme != backendUri.scheme ||
          requestUri.host != backendUri.host ||
          requestUri.port != backendUri.port  
        ){
          handler.reject(
            DioException(
              requestOptions: options,
              error: StateError('Request is outside the backend origin.')
            )
          );
          return;
        }
        final token = getAccessToken();
        if(token == null || token.isEmpty){
          handler.reject(
              DioException(
                requestOptions: options,
                error: StateError('No access token. Please log in.')
              )
          );
          return;
        }
        options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      }
    )
  );
  return dio;
}