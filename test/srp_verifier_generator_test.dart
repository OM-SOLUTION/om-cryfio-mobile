import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_cryfio/features/auth/data/services/srp_verifier_generator.dart';

void main() {
  test('generates a deterministic 384-byte SRP verifier', () async {
    final generator = SrpVerifierGenerator();

    // Fixed values are appropriate here because this is a test.
    final salt = Uint8List.fromList(
      List<int>.generate(16, (index) => index),
    );

    final srpInput = SecretKey(
      List<int>.generate(32, (index) => index + 1),
    );

    final first = await generator.generate(
      email: 'test@example.com',
      salt: salt,
      srpInput: srpInput,
    );

    final second = await generator.generate(
      email: 'test@example.com',
      salt: salt,
      srpInput: srpInput,
    );

    // The API requires a 3072-bit, fixed-width verifier.
    expect(first.verifier, hasLength(384));
    final verifierHash = await Sha256().hash(first.verifier);

    final verifierHashHex = verifierHash.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    expect(
      verifierHashHex,
      '271413cb6ed764983409591b05d03e5dd9fb4d9a16668e11cf9cc3f1c5597bc3',
    );

    // Identical inputs must produce the same verifier.
    expect(first.verifier, orderedEquals(second.verifier));

    final json = first.toJson();

    expect(json['protocol'], 'SRP-6a');
    expect(json['groupId'], 'RFC5054_3072');
    expect(json['hashAlgorithm'], 'SHA-256');

    final decoded = base64Url.decode(json['verifier'] as String);
    expect(decoded, orderedEquals(first.verifier));
  });
}