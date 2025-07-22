import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/config/api_config.dart';

class BackupService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Créer une sauvegarde
  static Future<Map<String, dynamic>> createBackup({
    required String token,
    required String type,
    required int cibleId,
    required int entrepriseId,
  }) async {
    try {
      print('[API] POST $baseUrl/api/sauvegardes');
      print('[API] Headers: {Content-Type: application/json, Authorization: Bearer $token}');
      print('[API] Body: {type: $type, cible_id: $cibleId, entreprise_id: $entrepriseId}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/sauvegardes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'type': type,
          'cible_id': cibleId,
          'entreprise_id': entrepriseId,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la création de la sauvegarde');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir toutes les sauvegardes
  static Future<List<Map<String, dynamic>>> getAllBackups({
    required String token,
  }) async {
    try {
      print('[API] GET $baseUrl/api/sauvegardes');
      print('[API] Headers: {Authorization: Bearer $token}');
      final response = await http.get(
        Uri.parse('$baseUrl/api/sauvegardes'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération des sauvegardes');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir une sauvegarde par ID
  static Future<Map<String, dynamic>> getBackupById({
    required String token,
    required int backupId,
  }) async {
    try {
      print('[API] GET $baseUrl/api/sauvegardes/$backupId');
      print('[API] Headers: {Authorization: Bearer $token}');
      final response = await http.get(
        Uri.parse('$baseUrl/api/sauvegardes/$backupId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération de la sauvegarde');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Télécharger une sauvegarde
  static Future<String> getBackupDownloadUrl({
    required String token,
    required int backupId,
  }) async {
    try {
      final backup = await getBackupById(token: token, backupId: backupId);
      return backup['s3Location'] ?? backup['contenu_json']['s3Location'];
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'URL de téléchargement: $e');
      }
    }

  // Nettoyage des sauvegardes
  static Future<Map<String, dynamic>> runCleanup({
    required String token,
  }) async {
    try {
      print('[API] POST $baseUrl/api/sauvegardes/cleanup');
      print('[API] Headers: {Authorization: Bearer $token}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/sauvegardes/cleanup'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors du nettoyage');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
} 