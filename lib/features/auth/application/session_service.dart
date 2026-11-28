import 'package:om_cryfio/features/auth/application/login_flow.dart';
import 'package:om_cryfio/features/auth/data/datasources/auth_api.dart';
import 'package:om_cryfio/features/auth/data/services/token_storage.dart';
final class SessionService {
  SessionService(
    this._loginFlow,
    this._tokenStorage,
    this._authApi
  );

  final LoginFlow _loginFlow;
  final RefreshTokenStore _tokenStorage;
  final AuthApi _authApi;

  String? _accessToken;
  Future<void>? _refreshInFlight;

  String? get accessToken => _accessToken;

  Future<void> login({
    required String email,
    required String password,
    required String deviceName
  }) async {
    final tokens = await _loginFlow.login(
        email: email,
        password: password,
        deviceName: deviceName
    );
    if(tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty){
      throw StateError('The backend returned an empty token.');
    }
    await _tokenStorage.saveRefreshToken(tokens.refreshToken);
    _accessToken = tokens.accessToken;
  }
  Future<void> refreshSession() async {
    final existing = _refreshInFlight;
    if(existing != null){
      return existing;
    }
    final operation = _performRefresh();
    _refreshInFlight = operation;
    try{
      await operation;
    } finally {
      if(identical(_refreshInFlight, operation)){
        _refreshInFlight = null;
      }
    }
  }
  Future<void> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if(refreshToken == null || refreshToken.isEmpty){
      throw StateError('No stored refresh token. Please log in.');
    }
    final tokens = await _authApi.refreshTokens(refreshToken: refreshToken);
    if(tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty){
      _accessToken = null;
      throw StateError('The backend returned an empty token.');
    }
    try{
      await _tokenStorage.saveRefreshToken(tokens.refreshToken);
    }catch(_){
      _accessToken = null;
      rethrow;
    }
    _accessToken = tokens.accessToken;
  }
}