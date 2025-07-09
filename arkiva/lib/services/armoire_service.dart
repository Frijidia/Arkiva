import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/armoire.dart';
import '../config/api_config.dart';

class ArmoireService {
  final String baseUrl = ApiConfig.baseUrl;

  // Récupérer toutes les armoires pour le déplacement
  Future<List<Map<String, dynamic>>> getAllArmoiresForDeplacement(int entrepriseId) async {
    try {
      print('[API] GET $baseUrl/api/armoire/$entrepriseId');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      final response = await http.get(
        Uri.parse('$baseUrl/api/armoire/$entrepriseId'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Échec du chargement des armoires');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des armoires: $e');
    }
  }

  // Récupérer les armoires par entreprise (méthode originale)
  Future<List<Armoire>> getAllArmoires(int entrepriseId) async {
    try {
      print('[API] GET $baseUrl/api/armoire/$entrepriseId');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      final response = await http.get(
        Uri.parse('$baseUrl/api/armoire/$entrepriseId'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Armoire.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des armoires');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des armoires: $e');
    }
  }

  // Récupérer tous les casiers pour le déplacement
  Future<List<Map<String, dynamic>>> getAllCasiers(int entrepriseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/casier/getcasiers'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Échec du chargement des casiers');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des casiers: $e');
    }
  }

  // Créer une armoire
  Future<Armoire> createArmoire(int userId, int entrepriseId) async {
    try {
      print('[API] POST $baseUrl/api/armoire');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      print('[API] Body: {\'user_id\': $userId, \'entreprise_id\': $entrepriseId}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/armoire'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'user_id': userId,
          'entreprise_id': entrepriseId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Armoire.fromJson(data['armoire']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Erreur inconnue';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Renommer une armoire
  Future<Armoire> renameArmoire(int armoireId, String sousTitre) async {
    try {
      print('[API] PUT $baseUrl/api/armoire/$armoireId');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      print('[API] Body: {\'sous_titre\': $sousTitre}');
      final response = await http.put(
        Uri.parse('$baseUrl/api/armoire/$armoireId'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'sous_titre': sousTitre,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Armoire.fromJson(data['armoire']);
      } else {
        throw Exception('Échec de la modification de l\'armoire');
      }
    } catch (e) {
      throw Exception('Erreur lors de la modification de l\'armoire: $e');
    }
  }

  // Supprimer une armoire
  Future<void> deleteArmoire(int armoireId) async {
    try {
      print('[API] DELETE $baseUrl/api/armoire/$armoireId');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/armoire/$armoireId'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de la suppression de l\'armoire');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'armoire: $e');
    }
  }
} 