import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:om_cryfio/features/auth/application/login_flow_providers.dart';
import 'package:om_cryfio/features/auth/application/session_service.dart';
import 'package:om_cryfio/features/auth/data/services/auth_providers.dart';
import 'package:om_cryfio/features/auth/data/services/token_storage_provider.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(
      ref.watch(loginFlowProvider),
      ref.watch(tokenStorageProvider),
      ref.watch(authApiProvider)
  );
});