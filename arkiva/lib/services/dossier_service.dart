import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/config/api_config.dart';
import 'package:flutter/foundation.dart'; // Import pour kDebugMode

class DossierService {
  Future<List<Dossier>> getDossiers(String token, int casierId) async {
    print('[API] GET ' + '${ApiConfig.baseUrl}/api/dosier/$casierId');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/dosier/$casierId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Raw response body for getDossiers: ${response.body}');
      }
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Dossier.fromJson(json)).toList();
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? 'Unknown error';
      throw Exception('Échec du chargement des dossiers: $errorMessage (Status: ${response.statusCode})');
    }
  }

  Future<Dossier> createDossier(
    String token,
    int casierId,
    String nom,
    String description,
    int userId,
  ) async {
    print('[API] POST ' + '${ApiConfig.baseUrl}/api/dosier');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    print('[API] Body: {cassier_id: $casierId, nom: $nom, description: $description, user_id: $userId}');
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/dosier'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'cassier_id': casierId, // <-- correction ici
        'nom': nom,
        'description': description,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Dossier.fromJson(data['dossier']);
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Erreur inconnue';
      throw Exception(errorMessage);
    }
  }

  Future<void> updateDossier(
    String token,
    int? dossierId,
    String nom,
    String description,
  ) async {
    if (dossierId == null) {
      throw Exception('Dossier ID cannot be null for update.');
    }
    print('[API] PUT ' + '${ApiConfig.baseUrl}/api/dosier/$dossierId');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    print('[API] Body: {nom: $nom, description: $description}');
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/dosier/$dossierId'),
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

  Future<void> deleteDossier(String token, int? dossierId) async {
    if (dossierId == null) {
      throw Exception('Dossier ID cannot be null for delete.');
    }
    print('[API] DELETE ' + '${ApiConfig.baseUrl}/api/dosier/$dossierId');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/dosier/$dossierId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la suppression du dossier');
    }
  }

  // Déplacer un dossier vers un autre casier
  Future<Dossier> deplacerDossier(String token, int dossierId, int nouveauCasierId) async {
    try {
      print('[API] PUT ' + '${ApiConfig.baseUrl}/api/dosier/$dossierId/deplacer');
      print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
      print('[API] Body: {nouveau_casier_id: $nouveauCasierId}');
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/dosier/$dossierId/deplacer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nouveau_casier_id': nouveauCasierId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Dossier.fromJson(data['dossier']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Erreur lors du déplacement du dossier';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors du déplacement du dossier: $e');
    }
  }
} 