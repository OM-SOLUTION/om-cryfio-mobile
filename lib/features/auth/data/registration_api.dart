import 'package:dio/dio.dart';
final class StartRegistrationRequest{
  const StartRegistrationRequest({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
  });
  final String email;
  final String firstName;
  final String lastName;
  final String username;

  Map<String,dynamic> toJson(){
    return  {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
    };
  }
}

final class PendingRegistration {
  const PendingRegistration({
    required this.accountId,
    required this.email,
    required this.status,
  });
  final String accountId;
  final String email;
  final String status;
}
final class VerifiedRegistration {
  const VerifiedRegistration({
    required this.accountId,
    required this.email,
    required this.status,
    required this.registrationToken,
  });
  final String accountId;
  final String email;
  final String status;
  final String registrationToken;

}
final class CompletedRegistration {
  const CompletedRegistration({
    required this.accountId,
    required this.status,
    required this.activatedAt,
  });
  final String accountId;
  final String status;
  final String? activatedAt;
}

final class RegistrationApiException implements Exception {
  const RegistrationApiException(this.message);
  final String message;
  @override
  String toString() => 'RegistrationApiException: $message';
}

final class RegistrationApi {
  RegistrationApi(this._dio);
  final Dio _dio;
  Future<PendingRegistration> start(StartRegistrationRequest request,)async {
    try{
      final response = await _dio.post<dynamic>(
          '/api/v1/registrations',
          data: request.toJson(),
      );
      final data = _successData(response);
      return PendingRegistration(
        accountId: data['accountId'] as String,
        email: data['email'] as String,
        status: data['status'] as String,
      );
    } on DioException catch (error) {
      throw _dioError(error);
    }
  }
  Future<VerifiedRegistration> verifyEmail({required String accountId, required String code,}) async {
    try{
      final response = await _dio.post<dynamic>(
        '/api/v1/registrations/$accountId/email-verification',
        data: {'code':code},
      );
      final data = _successData(response);
      return VerifiedRegistration(
          accountId: data['accountId'] as String,
          email: data['email'] as String,
          status: data['status'] as String,
          registrationToken: data['registrationToken'] as String,
      );
    } on DioException catch (error) {
      throw _dioError(error);
    }
  }
  Future<CompletedRegistration> uploadEncryptionMaterial({
    required String registrationToken,
    required Map<String, dynamic> encryptionMaterial,})
  async {
    try{
      final response = await _dio.put<dynamic>(
          '/api/v1/registrations/encryption-material',
          data: encryptionMaterial,
          options: Options(headers:{'Authorization': 'Bearer $registrationToken'})
      );
      final data = _successData(response);
      return CompletedRegistration(
        accountId: data['accountId'] as String,
        status: data['status'] as String,
        activatedAt: data['activatedAt'] as String?,
      );
    }on DioException catch (error) {
      throw _dioError(error);
    }
  }
  Map<String,dynamic> _successData(Response<dynamic> response){
    if(response.data is! Map){
      throw const RegistrationApiException('Backend returned an invalid response.');
    }
    final body = Map<String,dynamic>.from(response.data as Map);
    if(body['success'] != true){
      throw RegistrationApiException(body['message'] as String? ?? 'Request was rejected.');
    }
    if(body['data'] is! Map){
      throw const RegistrationApiException('Backend response does not contain data.');
    }
    return Map<String,dynamic>.from (body['data'] as Map);
  }
  RegistrationApiException _dioError(DioException error){
    final body = error.response?.data;
    if(body is Map && body['message'] is String){
      return RegistrationApiException(body['message'] as String);
    }
    return RegistrationApiException('Could not reach backend: ${error.message}');
  }

}