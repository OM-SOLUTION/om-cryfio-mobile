import 'package:flutter_test/flutter_test.dart';
import 'package:om_cryfio/core/crypto/password_derivation.dart';

void main() {
  test('derives separate backup and SRP values', () async {
    final keys = await PasswordDerivation().derive(
      password: 'test-password-only',
      salt: List<int>.generate(16, (index) => index),
      memoryKiB: 64 * 1024,
      iterations: 3,
      parallelism: 4,
    );

    final backupBytes = await keys.backupKey.extractBytes();
    final srpBytes = await keys.srpInput.extractBytes();

    expect(backupBytes, hasLength(32));
    expect(srpBytes, hasLength(32));

    // Different HKDF labels must produce different values.
    expect(backupBytes, isNot(orderedEquals(srpBytes)));
  });
}