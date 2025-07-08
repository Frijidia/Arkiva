import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/casier.dart';
import '../config/api_config.dart';

class CasierService {
  final String baseUrl = ApiConfig.baseUrl;

  // Récupérer les casiers par armoire
  Future<List<Casier>> getCasiersByArmoire(int armoireId) async {
    try {
      print('[API] GET $baseUrl/api/casier/$armoireId');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      final response = await http.get(
        Uri.parse('$baseUrl/api/casier/$armoireId'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Casier.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des casiers');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des casiers: $e');
    }
  }

  // Créer un casier (le nom est généré par le backend)
  Future<Casier> createCasier(int armoireId, int userId) async {
    try {
      print('[API] POST $baseUrl/api/casier');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      print('[API] Body: {\'armoire_id\': $armoireId, \'user_id\': $userId}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/casier'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'armoire_id': armoireId,
          'user_id': userId, // Le backend a besoin du user_id
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        // Le backend retourne l'objet casier créé directement
        return Casier.fromJson(data['casier']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Erreur inconnue';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Renommer un casier (seulement le sous-titre est modifiable via cette route)
  Future<Casier> renameCasier(int casierId, String sousTitre) async {
     try {
      print('[API] PUT $baseUrl/api/casier/$casierId');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      print('[API] Body: {\'sous_titre\': $sousTitre}');
      final response = await http.put(
        Uri.parse('$baseUrl/api/casier/$casierId'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'sous_titre': sousTitre,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Casier.fromJson(data['cassier']); // Le backend utilise 'cassier' dans le JSON
      } else {
        throw Exception('Échec de la mise à jour du casier');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du casier: $e');
    }
  }

  // Supprimer un casier
  Future<void> deleteCasier(int casierId) async {
    try {
      print('[API] DELETE $baseUrl/api/casier/$casierId');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/casier/$casierId'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de la suppression du casier');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression du casier: $e');
    }
  }

  // Note: La route backend pour GetAllCasiers (/api/casier/getcasiers) existe
  // mais n'est pas utilisée ici car nous affichons les casiers par armoire.

  // Déplacer un casier vers une autre armoire
  Future<Casier> deplacerCasier(int casierId, int nouvelleArmoireId) async {
    try {
      print('[API] PUT $baseUrl/api/casier/$casierId/deplacer');
      print('[API] Headers: ${await ApiConfig.getHeaders()}');
      print('[API] Body: {\'nouvelle_armoire_id\': $nouvelleArmoireId}');
      final response = await http.put(
        Uri.parse('$baseUrl/api/casier/$casierId/deplacer'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'nouvelle_armoire_id': nouvelleArmoireId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Casier.fromJson(data['casier']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Erreur lors du déplacement du casier';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors du déplacement du casier: $e');
    }
  }
} 