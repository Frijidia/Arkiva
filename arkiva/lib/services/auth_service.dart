import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entreprise.dart';
import 'dart:io';
import 'package:arkiva/config/api_config.dart';

class AuthService {
  Future<Map<String, dynamic>> registerAdmin({
    required String email,
    required String password,
    required String username,
  }) async {
    print('🔄 Envoi de la requête d\'inscription admin...');
    print('📤 Données envoyées:');
    print('   - Email: $email');
    print('   - Username: $username');
    print('   - Password: ********');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
      }),
    );

    print('📥 Réponse reçue:');
    print('   - Status code: ${response.statusCode}');
    print('   - Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('✅ Inscription réussie:');
      print('   - Token: ${data['token']?.substring(0, 10)}...');
      print('   - User ID: ${data['user']['id']}');
      return {
        'token': data['token'],
        'userId': data['user']['id'].toString(),
      };
    } else {
      print('❌ Échec de l\'inscription:');
      print('   - Erreur: ${response.body}');
      throw Exception('Échec de l\'inscription: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createEntreprise(Entreprise entreprise, String token) async {
    print('🔄 Envoi de la requête de création d\'entreprise...');
    print('📤 Données envoyées:');
    print('   - Nom: ${entreprise.nom}');
    print('   - Email: ${entreprise.email}');
    print('   - Téléphone: ${entreprise.telephone}');
    print('   - Adresse: ${entreprise.adresse}');
    print('   - Logo URL: ${entreprise.logoUrl}');
    print('   - Plan: ${entreprise.planAbonnement}');
    print('🔑 Envoi du token: ${token.substring(0, 10)}...');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/entreprise'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(entreprise.toJson()),
    );

    print('📥 Réponse reçue:');
    print('   - Status code: ${response.statusCode}');
    print('   - Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('✅ Création d\'entreprise réussie:');
      print('   - ID Entreprise: ${data['id']}');
      return data;
    } else {
      print('❌ Échec de la création d\'entreprise:');
      print('   - Erreur: ${response.body}');
      throw Exception('Échec de la création de l\'entreprise: ${response.body}');
    }
  }

  // Cette méthode sera implémentée pour gérer l'upload de fichier
  Future<Map<String, dynamic>> createEntrepriseWithLogo(Map<String, dynamic> entrepriseData, File logoFile, String token) async {
     print('🔄 Envoi de la requête de création d\'entreprise avec logo...');
     print('📤 Données envoyées:');
     print('   - Nom: ${entrepriseData['nom']}');
     print('   - Email: ${entrepriseData['email']}');
     print('   - Téléphone: ${entrepriseData['telephone']}');
     print('   - Adresse: ${entrepriseData['adresse']}');
     print('   - Fichier logo: ${logoFile.path.split('/').last}');
     print('🔑 Envoi du token: ${token.substring(0, 10)}...');

     final uri = Uri.parse('${ApiConfig.baseUrl}/api/entreprise');
     final request = http.MultipartRequest('POST', uri)
       ..headers['Authorization'] = 'Bearer $token';

     // Ajouter les champs texte
     entrepriseData.forEach((key, value) {
       request.fields[key] = value.toString();
     });

     // Ajouter le fichier logo
     request.files.add(await http.MultipartFile.fromPath(
       'logo', // Le nom du champ de fichier attendu par le backend
       logoFile.path,
     ));

     final streamedResponse = await request.send();
     final response = await http.Response.fromStream(streamedResponse);

     print('📥 Réponse reçue:');
     print('   - Status code: ${response.statusCode}');
     print('   - Body: ${response.body}');

     if (response.statusCode == 200 || response.statusCode == 201) {
       final data = jsonDecode(response.body);
       print('✅ Création d\'entreprise avec logo réussie:');
       print('   - ID Entreprise: ${data['id']}');
       return data;
     } else {
       print('❌ Échec de la création d\'entreprise avec logo:');
       print('   - Erreur: ${response.body}');
       throw Exception('Échec de la création de l\'entreprise avec logo: ${response.body}');
     }
  }

  Future<Map<String, dynamic>> getUserInfo(String token) async {
    print('🔄 Envoi de la requête pour récupérer les infos utilisateur...');
    print('🔑 Envoi du token: ${token.substring(0, 10)}...');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('📥 Réponse reçue:');
    print('   - Status code: ${response.statusCode}');
    print('   - Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Infos utilisateur reçues:');
      print('   - User ID: ${data['id']}');
      print('   - Email: ${data['email']}');
      print('   - Username: ${data['username']}');
      print('   - Role: ${data['role']}');
      print('   - Entreprise ID: ${data['entreprise_id']}');
      return data;
    } else {
      print('❌ Échec de la récupération des infos utilisateur:');
      print('   - Erreur: ${response.body}');
      throw Exception('Échec de la récupération des infos utilisateur: ${response.body}');
    }
  }

  // Nouvelle méthode pour récupérer les informations de l'entreprise
  Future<Map<String, dynamic>> getEntrepriseInfo(int entrepriseId, String token) async {
    print('🔄 Envoi de la requête pour récupérer les infos entreprise...');
    print('🔑 Envoi du token: ${token.substring(0, 10)}...');
    print('🏢 ID Entreprise: $entrepriseId');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/entreprise/$entrepriseId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('📥 Réponse reçue:');
    print('   - Status code: ${response.statusCode}');
    print('   - Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Infos entreprise reçues:');
      // Afficher quelques infos pour confirmation
      print('   - Nom: ${data['nom']}');
      print('   - Email: ${data['email']}');
      return data;
    } else {
      print('❌ Échec de la récupération des infos entreprise:');
      print('   - Erreur: ${response.body}');
      throw Exception('Échec de la récupération des infos entreprise: ${response.body}');
    }
  }

  // Nouvelle méthode pour mettre à jour les informations de l'entreprise
  Future<void> updateEntreprise(int entrepriseId, Map<String, dynamic> updatedData, String token) async {
    print('🔄 Envoi de la requête de mise à jour entreprise...');
    print('🔑 Envoi du token: ${token.substring(0, 10)}...');
    print('🏢 ID Entreprise: $entrepriseId');
    print('📤 Données envoyées: $updatedData');

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/entreprise/$entrepriseId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatedData),
    );

    print('📥 Réponse reçue:');
    print('   - Status code: ${response.statusCode}');
    print('   - Body: ${response.body}');

    if (response.statusCode != 200) {
      print('❌ Échec de la mise à jour de l\'entreprise:');
      print('   - Erreur: ${response.body}');
      throw Exception('Échec de la mise à jour de l\'entreprise: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print('🔄 Envoi de la requête de connexion...');
    print('📤 Données envoyées:');
    print('   - Email: $email');
    print('   - Password: ********');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    print('📥 Réponse reçue:');
    print('   - Status code: ${response.statusCode}');
    print('   - Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Connexion réussie:');
      print('   - Token: ${data['token']?.substring(0, 10)}...');
      print('   - User ID: ${data['user']['id']}');
      return {
        'token': data['token'],
        'userId': data['user']['id'].toString(),
      };
    } else {
      print('❌ Échec de la connexion:');
      print('   - Erreur: ${response.body}');
      throw Exception('Échec de la connexion: ${response.body}');
    }
  }

  // Nouvelle méthode pour créer un utilisateur pour une entreprise
  Future<void> createUser(int entrepriseId, Map<String, dynamic> userData, String token) async {
    print('🔄 Envoi de la requête de création d\'utilisateur...');
    print('🔑 Envoi du token: ${token.substring(0, 10)}...');
    print('🏢 ID Entreprise: $entrepriseId');
    print('📤 Données envoyées: ${userData['email']}, ${userData['username']}, Role: ${userData['role']}'); // Ne pas logger le mot de passe

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/entreprise/$entrepriseId/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userData),
    );

    print('📥 Réponse reçue:');
    print('   - Status code: ${response.statusCode}');
    print('   - Body: ${response.body}');

    if (response.statusCode != 201) { // Le code 201 Created est attendu pour une création réussie
      print('❌ Échec de la création de l\'utilisateur:');
      print('   - Erreur: ${response.body}');
      throw Exception('Échec de la création de l\'utilisateur: ${response.body}');
    }
     print('✅ Utilisateur créé avec succès');
  }
} 