// Fichier pour gérer l'upload audio sur Flutter Web
// Ce fichier utilise dart:html qui n'est disponible que sur le web

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Lire un blob URL et le convertir en bytes pour l'upload
Future<Uint8List> readBlobAsBytes(String blobUrl) async {
  final request = await html.HttpRequest.request(
    blobUrl,
    method: 'GET',
    responseType: 'arraybuffer',
  );
  
  // Le résultat est un ByteBuffer qu'on peut convertir en Uint8List
  final byteBuffer = request.response as ByteBuffer;
  return byteBuffer.asUint8List();
}

/// Créer un MultipartFile depuis un blob URL
Future<http.MultipartFile> createMultipartFileFromBlob(String blobUrl) async {
  final bytes = await readBlobAsBytes(blobUrl);
  
  return http.MultipartFile.fromBytes(
    'audio',
    bytes,
    filename: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
  );
}

