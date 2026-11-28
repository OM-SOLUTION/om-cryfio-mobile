import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:om_cryfio/features/auth/application/login_flow.dart';
import 'package:om_cryfio/features/auth/data/services/auth_providers.dart';

final loginFlowProvider = Provider<LoginFlow>((ref) {return LoginFlow(ref.watch(authApiProvider));});