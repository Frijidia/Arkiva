import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/models/document.dart';
import 'package:arkiva/config/api_config.dart';

class DocumentService {
  Future<List<Document>> getDocuments(String token, int? dossierId) async {
    if (dossierId == null) {
      throw Exception('Dossier ID cannot be null for fetching documents.');
    }
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fichier/$dossierId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['fichiers'] ?? [];
      return data.map((json) => Document.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement des documents');
    }
  }

  Future<Document> createDocument(
    String token,
    int? dossierId,
    String nom,
    String description,
    String type,
    int taille,
  ) async {
    if (dossierId == null) {
      throw Exception('Dossier ID cannot be null for creating a document.');
    }
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/fichier'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'dossier_id': dossierId,
        'nom': nom,
        'description': description,
        'type': type,
        'taille': taille,
      }),
    );

    if (response.statusCode == 201) {
      return Document.fromJson(json.decode(response.body));
    } else {
      throw Exception('Échec de la création du document');
    }
  }

  Future<Document> updateDocument(
    String token,
    String? documentId,
    String nom,
    String description,
  ) async {
    if (documentId == null) {
      throw Exception('Document ID cannot be null for update.');
    }
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/fichier/$documentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'nouveauNom': nom,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Document.fromJson(responseData['fichier']);
    } else {
      throw Exception('Échec de la mise à jour du document');
    }
  }

  Future<void> deleteDocument(String token, String? documentId) async {
    if (documentId == null) {
      throw Exception('Document ID cannot be null for delete.');
    }
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/fichier/$documentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la suppression du document');
    }
  }

  Future<int> fetchDocumentsCount(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/documents/count'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['count'];
    } else {
      throw Exception('Erreur lors du chargement du nombre de documents');
    }
  }
} 