import 'dart:convert';
import 'package:cryptography/cryptography.dart';

final class PasswordKeys {
  const PasswordKeys({
    required this.backupKey,
    required this.srpInput,
  });
  
  final SecretKey backupKey;
  final SecretKey srpInput;
}

final class PasswordDerivation {
  Future<PasswordKeys> derive({
    required String password,
    required List<int> salt,
    required int memoryKiB,
    required int iterations,
    required int parallelism
  }) async {
    final rootKey = await Argon2id(
      memory:  memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: 32,
    ).deriveKeyFromPassword(password: password, nonce: salt);
    
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final backupKey = await hkdf.deriveKey(secretKey: rootKey,info:utf8.encode('om-cryfio/identity-backup-kek/v1'));
    final srpInput = await hkdf.deriveKey(secretKey: rootKey,info:utf8.encode('om-cryfio/srp-password/v1'));

    return PasswordKeys(backupKey: backupKey,srpInput: srpInput);

  }
  
  
}