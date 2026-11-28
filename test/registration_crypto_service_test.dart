import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:om_cryfio/features/auth/data/registration_crypto_service.dart';
import 'package:om_cryfio/core/crypto/identity_crypto.dart';

void main() {
  test('prepares an identity backup and SRP credentials', () async {
    final service = RegistrationCryptoService();
    final identityCrypto = IdentityCrypto();

    const email = 'test@example.com';
    const password = 'test-password-only';
    const accountId = '11111111-1111-4111-8111-111111111111';

    final prepared = await service.prepare(
      password: password,
      accountId: accountId,
    );

    try {
      // Create the verifier using the backup's salt and the SRP input
      // derived by prepare().
      final credentials = await service.createSrpCredentials(
        email: email,
        prepared: prepared,
      );

      expect(credentials.verifier, hasLength(384));

      final credentialsJson = credentials.toJson();
      expect(credentialsJson['protocol'], 'SRP-6a');

      final verifierBytes = base64Url.decode(
        credentialsJson['verifier'] as String,
      );
      expect(verifierBytes, orderedEquals(credentials.verifier));

      // Confirm that preparing the SRP verifier did not affect the backup.
      final recovered = await identityCrypto.decryptPrivateKeyBackup(
        password: password,
        accountId: accountId,
        backup: prepared.payload.privateKeyBackup,
      );

      try {
        expect(
          recovered.publicKey,
          orderedEquals(prepared.identity.publicKey),
        );
        expect(
          recovered.privateKey,
          orderedEquals(prepared.identity.privateKey),
        );
      } finally {
        recovered.destroy();
      }
    } finally {
      prepared.destroy();
    }
  },timeout: const Timeout(Duration(minutes: 2)));;
  test('creates the complete registration payload', () async {
    final service = RegistrationCryptoService();

    const password = 'test-password-only';

    final payload = await service.createRegistrationPayload(
      email: 'test@example.com',
      password: password,
      accountId: '11111111-1111-4111-8111-111111111111',
    );

    expect(payload['schemaVersion'], 1);

    final identity = payload['encryptionIdentity'] as Map<String, dynamic>;
    expect(identity['algorithm'], 'X25519');
    expect(identity['publicKey'], isA<String>());

    final backup = payload['privateKeyBackup'] as Map<String, dynamic>;
    expect(backup['publicKey'], identity['publicKey']);
    expect(backup['kdf'], isA<Map>());
    expect(backup['cipher'], isA<Map>());

    final srp = payload['srpCredentials'] as Map<String, dynamic>;
    expect(srp['protocol'], 'SRP-6a');
    expect(srp['groupId'], 'RFC5054_3072');
    expect(srp['hashAlgorithm'], 'SHA-256');

    final verifier = base64Url.decode(srp['verifier'] as String);
    expect(verifier, hasLength(384));

    // Check that our test password was not placed in the JSON payload.
    expect(jsonEncode(payload), isNot(contains(password)));
  },timeout: const Timeout(Duration(minutes: 2)));
}