import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:om_cryfio/features/auth/data/services/srp_verifier_generator.dart';

void main() {
  test('creates a fresh, correctly encoded SRP public value', () {
    final generator = SrpVerifierGenerator();

    final first = generator.createLoginEphemeral();
    final second = generator.createLoginEphemeral();

    expect(first.privateValue, greaterThan(BigInt.zero));
    expect(first.publicValue, hasLength(384));

    // Base64URL without "=" padding, as required by the API.
    expect(first.encodedPublicValue, isNot(contains('=')));

    final decoded = base64Url.decode(
      base64Url.normalize(first.encodedPublicValue),
    );

    expect(decoded, orderedEquals(first.publicValue));

    // Each login attempt must generate a fresh random value.
    expect(first.publicValue, isNot(orderedEquals(second.publicValue)));
  });
}