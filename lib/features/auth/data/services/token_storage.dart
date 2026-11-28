import 'package:flutter_secure_storage/flutter_secure_storage.dart';
abstract interface class RefreshTokenStore{
  Future<void> saveRefreshToken(String refreshToken);
  Future<String?> readRefreshToken();
  Future<void> deleteRefreshToken();
}
final class TokenStorage implements RefreshTokenStore {
  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  static const _refreshTokenKey = 'auth.refresh_token';
  final FlutterSecureStorage _storage;
  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    if(refreshToken.isEmpty){
      throw ArgumentError('Refresh token cannot be empty.');
    }
    await _storage.write(
        key: _refreshTokenKey,
        value: refreshToken
    );
  }
  @override
  Future<String?> readRefreshToken(){
    return _storage.read(key: _refreshTokenKey);
  }
  @override
  Future<void> deleteRefreshToken(){
    return _storage.delete(key: _refreshTokenKey);
  }
}