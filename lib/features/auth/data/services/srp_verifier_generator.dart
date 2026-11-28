import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:om_cryfio/features/auth/data/models/srp_credentials.dart';
import 'package:cryptography/helpers.dart' show randomBytes;

final class SrpLoginEphemeral {
  const SrpLoginEphemeral({
    required this.privateValue,
    required this.publicValue
  });
  final BigInt privateValue;
  final Uint8List publicValue;
  String get encodedPublicValue {
    return base64UrlEncode(publicValue).replaceAll('=', '');
  }
}

final class SrpClientProof {
  SrpClientProof({
    required this.clientProof,
    required Uint8List expectedServerProof,
  }) : _expectedServerProof = Uint8List.fromList(expectedServerProof);

  /// Base64URL-encoded M1, sent to the backend.
  final String clientProof;

  final Uint8List _expectedServerProof;

  /// Check the backend's M2 before accepting its tokens.
  bool verifyServerProof(String encodedProof) {
    try {
      final received = base64Url.decode(
        base64Url.normalize(encodedProof),
      );

      if (received.length != 32) {
        return false;
      }

      var difference = 0;

      for (var i = 0; i < 32; i++) {
        difference |= received[i] ^ _expectedServerProof[i];
      }

      return difference == 0;
    } on FormatException {
      return false;
    }
  }
}
final class SrpVerifierGenerator {
  static final BigInt _prime = BigInt.parse(
    'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1'
      '29024E088A67CC74020BBEA63B139B22514A08798E3404DD'
      'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245'
      'E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED'
      'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3'
      'DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5'
      'F83655D23DCA3AD961C62F356208552BB9ED529077096966D'
      '670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B'
      'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9'
      'DE2BCBF6955817183995497CEA956AE515D2261898FA0510'
      '15728E5A8AAAC42DAD33170D04507A33A85521ABDF1CBA64'
      'ECFB850458DBEF0A8AEA71575D060C7DB3970F85A6E1E4C7'
      'ABF5AE8CDB0933D71E8C94E04A25619DCEE3D2261AD2EE6B'
      'F12FFA06D98A0864D87602733EC86A64521F2B18177B200C'
      'BBE117577A615D6C770988C0BAD946E208E24FA074E5AB31'
      '43DB5BFCE0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF',
    radix: 16,
  );
  static final BigInt _generator = BigInt.from(5);
  final Sha256  _sha256 = Sha256();

  Future<SrpCredentials> generate({
    required String email,
    required Uint8List salt,
    required SecretKey srpInput,
  }) async {
    if(salt.length != 16){
      throw ArgumentError('Expected a 16-byte salt.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if(normalizedEmail.isEmpty){
      throw ArgumentError('Email cannot be empty.');
    }
    final inputBytes = Uint8List.fromList(await srpInput.extractBytes());
    try{
      final identityAndInput = BytesBuilder(copy: false)
          ..add(utf8.encode(normalizedEmail))
          ..addByte(0x3a)
          ..add(inputBytes);

      final innerHash = await _sha256.hash(identityAndInput.takeBytes());
      final saltedHashInput = BytesBuilder(copy: false)
          ..add(salt)
          ..add(innerHash.bytes);

      final xHash = await _sha256.hash(saltedHashInput.takeBytes());
      final x = _unsignedBigInt(xHash.bytes);

      final verifier = _generator.modPow(x,_prime);
      return SrpCredentials(_toFixedLength(verifier,384));
    } finally {
      inputBytes.fillRange(0, inputBytes.length,0);
    }
  }
  SrpLoginEphemeral createLoginEphemeral(){
    final random = randomBytes(32, random: SecureRandom.system);
    try{
      final privateValue = _unsignedBigInt(random);
      if(privateValue == BigInt.zero){
        return createLoginEphemeral();
      }
      final publicValue = _generator.modPow(privateValue,_prime);
      return SrpLoginEphemeral(
          privateValue: privateValue,
          publicValue: _toFixedLength(publicValue, 384)
      );
    }finally{
      random.fillRange(0,random.length,0);
    }
  }
  Future<SrpClientProof> calculateClientProof({
    required String email,
    required Uint8List salt,
    required SecretKey srpInput,
    required SrpLoginEphemeral ephemeral,
    required String encodedServerPublicValue
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || salt.length != 16) {
      throw ArgumentError('Invalid email or salt.');
    }
    final serverBytes = base64Url.decode(base64Url.normalize(encodedServerPublicValue));
    if(serverBytes.length != 384){
      throw const FormatException('Server public value must contain exactly 384 bytes.');
    }
    final serverPublicValue = _unsignedBigInt(serverBytes);
    if(serverPublicValue <= BigInt.zero || serverPublicValue >= _prime){
      throw const FormatException('Invalid SRP server public value.');
    }
    final inputBytes = Uint8List.fromList(await srpInput.extractBytes());
    try{
      final identityAndInput = BytesBuilder(copy: false)
          ..add(utf8.encode(normalizedEmail))
          ..addByte(0x3a)
          ..add(inputBytes);

      final innerHash = await _sha256.hash(identityAndInput.takeBytes());
      final xInput = BytesBuilder(copy: false)
        ..add(salt)
        ..add(innerHash.bytes);
      final xHash = await _sha256.hash(xInput.takeBytes());
      final x = _unsignedBigInt(xHash.bytes);

      // k = H(PAD(N) || PAD(g))
      final kInput = BytesBuilder(copy: false)
        ..add(_toFixedLength(_prime, 384))
        ..add(_toFixedLength(_generator, 384));

      final kHash = await _sha256.hash(kInput.takeBytes());
      final k = _unsignedBigInt(kHash.bytes);

      // u = H(PAD(A) || PAD(B))
      final uInput = BytesBuilder(copy: false)
        ..add(ephemeral.publicValue)
        ..add(serverBytes);

      final uHash = await _sha256.hash(uInput.takeBytes());
      final u = _unsignedBigInt(uHash.bytes);

      if (u == BigInt.zero) {
        throw const FormatException('Invalid SRP scrambling parameter.');
      }

      // S = (B - k * g^x) ^ (a + u*x) mod N
      final gx = _generator.modPow(x, _prime);

      final base = (serverPublicValue - k * gx) % _prime;
      final exponent = ephemeral.privateValue + u * x;
      final sharedSecret = base.modPow(exponent, _prime);
      final paddedSecret = _toFixedLength(sharedSecret, 384);

      // M1 = H(PAD(A) || PAD(B) || PAD(S))
      final m1Input = BytesBuilder(copy: false)
        ..add(ephemeral.publicValue)
        ..add(serverBytes)
        ..add(paddedSecret);

      final m1 = await _sha256.hash(m1Input.takeBytes());

      // M2 = H(PAD(A) || PAD(M1) || PAD(S))
      final m2Input = BytesBuilder(copy: false)
        ..add(ephemeral.publicValue)
        ..add(_toFixedLength(_unsignedBigInt(m1.bytes), 384))
        ..add(paddedSecret);

      final m2 = await _sha256.hash(m2Input.takeBytes());
      return SrpClientProof(
          clientProof: base64UrlEncode(m1.bytes).replaceAll('=', ''),
          expectedServerProof: Uint8List.fromList(m2.bytes)
      );
    } finally {
      inputBytes.fillRange(0, inputBytes.length,0);
    }
  }
  BigInt _unsignedBigInt(List<int> bytes){
    var value = BigInt.zero;
    for(final byte in bytes){
      value = (value << 8) | BigInt.from(byte);
    }

    return value;
  }
  Uint8List _toFixedLength(BigInt value,int length){
    final result = Uint8List(length);
    var remaining = value;
    for(var index = length - 1; index >= 0;index --){
      result[index] = (remaining & BigInt.from(0xff)).toInt();
      remaining = remaining >> 8;
    }
    if(remaining != BigInt.zero){
      throw StateError('Verifier does not fit in $length bytes.');
    }

    return result;
  }

}