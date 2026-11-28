import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:om_cryfio/features/auth/application/registration_flow.dart';
import 'package:om_cryfio/features/auth/data/services/registration_providers.dart';


final registrationFlowProvider = Provider<RegistrationFlow>((ref){
  final registrationApi = ref.watch(registrationApiProvider);
  return RegistrationFlow(registrationApi);
});