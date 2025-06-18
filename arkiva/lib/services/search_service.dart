import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SearchService {
  final String baseUrl = ApiConfig.baseUrl;

  // Recherche par tag
  Future<List<dynamic>> getFilesByTag(String token, int tagId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/search/$tagId/tag'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la recherche par tag');
    }
  }

  // Recherche par contenu OCR ou nom
  Future<List<dynamic>> searchByOcr(String token, String searchTerm) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/search/$searchTerm/ocr'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la recherche OCR');
    }
  }

  // Recherche par date
  Future<List<dynamic>> searchByDate(String token, String debut, String fin) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/search/seachbydate?debut=$debut&fin=$fin'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la recherche par date');
    }
  }

  // Recherche flexible (armoire, casier, dossier, nom)
  Future<List<dynamic>> searchFlexible(String token, {String? armoire, String? casier, String? dossier, String? nom}) async {
    final params = <String, String>{};
    if (armoire != null) params['armoire'] = armoire;
    if (casier != null) params['casier'] = casier;
    if (dossier != null) params['dossier'] = dossier;
    if (nom != null) params['nom'] = nom;

    final uri = Uri.parse('$baseUrl/api/search/seachbyname').replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la recherche flexible');
    }
  }
} 