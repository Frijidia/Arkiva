import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SearchService {
  final String baseUrl = ApiConfig.baseUrl;

  // Recherche par tag
  Future<List<dynamic>> getFilesByTag(String token, int tagId, int entrepriseId) async {
    print('DEBUG: Appel getFilesByTag avec tagId: $tagId, entrepriseId: $entrepriseId');
    final url = '$baseUrl/api/search/$tagId/tag?entreprise_id=$entrepriseId';
    print('DEBUG: URL de recherche par tag: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    print('DEBUG: Status code de la réponse tag: ${response.statusCode}');
    print('DEBUG: Corps de la réponse tag: ${response.body}');
    
    if (response.statusCode == 200) {
      final results = json.decode(response.body);
      print('DEBUG: Résultats tag décodés: $results');
      print('DEBUG: Nombre de résultats tag: ${results.length}');
      return results;
    } else {
      print('DEBUG: Erreur lors de la recherche par tag: ${response.statusCode} - ${response.body}');
      throw Exception('Erreur lors de la recherche par tag');
    }
  }

  // Recherche par contenu OCR ou nom
  Future<List<dynamic>> searchByOcr(String token, String searchTerm, int entrepriseId) async {
    print('DEBUG: Appel searchByOcr avec searchTerm: "$searchTerm", entrepriseId: $entrepriseId');
    final url = '$baseUrl/api/search/$searchTerm/ocr?entreprise_id=$entrepriseId';
    print('DEBUG: URL de recherche OCR: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    print('DEBUG: Status code de la réponse OCR: ${response.statusCode}');
    print('DEBUG: Corps de la réponse OCR: ${response.body}');
    
    if (response.statusCode == 200) {
      final results = json.decode(response.body);
      print('DEBUG: Résultats OCR décodés: $results');
      return results;
    } else {
      print('DEBUG: Erreur lors de la recherche OCR: ${response.statusCode} - ${response.body}');
      throw Exception('Erreur lors de la recherche OCR');
    }
  }

  // Recherche par date
  Future<List<dynamic>> searchByDate(String token, String debut, String fin, int entrepriseId) async {
    final url = '$baseUrl/api/search/seachbydate?debut=$debut&fin=$fin&entreprise_id=$entrepriseId';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la recherche par date');
    }
  }

  // Recherche flexible (armoire, casier, dossier, nom)
  Future<List<dynamic>> searchFlexible(String token, int entrepriseId, {String? armoire, String? casier, String? dossier, String? nom}) async {
    final params = <String, String>{'entreprise_id': entrepriseId.toString()};
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