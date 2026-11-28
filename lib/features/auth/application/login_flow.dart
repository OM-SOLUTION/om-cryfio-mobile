import 'dart:convert';
import 'dart:typed_data';

import 'package:om_cryfio/core/crypto/password_derivation.dart';
import 'package:om_cryfio/features/auth/data/datasources/auth_api.dart';
import 'package:om_cryfio/features/auth/data/services/srp_verifier_generator.dart';

final class LoginTokens  {
  const LoginTokens({
    required this.accessToken,
    required this.refreshToken
  });
  final String accessToken;
  final String refreshToken;
}
final class LoginFlowException implements Exception{
  const LoginFlowException(this.message);
  final String message;
  @override
  String toString() => 'LoginFlowException: $message';
}
final class LoginFlow {
  LoginFlow(
    this._api,{
      PasswordDerivation? passwordDerivation,
      SrpVerifierGenerator? srp,
    }
  ) : _passwordDerivation = passwordDerivation ?? PasswordDerivation(),
      _srp = srp ?? SrpVerifierGenerator();
  
  final AuthApi _api;
  final PasswordDerivation _passwordDerivation;
  final SrpVerifierGenerator _srp;
    
  Future<LoginTokens> login({
    required String email,
    required String password,
    required String deviceName
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if(normalizedEmail.isEmpty || deviceName.trim().isEmpty){
      throw const LoginFlowException('Email and device name are required.');
    }
    final ephemeral = _srp.createLoginEphemeral();
    final challenge = await _api.startSrpLogin(
        email: normalizedEmail,
        clientPublicValue: ephemeral.encodedPublicValue
    );
    if(challenge.passwordKdfMemoryKiB != 64 * 1024 ||
        challenge.passwordKdfIterations != 3 ||
        challenge.passwordKdfParallelism != 4 ||
        challenge.passwordKdfOutputBytes != 32){
      throw const LoginFlowException('Unsupported password KDF parameters.');
    }
    Uint8List salt;
    try{
      salt = Uint8List.fromList(base64Url.decode(base64Url.normalize(challenge.passwordKdfSalt)));
    } on FormatException {
      throw const LoginFlowException('Invalid password KDF salt.');
    }
    if(salt.length != 16){
      throw const LoginFlowException('Invalid password KDF salt length.');
    }
    final keys = await _passwordDerivation.derive(
        password: password,
        salt: salt,
        memoryKiB: challenge.passwordKdfMemoryKiB,
        iterations: challenge.passwordKdfIterations,
        parallelism: challenge.passwordKdfParallelism
    );
    final proof = await _srp.calculateClientProof(
        email: normalizedEmail,
        salt: salt,
        srpInput: keys.srpInput,
        ephemeral: ephemeral,
        encodedServerPublicValue: challenge.serverPublicValue
    );

    final result = await _api.finishSrpLogin(
        challengeId: challenge.challengeId,
        clientProof: proof.clientProof,
        deviceName: deviceName
    );

    if(!proof.verifyServerProof(result.serverProof)){
      throw const LoginFlowException('Server proof verification failed.');
    }
    return LoginTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken
    );
  }

}