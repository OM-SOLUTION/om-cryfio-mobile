import 'dart:convert';
import 'package:cryptography/cryptography.dart';

final class SrpPasswordDerivation {
  Future<SecretKey> derive({
    required String password,
    required List<int> salt,
    required int memoryKiB,
    required int iterations,
    required int parallelism
  }) async {
    if(salt.length != 16){
      throw ArgumentError.value(
        salt.length,
        'salt',
        'The current identity backup format requires a 16-byte salt.',
      );
    }
    if(memoryKiB < 64*1024 || iterations < 3 || parallelism < 4) {
      throw ArgumentError('Unsupported Argon2id parameters.');
    }
    final rootKey = await Argon2id(
      memory: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: 32
    ).deriveKeyFromPassword(password: password, nonce: salt);
    return Hkdf(
        hmac: Hmac.sha256(),
        outputLength: 32
    ).deriveKey(
      secretKey: rootKey,
      info: utf8.encode('om-cryfio/srp-password/v1')
    );
  }
}