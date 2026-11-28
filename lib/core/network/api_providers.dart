import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:om_cryfio/core/network/api_client.dart';

/// One shared backend connection for the whole app.
final apiClientProvider = Provider<ApiClient>((ref) { return ApiClient();});