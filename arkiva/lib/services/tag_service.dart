import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_state_service.dart';

class TagService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> getAllTags(String token, int entrepriseId) async {
    print('[API] GET $baseUrl/api/tag?entreprise_id=$entrepriseId');
    print('[API] Headers: {Authorization: Bearer $token}');
    final response = await http.get(
      Uri.parse('$baseUrl/api/tag?entreprise_id=$entrepriseId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('[API] Response status: ${response.statusCode}');
    print('[API] Response body: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des tags: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createTag(String token, int entrepriseId, String name, String color, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tag'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'color': color,
        'description': description,
        'entreprise_id': entrepriseId
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la création du tag');
    }
  }

  Future<void> renameTag(String token, int entrepriseId, int tagId, String newName) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/tag/$tagId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'newName': newName,
        'entreprise_id': entrepriseId
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors du renommage du tag');
    }
  }

  Future<void> deleteTag(String token, int entrepriseId, int tagId) async {
    print('[API] DELETE $baseUrl/api/tag/deletetag/$tagId');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    print('[API] Body: {entreprise_id: $entrepriseId}');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tag/deletetag/$tagId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: json.encode({'entreprise_id': entrepriseId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du tag');
    }
  }

  Future<List<String>> getPopularTags(String token, int entrepriseId, {int limit = 10}) async {
    print('[API] GET $baseUrl/api/tag/tagsPopular?entreprise_id=$entrepriseId');
    print('[API] Headers: {Authorization: Bearer $token}');
    final response = await http.get(
      Uri.parse('$baseUrl/api/tag/tagsPopular?entreprise_id=$entrepriseId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('[API] Response status: ${response.statusCode}');
    print('[API] Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['tags'] ?? []);
    } else {
      throw Exception('Erreur lors de la récupération des tags populaires: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> addTagToFile(String token, int entrepriseId, String fichierId, String nomTag) async {
    print('[API] POST $baseUrl/api/tag/addTagToFile');
    print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
    print('[API] Body: {fichier_id: $fichierId, nom_tag: $nomTag, entreprise_id: $entrepriseId}');
    final response = await http.post(
      Uri.parse('$baseUrl/api/tag/addTagToFile'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'fichier_id': int.parse(fichierId),
        'nom_tag': nomTag,
        'entreprise_id': entrepriseId
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur lors de l\'association du tag au fichier');
    }
  }

  Future<void> removeTagFromFile(String token, int entrepriseId, String fichierId, int tagId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tag/removeTagFromFile'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'fichier_id': int.parse(fichierId),
        'tag_id': tagId,
        'entreprise_id': entrepriseId
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l\'association tag-fichier');
    }
  }

  Future<List<dynamic>> getSuggestedTags(String token, int entrepriseId, String documentId) async {
    try {
      print('[API] POST $baseUrl/api/tag/Tagsuggested');
      print('[API] Headers: {Authorization: Bearer $token, Content-Type: application/json}');
      print('[API] Body: {fichier_id: $documentId}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/tag/Tagsuggested'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fichier_id': documentId,
        }),
      );
      print('[API] Response status: ${response.statusCode}');
      print('[API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> tags = data['tags'] ?? [];
        return tags.map((tag) => {'name': tag}).toList();
      } else {
        throw Exception('Erreur lors de la récupération des suggestions de tags: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des suggestions de tags: $e');
    }
  }
} 