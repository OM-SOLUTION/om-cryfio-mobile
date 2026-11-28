import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:om_cryfio/core/network/api_providers.dart';
import 'package:om_cryfio/features/auth/data/datasources/registration_api.dart';

final registrationApiProvider = Provider<RegistrationApi>((ref){
  final apiClient = ref.watch(apiClientProvider);
  return RegistrationApi(apiClient.dio);
});
