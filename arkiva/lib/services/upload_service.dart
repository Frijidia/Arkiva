import 'package:http/http.dart' as http;
import 'package:arkiva/config/api_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadService {
  Future<void> uploadFile(
    String token,
    int dossierId,
    int entrepriseId,
    PlatformFile selectedFile,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/upload');
    var request = http.MultipartRequest('POST', url);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    request.fields['dossier_id'] = dossierId.toString();
    request.fields['entreprise_id'] = entrepriseId.toString();

    if (kIsWeb) {
      if (selectedFile.bytes == null) {
        throw Exception('File bytes are null on web.');
      }
      request.files.add(http.MultipartFile.fromBytes(
        'files',
        selectedFile.bytes!,
        filename: selectedFile.name,
      ));
    } else {
      if (selectedFile.path == null) {
        throw Exception('File path is null on non-web platforms.');
      }
      request.files.add(await http.MultipartFile.fromPath(
        'files',
        selectedFile.path!,
        filename: selectedFile.name,
      ));
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        print('Upload successful');
      } else {
        final responseBody = await response.stream.bytesToString();
        print('Upload failed with status ${response.statusCode}: $responseBody');
        throw Exception('Échec du téléversement du fichier: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Erreur lors du téléversement du fichier: $e');
    }
  }
} 