import 'dart:convert';
import 'dart:typed_data';
import 'package:om_cryfio/features/crypto/identity_crypto.dart';


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
  });
  final IdentityKeyPair identity;
  final RegistrationCryptoPayload payload;

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
      final backup = await _identityCrypto.encryptPrivateKeyBackup(
          password: password,
          accountId: accountId,
          identity: identity
      );
      return PreparedRegistration(
          identity: identity,
          payload: RegistrationCryptoPayload(
              publicKey: identity.publicKey,
              privateKeyBackup: backup
          )
      );
    }catch(_){
      identity.destroy();
      rethrow;
    }
  }
}
