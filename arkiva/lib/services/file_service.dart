import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:arkiva/config/api_config.dart';

class FileService {
  // Fusion de fichiers PDF et images
  Future<Uint8List> mergeFiles({
    required String token,
    required List<String> fichiers,
    required int entrepriseId,
    required int dossierId,
    required String fileName,
  }) async {
    try {
      print('[API] POST ${ApiConfig.baseUrl}/api/fileManager/mergefile');
      print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
      print('[API] Body: {fichiers: $fichiers, entreprise_id: $entrepriseId, dossier_id: $dossierId, fileName: $fileName}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/fileManager/mergefile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fichiers': fichiers,
          'entreprise_id': entrepriseId,
          'dossier_id': dossierId,
          'fileName': fileName,
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Erreur lors de la fusion des fichiers';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors de la fusion des fichiers: $e');
    }
  }

  // Extraction de pages sélectionnées
  Future<Uint8List> extractSelectedPages({
    required String token,
    required List<Map<String, dynamic>> fichiers,
    required int entrepriseId,
  }) async {
    try {
      print('[API] POST \\${ApiConfig.baseUrl}/api/fileManager/extracfile');
      print('[API] Payload envoyé :');
      print(jsonEncode({
        'fichiers': fichiers,
        'entreprise_id': entrepriseId,
      }));
      print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/fileManager/extracfile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fichiers': fichiers,
          'entreprise_id': entrepriseId,
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Erreur lors de l\'extraction des pages';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'extraction des pages: $e');
    }
  }

  Future<int> getPdfPageCount({
    required String token,
    required String chemin,
    required int entrepriseId,
  }) async {
    try {
      print('[API] POST ${ApiConfig.baseUrl}/api/fileManager/getpagecount');
      print('[API] Payload envoyé :');
      print(jsonEncode({
        'chemin': chemin,
        'entreprise_id': entrepriseId,
      }));

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/fileManager/getpagecount'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chemin': chemin,
          'entreprise_id': entrepriseId,
        }),
      );

      print('[API] Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['pageCount'] as int;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[API] Erreur getPdfPageCount: $e');
      rethrow;
    }
  }
}
