import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TagService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> getAllTags(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tag'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des tags');
    }
  }

  Future<Map<String, dynamic>> createTag(String token, String name, String color, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tag'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'color': color, 'description': description}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la création du tag');
    }
  }

  Future<void> renameTag(String token, int tagId, String newName) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tag/$tagId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'newName': newName}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors du renommage du tag');
    }
  }

  Future<void> deleteTag(String token, int tagId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tag/deletetag/$tagId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du tag');
    }
  }

  Future<List<String>> getTagSuggestions(String token, {String mode = 'top', int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tag/tagsuggestions?mode=$mode&limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['tags'] ?? []);
    } else {
      throw Exception('Erreur lors de la récupération des suggestions de tags');
    }
  }

  Future<void> addTagToFile(String token, int fichierId, String nomTag) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tag/addTagToFile'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'fichier_id': fichierId, 'nom_tag': nomTag}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur lors de l\'association du tag au fichier');
    }
  }

  Future<void> removeTagFromFile(String token, int fichierId, int tagId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tag/removeTagFromFile'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'fichier_id': fichierId, 'tag_id': tagId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l\'association tag-fichier');
    }
  }
} 