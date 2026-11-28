import 'dart:convert';
import 'dart:typed_data';

final class SrpCredentials {
  SrpCredentials(Uint8List verifier) : verifier = Uint8List.fromList(verifier){
    if(verifier.length != 384){
      throw ArgumentError('An RFC5054 3072-bit verifier must be encoded as 384 bytes.');
    }
  }
  final Uint8List verifier;

  Map<String,dynamic> toJson(){
    return {
      'protocol' : 'SRP-6a',
      'groupId' : 'RFC5054_3072',
      'hashAlgorithm' : 'SHA-256',
      'verifier' : base64UrlEncode(verifier)
    };
  }
}