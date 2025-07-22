import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/config/api_config.dart';

class RestoreService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Restaurer une sauvegarde
  static Future<Map<String, dynamic>> restoreBackup({
    required String token,
    required int backupId,
    int? armoireId,
    int? cassierId,
    int? dossierId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (armoireId != null) body['armoire_id'] = armoireId;
      if (cassierId != null) body['cassier_id'] = cassierId;
      if (dossierId != null) body['dossier_id'] = dossierId;
      print('[API] POST $baseUrl/api/restaurations/backup/$backupId');
      print('[API] Headers: {Content-Type: application/json, Authorization: Bearer $token}');
      print('[API] Body: ' + jsonEncode(body));
      final response = await http.post(
        Uri.parse('$baseUrl/api/restaurations/backup/$backupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body.isNotEmpty ? jsonEncode(body) : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la restauration de la sauvegarde');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Restaurer une version
  static Future<Map<String, dynamic>> restoreVersion({
    required String token,
    required String versionId,
  }) async {
    try {
      print('[API] POST $baseUrl/api/restaurations/version/$versionId');
      print('[API] Headers: {Content-Type: application/json, Authorization: Bearer $token}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/restaurations/version/$versionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la restauration de la version');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir toutes les restaurations
  static Future<List<Map<String, dynamic>>> getAllRestores({
    required String token,
  }) async {
    try {
      print('[API] GET $baseUrl/api/restaurations');
      print('[API] Headers: {Authorization: Bearer $token}');
      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurations'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération des restaurations');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir une restauration par ID
  static Future<Map<String, dynamic>> getRestoreById({
    required String token,
    required String restoreId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurations/$restoreId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération de la restauration');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir les détails d'une restauration
  static Future<Map<String, dynamic>> getRestoreDetails({
    required String token,
    required String restoreId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurations/$restoreId/details'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération des détails de restauration');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir les restaurations par type
  static Future<List<Map<String, dynamic>>> getRestoresByType({
    required String token,
    required String type,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurations/type/$type'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération des restaurations par type');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir les restaurations par entreprise
  static Future<List<Map<String, dynamic>>> getRestoresByEntreprise({
    required String token,
    required int entrepriseId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurations/entreprise/$entrepriseId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération des restaurations par entreprise');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir les restaurations par version
  static Future<List<Map<String, dynamic>>> getRestoresByVersion({
    required String token,
    required String versionId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurations/version/$versionId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération des restaurations par version');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Obtenir les restaurations par sauvegarde
  static Future<List<Map<String, dynamic>>> getRestoresByBackup({
    required String token,
    required int backupId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurations/backup/$backupId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la récupération des restaurations par sauvegarde');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Supprimer une restauration
  static Future<Map<String, dynamic>> deleteRestore({
    required String token,
    required String restoreId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/restaurations/$restoreId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur lors de la suppression de la restauration');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
} 