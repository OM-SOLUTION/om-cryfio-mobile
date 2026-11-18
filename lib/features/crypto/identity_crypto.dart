import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart' show randomBytes;
/// Keep an instance only while the app is unlocked.
/// Never log, serialize, or send [privateKey] to the backend.
final class IdentityKeyPair {
  IdentityKeyPair({
    required Uint8List privateKey,
    required Uint8List publicKey,
  })  : _privateKey = privateKey,
        this.publicKey = publicKey;

  final Uint8List _privateKey;
  final Uint8List publicKey;

  Uint8List get privateKey => _privateKey;

  /// Best-effort memory cleanup. Dart cannot guarantee wiping all copies.
  void destroy() {
    _privateKey.fillRange(0, _privateKey.length, 0);
  }

  SimpleKeyPairData toX25519KeyPair() {
    return SimpleKeyPairData(
      _privateKey,
      publicKey: SimplePublicKey(
        publicKey,
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );
  }
}

/// This is the only object that may be stored by the backend.
/// It never contains a plaintext private key or password.
final class EncryptedIdentityBackup {
  const EncryptedIdentityBackup({
    required this.version,
    required this.publicKey,
    required this.salt,
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    required this.nonce,
    required this.ciphertext,
    required this.mac,
  });

  final int version;
  final Uint8List publicKey;
  final Uint8List salt;
  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final Uint8List nonce;
  final Uint8List ciphertext;
  final Uint8List mac;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'algorithm': 'X25519+Argon2id+HKDF-SHA256+AES-256-GCM',
      'publicKey': base64UrlEncode(publicKey),
      'kdf': {
        'algorithm': 'Argon2id',
        'salt': base64UrlEncode(salt),
        'memoryKiB': memoryKiB,
        'iterations': iterations,
        'parallelism': parallelism,
        'outputBytes': 32,
      },
      'cipher': {
        'algorithm': 'AES-256-GCM',
        'nonce': base64UrlEncode(nonce),
        'ciphertext': base64UrlEncode(ciphertext),
        'tag': base64UrlEncode(mac),
      },
    };
  }

  factory EncryptedIdentityBackup.fromJson(Map<String, dynamic> json) {
    final kdf = Map<String, dynamic>.from(json['kdf'] as Map);
    final cipher = Map<String, dynamic>.from(json['cipher'] as Map);

    final backup = EncryptedIdentityBackup(
      version: json['version'] as int,
      publicKey: Uint8List.fromList(base64Url.decode(json['publicKey'] as String)),
      salt: Uint8List.fromList(base64Url.decode(kdf['salt'] as String)),
      memoryKiB: kdf['memoryKiB'] as int,
      iterations: kdf['iterations'] as int,
      parallelism: kdf['parallelism'] as int,
      nonce: Uint8List.fromList(base64Url.decode(cipher['nonce'] as String)),
      ciphertext: Uint8List.fromList(base64Url.decode(cipher['ciphertext'] as String),),
      mac: Uint8List.fromList(base64Url.decode(cipher['tag'] as String)),
    );

    if (backup.version != 1 ||
        backup.publicKey.length != 32 ||
        backup.salt.length != 16 ||
        backup.nonce.length != 12 ||
        backup.mac.length != 16 ||
        backup.memoryKiB < 64 * 1024 ||
        backup.iterations < 3 ||
        backup.parallelism < 4) {
      throw const FormatException('Unsupported or weakened identity backup.');
    }

    return backup;
  }
}

final class IdentityCrypto {
  static const _backupFormatVersion = 1;
  static const _memoryKiB = 64 * 1024;
  static const _iterations = 3;
  static const _parallelism = 4;

  final X25519 _x25519 = X25519();
  final AesGcm _aesGcm = AesGcm.with256bits();

  Future<IdentityKeyPair> generateIdentity() async {
    final keyPair = await _x25519.newKeyPair();
    final extracted = await keyPair.extract();

    return IdentityKeyPair(
      privateKey: Uint8List.fromList(extracted.bytes),
      publicKey: Uint8List.fromList(extracted.publicKey.bytes),
    );
  }

  Future<EncryptedIdentityBackup> encryptPrivateKeyBackup({
    required String password,
    required String accountId,
    required IdentityKeyPair identity,
  }) async {
    final salt = randomBytes(16,random: SecureRandom.system);

    final kek = await _deriveBackupKek(
      password: password,
      salt: salt,
      memoryKiB: _memoryKiB,
      iterations: _iterations,
      parallelism: _parallelism,
    );

    final payload = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'version': _backupFormatVersion,
          'curve': 'X25519',
          'privateKey': base64UrlEncode(identity.privateKey),
          'publicKey': base64UrlEncode(identity.publicKey),
        }),
      ),
    );

    try {
      final secretBox = await _aesGcm.encrypt(
        payload,
        secretKey: kek,
        aad: _backupAad(accountId),
      );

      return EncryptedIdentityBackup(
        version: _backupFormatVersion,
        publicKey: identity.publicKey,
        salt: salt,
        memoryKiB: _memoryKiB,
        iterations: _iterations,
        parallelism: _parallelism,
        nonce: Uint8List.fromList(secretBox.nonce),
        ciphertext: Uint8List.fromList(secretBox.cipherText),
        mac: Uint8List.fromList(secretBox.mac.bytes),
      );
    } finally {
      payload.fillRange(0, payload.length, 0);
    }
  }

  Future<IdentityKeyPair> decryptPrivateKeyBackup({
    required String password,
    required String accountId,
    required EncryptedIdentityBackup backup,
  }) async {
    final kek = await _deriveBackupKek(
      password: password,
      salt: backup.salt,
      memoryKiB: backup.memoryKiB,
      iterations: backup.iterations,
      parallelism: backup.parallelism,
    );

    final cleartext = await _aesGcm.decrypt(
      SecretBox(backup.ciphertext,nonce: backup.nonce,mac: Mac(backup.mac),),
      secretKey: kek,
      aad: _backupAad(accountId),
    );

    final bytes = Uint8List.fromList(cleartext);

    try {
      final payload = Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map,);
      if (payload['version'] != _backupFormatVersion ||payload['curve'] != 'X25519') {
        throw const FormatException('Unsupported identity backup format.');
      }

      final identity = IdentityKeyPair(
        privateKey: Uint8List.fromList(base64Url.decode(payload['privateKey'] as String),),
        publicKey: Uint8List.fromList(base64Url.decode(payload['publicKey'] as String),),
      );

      if (identity.publicKey.length != 32 ||
          identity.privateKey.length != 32 ||
          base64UrlEncode(identity.publicKey) !=
              base64UrlEncode(backup.publicKey)) {
        identity.destroy();
        throw const FormatException('Identity backup integrity mismatch.');
      }

      return identity;
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  Future<SecretKey> _deriveBackupKek({
    required String password,
    required List<int> salt,
    required int memoryKiB,
    required int iterations,
    required int parallelism,
  }) async {
    final rootKey = await Argon2id(
      memory: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: 32,
    ).deriveKeyFromPassword(password: password,nonce: salt,);
    return Hkdf(hmac: Hmac.sha256(),outputLength: 32,)
        .deriveKey(secretKey: rootKey, info: utf8.encode('om-cryfio/identity-backup-kek/v1'));
  }

  List<int> _backupAad(String accountId) {
    return utf8.encode('om-cryfio/identity-backup/v1|account-id:$accountId',);
  }
}