import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arkiva/config/api_config.dart';

class StatsService {
  static String get baseUrl => '${ApiConfig.baseUrl}/api/stats';

  Future<Map<String, dynamic>> getStatsGenerales(int entrepriseId, String token) async {
    print('[API] GET $baseUrl/entreprise/$entrepriseId');
    print('[API] Headers: {Authorization: Bearer $token}');
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur stats générales: ${response.body}');
    }
  }

  Future<List<dynamic>> getAdmins(int entrepriseId, String token) async {
    print('[API] GET $baseUrl/entreprise/$entrepriseId/admins');
    print('[API] Headers: {Authorization: Bearer $token}');
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/admins'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur admins: ${response.body}');
    }
  }

  Future<List<dynamic>> getContributeurs(int entrepriseId, String token) async {
    print('[API] GET $baseUrl/entreprise/$entrepriseId/contributeurs');
    print('[API] Headers: {Authorization: Bearer $token}');
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/contributeurs'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur contributeurs: ${response.body}');
    }
  }

  Future<List<dynamic>> getLecteurs(int entrepriseId, String token) async {
    print('[API] GET $baseUrl/entreprise/$entrepriseId/lecteurs');
    print('[API] Headers: {Authorization: Bearer $token}');
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/lecteurs'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur lecteurs: ${response.body}');
    }
  }

  Future<List<dynamic>> getStatsArmoires(int entrepriseId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/armoires'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur stats armoires: ${response.body}');
    }
  }

  Future<List<dynamic>> getActiviteRecente(int entrepriseId, String token, {int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/activite?limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur activité récente: ${response.body}');
    }
  }

  Future<List<dynamic>> getStatsTypesFichiers(int entrepriseId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/types-fichiers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur stats types fichiers: ${response.body}');
    }
  }

  Future<List<dynamic>> getCroissance(int entrepriseId, String token, {int mois = 12}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/croissance?mois=$mois'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur croissance: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTableauBord(int entrepriseId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/tableau-bord'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur tableau de bord: ${response.body}');
    }
  }

  Future<List<dynamic>> getLogs(int entrepriseId, String token, {int limit = 100, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/logs?limit=$limit&offset=$offset'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur logs: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getLogsStats(int entrepriseId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/logs/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur stats logs: ${response.body}');
    }
  }

  Future<List<dynamic>> getLogsParUtilisateur(int entrepriseId, String token, {int limit = 50}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/logs/utilisateurs?limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur logs par utilisateur: ${response.body}');
    }
  }

  Future<List<dynamic>> getLogsParAction(int entrepriseId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/logs/actions'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur logs par action: ${response.body}');
    }
  }

  Future<List<dynamic>> getLogsParCible(int entrepriseId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/logs/cibles'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur logs par cible: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTableauBordComplet(int entrepriseId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/tableau-bord-complet'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Erreur tableau de bord complet: ${response.body}');
    }
  }
} 