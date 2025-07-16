import 'dart:convert';
import 'dart:io';
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

  Future<void> uploadScannedDocuments({
    required String token,
    required List<File> files,
    required int dossierId,
    required int entrepriseId,
  }) async {
    try {
      print('[API] POST ${ApiConfig.baseUrl}/api/upload');
      print('[API] Upload de ${files.length} documents scannés');

      // Créer la requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/upload'),
      );

      // Ajouter les headers
      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter les champs
      request.fields['dossier_id'] = dossierId.toString();
      request.fields['entreprise_id'] = entrepriseId.toString();

      // Ajouter les fichiers
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        
        // S'assurer que le nom de fichier a l'extension .jpg
        String fileName = file.path.split('/').last;
        if (!fileName.toLowerCase().endsWith('.jpg') && !fileName.toLowerCase().endsWith('.jpeg')) {
          fileName = 'scanned_document_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        }
        
        print('[API] Ajout du fichier: $fileName (${await file.length()} bytes)');
        
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        
        final multipartFile = http.MultipartFile(
          'files',
          stream,
          length,
          filename: fileName,
        );
        
        request.files.add(multipartFile);
      }

      print('[API] Envoi de la requête...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('[API] Status: ${response.statusCode}');
      print('[API] Response: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        print('[API] Upload réussi: ${data['fichiers']?.length ?? 0} fichiers uploadés');
      } else {
        final errorData = jsonDecode(responseBody);
        final errorMessage = errorData['error'] ?? 'Erreur lors de l\'upload';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[API] Erreur uploadScannedDocuments: $e');
      rethrow;
    }
  }
} 