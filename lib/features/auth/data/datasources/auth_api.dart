import 'package:dio/dio.dart';
final class SrpLoginChallenge{
  const SrpLoginChallenge({
    required this.challengeId,
    required this.passwordKdfSalt,
    required this.passwordKdfMemoryKiB,
    required this.passwordKdfIterations,
    required this.passwordKdfParallelism,
    required this.passwordKdfOutputBytes,
    required this.serverPublicValue
  });
  final String challengeId;
  final String passwordKdfSalt;
  final int passwordKdfMemoryKiB;
  final int passwordKdfIterations;
  final int passwordKdfParallelism;
  final int passwordKdfOutputBytes;
  final String serverPublicValue;
}
final class SrpLoginResult{
  const SrpLoginResult({
    required this.serverProof,
    required this.accessToken,
    required this.refreshToken,
  });
  final String serverProof;
  final String accessToken;
  final String refreshToken;
}
final class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;
  @override
  String toString() => 'AuthApiException: $message';
}
final class RefreshedTokens {
  const RefreshedTokens({
    required this.accessToken,
    required this.refreshToken
  });
  final String accessToken;
  final String refreshToken;
}
final class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;
  Future<SrpLoginChallenge> startSrpLogin({
    required String email,
    required String clientPublicValue
  }) async {
    try{
      final response = await _dio.post<dynamic>(
          '/api/v1/auth/srp/start',
        data: {
          'email' : email,
          'clientPublicValue': clientPublicValue
        },
      );
      final data = _successData(response);
      return SrpLoginChallenge(
          challengeId: data['challengeId'] as String,
          passwordKdfSalt: data['passwordKdfSalt'] as String,
          passwordKdfMemoryKiB: data['passwordKdfMemoryKiB'] as int,
          passwordKdfIterations: data['passwordKdfIterations'] as int,
          passwordKdfParallelism: data['passwordKdfParallelism'] as int,
          passwordKdfOutputBytes: data['passwordKdfOutputBytes'] as int,
          serverPublicValue: data['serverPublicValue'] as String,
      );
    } on DioException catch (error){
      throw _dioError(error);
    }
  }
  Future<SrpLoginResult> finishSrpLogin({
    required String challengeId,
    required String clientProof,
    required String deviceName
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/auth/srp/finish',
        data: {
          'challengeId' : challengeId,
          'clientProof' : clientProof,
          'deviceName' : deviceName,
        },
      );
      final data = _successData(response);
      return SrpLoginResult(
          serverProof: data['serverProof'] as String,
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String
      );
    } on DioException catch (error){
      throw _dioError(error);
    }
  }
  Future<RefreshedTokens> refreshTokens({
    required String refreshToken
  }) async {
    try{
      final response = await _dio.post<dynamic>(
        '/api/v1/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        }
      );
      final data = _successData(response);
      return RefreshedTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String
      );
    } on  DioException catch (error){
      throw _dioError(error);
    }
  }
  Map<String,dynamic> _successData(Response<dynamic> response){
    if(response.data is! Map){
      throw const AuthApiException('Backend returned an invalid response.');
    }
    final body = Map<String,dynamic>.from(response.data as Map);
    if(body['success'] != true){
      throw AuthApiException(body['message'] as String? ?? 'Authentication was rejected.');
    }
    if (body['data'] is! Map) {
      throw const AuthApiException('Backend response does not contain authentication data.',);
    }

    return Map<String,dynamic>.from(body['data'] as Map);
  }

  AuthApiException _dioError(DioException error){
    final body = error.response?.data;
    if(body is Map && body['message'] is String){
      return AuthApiException(body['message'] as String);
    }
    return AuthApiException('Authentication request failed: ${error.message}');
  }
}