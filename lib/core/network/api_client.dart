import 'package:dio/dio.dart';

const defaultApiBaseUrl  = String.fromEnvironment(
  'API_BASE_URL',defaultValue: 'http://localhost:8080'
);
/// Shared HTTP client for all backend API classes.
/// The UI never calls Dio directly.
/// It calls feature APIs such as RegistrationApi, FolderApi, or SessionApi.

final class ApiClient {
  ApiClient({
    Dio? dio,
    String? baseUrl,
  }) : dio = dio ?? Dio(
          BaseOptions(
            baseUrl: baseUrl ?? defaultApiBaseUrl ,
            headers: const{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        );
  final Dio dio;
}

