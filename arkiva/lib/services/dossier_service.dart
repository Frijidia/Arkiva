import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/config/api_config.dart';
import 'package:flutter/foundation.dart'; // Import pour kDebugMode

class DossierService {
  Future<List<Dossier>> getDossiers(String token, int casierId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/dosier/$casierId'),
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
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/dosier'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'casier_id': casierId,
        'nom': nom,
        'description': description,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 201) {
      if (kDebugMode) {
        print('Raw response body for createDossier (201): ${response.body}');
      }
      final data = json.decode(response.body);
      return Dossier.fromJson(data['dossier']);
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? 'Unknown error';
      throw Exception('Échec de la création du dossier: $errorMessage (Status: ${response.statusCode})');
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
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/dosier/$dossierId'),
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
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/dosier/$dossierId'),
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