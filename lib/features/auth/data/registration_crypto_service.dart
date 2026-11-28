import 'dart:convert';
import 'dart:typed_data';
import 'package:om_cryfio/features/auth/data/models/srp_credentials.dart';
import 'package:om_cryfio/features/auth/data/services/srp_verifier_generator.dart';
import 'package:om_cryfio/core/crypto/identity_crypto.dart';
import 'package:cryptography/cryptography.dart';


final class RegistrationCryptoPayload {
  const RegistrationCryptoPayload({
    required this.publicKey,
    required this.privateKeyBackup
  });

  final Uint8List publicKey;
  final EncryptedIdentityBackup privateKeyBackup;

  Map<String,dynamic> toJson(){
    return  {
      'schemaVersion': 1,
      'encryptionIdentity': {
        'algorithm': 'X25519',
        'publicKey': base64UrlEncode(publicKey),
      },
      'privateKeyBackup': privateKeyBackup.toJson(),
    };
  }
}

final class PreparedRegistration {
  const PreparedRegistration({
    required this.identity,
    required this.payload,
    required this.srpInput,
  });

  final IdentityKeyPair identity;
  final RegistrationCryptoPayload payload;
  final SecretKey srpInput;

  void destroy(){
    identity.destroy();
  }
}
final class RegistrationCryptoService {
  RegistrationCryptoService({
    IdentityCrypto? identityCrypto,
  }) : _identityCrypto = identityCrypto ?? IdentityCrypto();

  final IdentityCrypto _identityCrypto;

  Future<PreparedRegistration> prepare({
    required String password,
    required String accountId,
  }) async {
    final identity = await _identityCrypto.generateIdentity();
    try{
      final preparedBackup = await _identityCrypto.prepareIdentityBackup(
          password: password,
          accountId: accountId,
          identity: identity
      );
      return PreparedRegistration(
          identity: identity,
          payload: RegistrationCryptoPayload(
              publicKey: identity.publicKey,
              privateKeyBackup: preparedBackup.backup
          ),
          srpInput: preparedBackup.srpInput
      );
    }catch(_){
      identity.destroy();
      rethrow;
    }
  }
  Future<SrpCredentials> createSrpCredentials({
    required String email,
    required PreparedRegistration prepared,
  }) {
    return SrpVerifierGenerator().generate(
        email: email,
        salt: prepared.payload.privateKeyBackup.salt,
        srpInput: prepared.srpInput,
    );
  }
  Future<Map<String,dynamic>> createRegistrationPayload({
    required String email,
    required String password,
    required String accountId
  }) async {
    final prepared = await prepare(
        password: password,
        accountId: accountId
    );
    try{
      final credentials = await createSrpCredentials(
          email: email,
          prepared: prepared
      );
      return {
        ...prepared.payload.toJson(),
        'srpCredentials': credentials.toJson()
      };
    }finally{
      prepared.destroy();
    }
  }

}
