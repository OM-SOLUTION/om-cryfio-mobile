import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_cryfio/features/auth/data/services/srp_verifier_generator.dart';

void main() {
  test('calculates the expected client and server proofs', () async {
    final generator = SrpVerifierGenerator();

    // Fixed test-only SRP values. Never use these for a real login.
    const encodedA =
        'tbXlRF1yAkIPrN5_CqCXD9utnRzGBPcf_o4DcP7uoVZ4lyrM'
        'FN09dBro0jLNUtxd83WpalFQyKOyH06RJcmGIGvYO7rDRaO7'
        'BK9DQhnsqCkqh1tj9Ja5VvMt7RDGxPBc37D8cLML6cmzw7K'
        'bad8TQeSWReuuSCPZ-wD30ZFYOB72EUp2_O7PssAxwij2114'
        'QEYgvo_6MIYWjLw_JN3rdd10FGRHFDlUBxIv2JjBxtNh_MCjI'
        'RaGTYR_8_CYOr7QIn8bOHe-UkSb80IK5dit7DoBojVCmkPVp'
        'wfkL-lzojk_9AuN_0gVfFTuM12E4EzvSFF3TwA-Z0H7Z0vf'
        '47QZW29ZlS3bC3GWp0yhqV8YKdQodTYfCEGcVwhaxOEl1'
        'enj9Q-JSdW3HZ7TnyrZdQKRbEUd8A4Yy8qm58dWi2MQmZ'
        '-Xx__d3CGU0ACLHLGIqHvLUTfWfBlvKsYm1zdFpA6GbtX'
        'lR1BxxQl6hNhaPFSLqF25eilxnnutiK-AbB0gTittv';

    const encodedB =
        '9B_o5v7BZ_-oMLwFCp_FqBScNsf3AdIHlqnuZ2ery9MIRth1'
        'iBKtEALIiQ3pbra0ow6clVwGrR9z69SlljGy17MCCer3ypH'
        '8o1wcbyjcBF4aIchf8V55CYgyEcu7RGrX13CQSYjop_abyQ'
        'yfEEFYw2GJzc9Ay5t39usjHSOPD-6t_jBMrI3eWSyesRovw'
        'OZ2i0jR_WGqycnDAEOyg68COzlg6Rfo5vhHfhV-sEslmr2g'
        'C1l6bTV19VnDupNQ7v7wk5hN9ZaG9btGEstFb8UCcxE8p'
        'hIKobKM8xaEl41NvYeDxpx5mgXP3OE1sYgFp-5R9qDOl0W'
        'ztvDRylxjHUuyhfK7lMK5gy_cTH_RQ3h8m8dc9LrJP09KR5'
        'UF6vn8a4F820nCAmp0WuI5axasq-eFcjhfZrhCRFznnDiDA'
        'zVdDG9YMbGy57dOc5lMTpQitP7mKRbRPOd3_zC3n7cvab'
        'EY8vH15D4GJ9u4XoN8i-dDM2qBEAdTKN6Ea_c27NrBNY-j';

    final ephemeral = SrpLoginEphemeral(
      privateValue: BigInt.from(123456789),
      publicValue: Uint8List.fromList(
        base64Url.decode(base64Url.normalize(encodedA)),
      ),
    );

    final proof = await generator.calculateClientProof(
      email: 'test@example.com',
      salt: Uint8List.fromList(
        List<int>.generate(16, (index) => index),
      ),
      srpInput: SecretKey(
        List<int>.generate(32, (index) => index + 1),
      ),
      ephemeral: ephemeral,
      encodedServerPublicValue: encodedB,
    );

    expect(
      proof.clientProof,
      '7Sanbel5SBxOrDd4YqBuNKQB02BVvIwYisHO5yBSMUc',
    );

    expect(
      proof.verifyServerProof(
        'aNDJkwCdzcqpUu0Azq9y77Gjvspnz5Rl4GO3AvrX49o',
      ),
      isTrue,
    );

    expect(
      proof.verifyServerProof(
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      ),
      isFalse,
    );
  });
}