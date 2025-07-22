import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/config/api_config.dart';
import 'package:arkiva/models/document.dart';

class FavorisService {
  final String _baseUrl = ApiConfig.baseUrl;

  // Récupérer tous les favoris d'un utilisateur
  Future<List<Document>> getFavoris(String token, int userId) async {
    try {
    print('[API] GET $_baseUrl/api/favoris/$userId');
    print('[API] Headers: {Authorization: Bearer $token}');
    final response = await http.get(
        Uri.parse('$_baseUrl/api/favoris/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Document.fromJson(json)).toList();
    } else {
        throw Exception('Erreur lors de la récupération des favoris: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Ajouter un fichier aux favoris
  Future<bool> addFavori(String token, int userId, int fichierId, int entrepriseId) async {
    try {
    print('[API] POST $_baseUrl/api/favoris');
    print('[API] Headers: {Content-Type: application/json, Authorization: Bearer $token}');
    print('[API] Body: {user_id: $userId, fichier_id: $fichierId, entreprise_id: $entrepriseId}');
    final response = await http.post(
        Uri.parse('$_baseUrl/api/favoris'),
      headers: {
          'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
        body: jsonEncode({
        'user_id': userId,
        'fichier_id': fichierId,
        'entreprise_id': entrepriseId,
      }),
    );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Erreur lors de l\'ajout aux favoris: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Retirer un fichier des favoris
  Future<bool> removeFavori(String token, int userId, int fichierId) async {
    try {
    print('[API] DELETE $_baseUrl/api/favoris/$userId/$fichierId');
    print('[API] Headers: {Authorization: Bearer $token}');
    final response = await http.delete(
        Uri.parse('$_baseUrl/api/favoris/$userId/$fichierId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Erreur lors de la suppression des favoris: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Vérifier si un fichier est en favori
  Future<bool> isFavori(String token, int userId, int fichierId) async {
    try {
      final favoris = await getFavoris(token, userId);
      return favoris.any((doc) => int.parse(doc.id) == fichierId);
    } catch (e) {
      return false;
    }
  }
} 