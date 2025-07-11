import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/config/api_config.dart';

class VersionService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Créer une nouvelle version
  static Future<Map<String, dynamic>> createVersion({
    required String token,
    required int cibleId,
    required String type,
    String? versionNumber,
    String? description,
  }) async {
    try {
      print('[API] POST $baseUrl/api/versions');
      print('[API] Headers: {Content-Type: application/json, Authorization: Bearer $token}');
      print('[API] Body: {cible_id: $cibleId, type: $type, version_number: $versionNumber, description: $description}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/versions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'cible_id': cibleId,
          'type': type,
          if (versionNumber != null) 'version_number': versionNumber,
          if (description != null) 'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la création de la version');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir l'historique des versions
  static Future<List<Map<String, dynamic>>> getVersionHistory({
    required String token,
    required int cibleId,
    required String type,
  }) async {
    try {
      print('[API] GET $baseUrl/api/versions/cible/history?cible_id=$cibleId&type=$type');
      print('[API] Headers: {Authorization: Bearer $token}');
      final response = await http.get(
        Uri.parse('$baseUrl/api/versions/cible/history?cible_id=$cibleId&type=$type'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['versions'] ?? []);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération de l\'historique');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir le contenu d'une version
  static Future<Map<String, dynamic>> getVersionContent({
    required String token,
    required String versionId,
  }) async {
    try {
      print('[API] GET $baseUrl/api/versions/$versionId/content');
      print('[API] Headers: {Authorization: Bearer $token}');
      final response = await http.get(
        Uri.parse('$baseUrl/api/versions/$versionId/content'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération du contenu');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir l'URL de téléchargement d'une version
  static Future<String> getVersionDownloadUrl({
    required String token,
    required String versionId,
    int expiresIn = 3600,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/versions/$versionId/download-url?expiresIn=$expiresIn'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['download_url'];
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération de l\'URL de téléchargement');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Comparer deux versions
  static Future<Map<String, dynamic>> compareVersions({
    required String token,
    required String versionId1,
    required String versionId2,
  }) async {
    try {
      print('[API] POST $baseUrl/api/versions/compare');
      print('[API] Headers: {Content-Type: application/json, Authorization: Bearer $token}');
      print('[API] Body: {version_id_1: $versionId1, version_id_2: $versionId2}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/versions/compare'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'version_id_1': versionId1,
          'version_id_2': versionId2,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la comparaison des versions');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Supprimer une version
  static Future<void> deleteVersion({
    required String token,
    required String versionId,
  }) async {
    try {
      print('[API] DELETE $baseUrl/api/versions/$versionId');
      print('[API] Headers: {Authorization: Bearer $token}');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/versions/$versionId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la suppression de la version');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
} 