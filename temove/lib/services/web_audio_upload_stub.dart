// Stub pour les plateformes non-web
// Ce fichier ne sera jamais utilisé sur le web

import 'package:http/http.dart' as http;

/// Stub - ne devrait jamais être appelé
Future<http.MultipartFile> createMultipartFileFromBlob(String blobUrl) {
  throw UnsupportedError('createMultipartFileFromBlob is only supported on web');
}

