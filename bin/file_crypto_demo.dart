import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:om_cryfio/features/crypto/file_crypto.dart';

String toBase64(List<int> bytes) => base64UrlEncode(bytes);

bool sameBytes(List<int> first, List<int> second) {
  if (first.length != second.length) {
    return false;
  }

  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }

  return true;
}

Future<void> main() async {
  final crypto = FileCrypto();
  final original = Uint8List(FileCrypto.defaultChunkSize + 73);

  for (var index = 0; index < original.length; index++) {
    original[index] = index % 251;
  }

  print('========== OM-CRYFIO FILE CRYPTO DEMO ==========');

  print('\nSTEP 1: Create a file-version key (DEK)');
  final fileKey = await crypto.newFileVersionKey();

  // Learning demo only. Never print a DEK in the real application.
  final rawFileKey = Uint8List.fromList(await fileKey.extractBytes());
  print('DEK, demo only: ${toBase64(rawFileKey)}');
  print('DEK length: ${rawFileKey.length} bytes');

  print('\nSTEP 2: Encrypt ${original.length} bytes');
  final encryptedFile = await crypto.encryptBytes(
    original,
    fileKey: fileKey,
  );

  print('Public header:');
  print(const JsonEncoder.withIndent('  ').convert(encryptedFile.header.toJson()));

  print('\nEncrypted chunks:');
  for (final chunk in encryptedFile.chunks) {
    print(
      'Chunk ${chunk.index}: '
          'ciphertext=${chunk.ciphertext.length} bytes, '
          'tag=${chunk.tag.length} bytes, '
          'final=${chunk.isFinal}',
    );
  }

  print('\nSTEP 3: Decrypt with the same DEK');
  final recovered = await crypto.decryptBytes(
    encryptedFile,
    fileKey: fileKey,
  );

  print('Recovered bytes: ${recovered.length}');
  print('Original and recovered data match: ${sameBytes(original, recovered)}');

  print('\nSTEP 4: Tamper with one encrypted byte');
  encryptedFile.chunks.first.ciphertext[0] ^= 0x01;

  try {
    await crypto.decryptBytes(
      encryptedFile,
      fileKey: fileKey,
    );

    print('ERROR: changed ciphertext was accepted.');
  } on SecretBoxAuthenticationError {
    print('Correct: AES-GCM rejected the modified ciphertext.');
  }

  rawFileKey.fillRange(0, rawFileKey.length, 0);
  original.fillRange(0, original.length, 0);

  print('\n========== DEMO COMPLETE ==========');
}