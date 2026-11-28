import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart' show randomBytes;
final class FileHeader{
  const FileHeader ({
    required this.version,
    required this.plainSize,
    required this.chunkSize,
    required this.fileVersionId,
    required this.noncePrefix
  });
  final int version;
  final int plainSize;
  final int chunkSize;
  final Uint8List fileVersionId;
  final Uint8List noncePrefix;

  Map<String,dynamic> toJson(){
    return {
      'format': 'om-cryfio-file',
      'version': version,
      'algorithm': 'AES-256-GCM',
      'plainSize': plainSize,
      'chunkSize': chunkSize,
      'fileVersionId': base64UrlEncode(fileVersionId),
      'noncePrefix': base64UrlEncode(noncePrefix),
    };
  }
  Uint8List toCanonicalBytes(){
    return Uint8List.fromList(utf8.encode(jsonEncode(toJson())));
  }
}

final class EncryptedChunk{
  const EncryptedChunk({
    required this.index,
    required this.isFinal,
    required this.ciphertext,
    required this.tag
  });
  final int index;
  final bool isFinal;
  final Uint8List ciphertext;
  final Uint8List tag;
}
final class EncryptedFile{
  const EncryptedFile({
    required this.header,
    required this.chunks
  });
  final FileHeader header;
  final List<EncryptedChunk> chunks;
}
final class FileCrypto {
  static const int formatVersion = 1;
  static const int defaultChunkSize = 1024 * 1024; // 1 MiB

  final AesGcm _aesGcm = AesGcm.with256bits();

  Future<SecretKey> newFileVersionKey() {
    return _aesGcm.newSecretKey();
  }


  Future<EncryptedFile> encryptBytes(
      List<int> plaintext, {
        required SecretKey fileKey,
      }) async {
    final header = FileHeader(
      version: formatVersion,
      plainSize: plaintext.length,
      chunkSize: defaultChunkSize,
      fileVersionId: randomBytes(16, random: SecureRandom.system),
      noncePrefix: randomBytes(4, random: SecureRandom.system),
    );

    final headerHash = await _hashHeader(header);
    final chunkCount = _chunkCount(
      plainSize: plaintext.length,
      chunkSize: header.chunkSize,
    );
    final chunks = <EncryptedChunk>[];
    for(var index = 0; index < chunkCount; index++){
      final start = index * header.chunkSize;
      final end = _minimum(
          start + header.chunkSize,
          plaintext.length
      );
      final isFinal = index == chunkCount - 1;
      final plainChunk = Uint8List.fromList(plaintext.sublist(start,end));

      final secretBox = await _aesGcm.encrypt(
          plainChunk,
          secretKey: fileKey,
          nonce: _chunkNonce(header.noncePrefix, index),
          aad: _chunkAad(
            headerHash: headerHash,
            chunkIndex: index,
            isFinal: isFinal,
          ),
      );
      chunks.add(
        EncryptedChunk(
            index: index,
            isFinal: isFinal,
            ciphertext: Uint8List.fromList(secretBox.cipherText),
            tag: Uint8List.fromList(secretBox.mac.bytes)
        ),
      );
    }
    return EncryptedFile(header: header, chunks: List.unmodifiable(chunks));
  }
  Future<Uint8List> decryptBytes(
      EncryptedFile encryptedFile, {
        required SecretKey fileKey,
  }) async {
    final header =  encryptedFile.header;
    if(header.version != formatVersion ||
      header.chunkSize != defaultChunkSize ||
      header.fileVersionId.length != 16 ||
      header.noncePrefix.length != 4 ||
      header.plainSize < 0
    ){
      throw const FormatException('Unsupported encrypted-file header.');
    }
    final expectedCount  = _chunkCount(
      plainSize: header.plainSize,
      chunkSize: header.chunkSize,
    );
    if(encryptedFile.chunks.length != expectedCount){
      throw const FormatException('Missing or unexpected encrypted chunks.');
    }
    final headerHash = await _hashHeader(header);
    final output = BytesBuilder(copy :false);
    for(var index = 0; index <expectedCount; index++){
      final chunk = encryptedFile.chunks[index];
      final isFinal = index == expectedCount - 1;
      if(chunk.index != index || chunk.isFinal != isFinal || chunk.tag.length != 16){
        throw const FormatException('Invalid encrypted-chunk sequence.');
      }
      final start = index * header.chunkSize;
      final expectedPlainLength  = _minimum(
        header.chunkSize,
        header.plainSize - start,
      );
      if(chunk.ciphertext.length != expectedPlainLength){
        throw const FormatException('Unexpected encrypted-chunk size.');
      }
      final plainChunk = await _aesGcm.decrypt(
          SecretBox(
              chunk.ciphertext,
              nonce: _chunkNonce(header.noncePrefix,index),
              mac: Mac(chunk.tag)
          ),
          secretKey: fileKey,
          aad : _chunkAad(
            headerHash: headerHash,
            chunkIndex: index,
            isFinal: isFinal,
          ),
      );
      output.add(plainChunk);
    }
    final plaintext = output.toBytes();
    if(plaintext.length != header.plainSize){
      throw const FormatException('Recovered file size is incorrect.');
    }
    return plaintext;
  }
  int _chunkCount({
    required int plainSize,
    required int chunkSize
  }){
    if(plainSize == 0){
      return 1;
    }
    return (plainSize + chunkSize - 1) ~/ chunkSize;
  }
  Future<Uint8List> _hashHeader(FileHeader header) async {
    final hash = await Sha256().hash(header.toCanonicalBytes());
    return Uint8List.fromList(hash.bytes);
  }
  Uint8List _chunkNonce(Uint8List prefix,int chunkIndex){
    final bytes = ByteData(12);
    for(var index = 0; index < 4; index++){
      bytes.setUint8(index,prefix[index]);
    }
    bytes.setUint64(4, chunkIndex, Endian.big);
    return bytes.buffer.asUint8List();
  }

  Uint8List _chunkAad({
    required Uint8List headerHash,
    required int chunkIndex,
    required bool isFinal,
  }){
    final bytes = BytesBuilder(copy: false)
        ..add(utf8.encode('om-cryfio/file/v1'))
        ..add(headerHash)
        ..add(_uint64(chunkIndex))
        ..add(<int>[isFinal ? 1 : 0]);
    return bytes.toBytes();
  }
  Uint8List _uint64(int value){
    final bytes = ByteData(8)..setUint64(0, value,Endian.big);
    return bytes.buffer.asUint8List();
  }
  int _minimum(int first,int second){
    return first < second ? first : second;
  }
  
}
