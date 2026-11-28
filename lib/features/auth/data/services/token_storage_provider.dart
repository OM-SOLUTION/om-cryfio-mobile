import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:om_cryfio/features/auth/data/services/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref){return TokenStorage();});