import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/config/api_config.dart';

class DossierService {
  Future<List<Dossier>> getDossiers(String token, int casierId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/dossiers/$casierId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Dossier.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement des dossiers');
    }
  }

  Future<Dossier> createDossier(
    String token,
    int casierId,
    String nom,
    String description,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/dossiers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'casier_id': casierId,
        'nom': nom,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return Dossier.fromJson(json.decode(response.body));
    } else {
      throw Exception('Échec de la création du dossier');
    }
  }

  Future<void> updateDossier(
    String token,
    int dossierId,
    String nom,
    String description,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/dossiers/$dossierId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'nom': nom,
        'description': description,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la mise à jour du dossier');
    }
  }

  Future<void> deleteDossier(String token, int dossierId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/dossiers/$dossierId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la suppression du dossier');
    }
  }
} 