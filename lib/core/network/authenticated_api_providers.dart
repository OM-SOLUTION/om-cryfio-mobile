import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:om_cryfio/core/network/api_providers.dart';
import 'package:om_cryfio/core/network/authenticated_api_client.dart';
import 'package:om_cryfio/features/auth/application/session_providers.dart';

final authenticatedApiClientProvider = Provider<Dio>((ref){
  final apiClient = ref.watch(apiClientProvider);
  final session = ref.watch(sessionServiceProvider);
  final dio = createAuthenticatedApiClient(
      baseUrl: apiClient.dio.options.baseUrl,
      getAccessToken: () => session.accessToken,
  );
  ref.onDispose(dio.close);
  return dio;
});