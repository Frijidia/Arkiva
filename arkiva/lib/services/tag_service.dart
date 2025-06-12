import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_state_service.dart';

class TagService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> getAllTags(String token, int entrepriseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tag?entreprise_id=$entrepriseId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des tags');
    }
  }

  Future<Map<String, dynamic>> createTag(String token, int entrepriseId, String name, String color, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tag'),
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
      Uri.parse('$baseUrl/tag/$tagId'),
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
    final response = await http.delete(
      Uri.parse('$baseUrl/tag/deletetag/$tagId'),
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

  Future<List<String>> getTagSuggestions(String token, int entrepriseId, {String mode = 'top', int limit = 10}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tag/tagsuggestions'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'mode': mode,
        'limit': limit,
        'entreprise_id': entrepriseId
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['tags'] ?? []);
    } else {
      throw Exception('Erreur lors de la récupération des suggestions de tags');
    }
  }

  Future<void> addTagToFile(String token, int entrepriseId, int fichierId, String nomTag) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tag/addTagToFile'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'fichier_id': fichierId,
        'nom_tag': nomTag,
        'entreprise_id': entrepriseId
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur lors de l\'association du tag au fichier');
    }
  }

  Future<void> removeTagFromFile(String token, int entrepriseId, int fichierId, int tagId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tag/removeTagFromFile'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'fichier_id': fichierId,
        'tag_id': tagId,
        'entreprise_id': entrepriseId
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l\'association tag-fichier');
    }
  }
} 