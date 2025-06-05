import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/armoire.dart';
import '../config/api_config.dart';

class ArmoireService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<Armoire>> getAllArmoires(int entrepriseId) async {
    try {
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

  Future<Armoire> createArmoire(int userId, int entrepriseId) async {
    try {
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
        throw Exception('Échec de la création de l\'armoire');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'armoire: $e');
    }
  }

  Future<Armoire> renameArmoire(int armoireId, String sousTitre) async {
    try {
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

  Future<void> deleteArmoire(int armoireId) async {
    try {
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