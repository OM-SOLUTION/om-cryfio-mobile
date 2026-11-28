import 'package:flutter_test/flutter_test.dart';
import 'package:om_cryfio/core/crypto/identity_crypto.dart';

void main() {
  test('identity backup can be encrypted and recovered', () async {
    final crypto = IdentityCrypto();
    final identity = await crypto.generateIdentity();

    const password = 'test-password-only';
    const accountId = '11111111-1111-4111-8111-111111111111';

    try {
      final prepared = await crypto.prepareIdentityBackup(
        password: password,
        accountId: accountId,
        identity: identity,
      );

      final recovered = await crypto.decryptPrivateKeyBackup(
        password: password,
        accountId: accountId,
        backup: prepared.backup,
      );

      try {
        expect(recovered.publicKey, orderedEquals(identity.publicKey));
        expect(recovered.privateKey, orderedEquals(identity.privateKey));
      } finally {
        recovered.destroy();
      }
    } finally {
      identity.destroy();
    }
  });
}