import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Récupérer les statistiques de l'entreprise
  Future<Map<String, dynamic>> getEntrepriseStats(int entrepriseId, String token) async {
    print('🔄 Récupération des statistiques de l\'entreprise...');
    
    final response = await http.get(
      Uri.parse('$baseUrl/entreprise/$entrepriseId/stats'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la récupération des statistiques: ${response.body}');
    }
  }

  // Récupérer la liste des utilisateurs
  Future<List<Map<String, dynamic>>> getUsers(String token) async {
    print('🔄 Récupération de la liste des utilisateurs...');
    
    final response = await http.get(
      Uri.parse('$baseUrl/auth/users'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Échec de la récupération des utilisateurs: ${response.body}');
    }
  }

  // Modifier les informations d'un utilisateur
  Future<void> updateUser(String token, int userId, Map<String, dynamic> userData) async {
    print('🔄 Mise à jour des informations de l\'utilisateur...');
    
    final response = await http.put(
      Uri.parse('$baseUrl/auth/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la mise à jour de l\'utilisateur: ${response.body}');
    }
  }

  // Modifier le rôle d'un utilisateur
  Future<void> updateUserRole(String token, int userId, String newRole) async {
    print('🔄 Mise à jour du rôle de l\'utilisateur...');
    
    final response = await http.put(
      Uri.parse('$baseUrl/auth/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'role': newRole}),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la mise à jour du rôle: ${response.body}');
    }
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String token, int userId) async {
    print('🔄 Suppression de l\'utilisateur...');
    
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la suppression de l\'utilisateur: ${response.body}');
    }
  }
} 