import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/models/document.dart';
import 'package:arkiva/config/api_config.dart';

class DocumentService {
  Future<List<Document>> getDocuments(String token, int? dossierId) async {
    if (dossierId == null) {
      throw Exception('Dossier ID cannot be null for fetching documents.');
    }
    print('[API] GET ' + '${ApiConfig.baseUrl}/api/fichier/$dossierId');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/fichier/$dossierId'),
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
    int? taille,
    String chemin,
  ) async {
    if (dossierId == null) {
      throw Exception('Dossier ID cannot be null for creating a document.');
    }
    print('[API] POST ' + '${ApiConfig.baseUrl}/api/fichier');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    print('[API] Body: {dossier_id: $dossierId, nom: $nom, description: $description, type: $type, taille: $taille, chemin: $chemin}');
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/fichier'),
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
        'chemin': chemin,
      }),
    );

    if (response.statusCode == 201) {
      return Document.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Erreur inconnue';
      throw Exception(errorMessage);
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
    print('[API] PUT ' + '${ApiConfig.baseUrl}/api/fichier/$documentId');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    print('[API] Body: {nouveauoriginalfilename: $nom, description: $description}');
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/fichier/$documentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'nouveauoriginalfilename': nom,
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
    print('[API] DELETE ' + '${ApiConfig.baseUrl}/api/fichier/$documentId');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/fichier/$documentId'),
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
      Uri.parse('${ApiConfig.baseUrl}/api/documents/count'),
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

  // Déplacer un fichier vers un autre dossier
  Future<Document> deplacerFichier(String token, String fichierId, int nouveauDossierId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/fichier/$fichierId/deplacer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nouveau_dossier_id': nouveauDossierId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Document.fromJson(data['fichier']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Erreur lors du déplacement du fichier';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors du déplacement du fichier: $e');
    }
  }
} 