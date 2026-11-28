import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:om_cryfio/core/network/api_providers.dart';
import 'package:om_cryfio/features/auth/data/datasources/auth_api.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthApi(apiClient.dio);
});
