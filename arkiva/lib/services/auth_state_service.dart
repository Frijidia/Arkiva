import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arkiva/services/auth_service.dart';

class AuthStateService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  String? _userId;
  String? _username;
  int? _entrepriseId;
  String? _role;
  int? _armoireCount;
  int? _casierCount;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  int? get entrepriseId => _entrepriseId;
  String? get role => _role;
  int? get armoireCount => _armoireCount;
  int? get casierCount => _casierCount;

  Future<void> initialize() async {
    print('🔄 Initialisation de l\'état d\'authentification...');
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _isAuthenticated = _token != null;

    if (_isAuthenticated) {
      try {
        final userInfo = await AuthService().getUserInfo(_token!);
        _userId = userInfo['user_id']?.toString() ?? userInfo['id']?.toString();
        _username = userInfo['username'];
        _entrepriseId = userInfo['entreprise_id'];
        _role = userInfo['role'];
        print('   - User ID (from /me): $_userId');
        print('   - Username: $_username');
        print('   - Entreprise ID: $_entrepriseId');
        print('   - Role: $_role');
      } catch (e) {
        print('❌ Erreur lors de la récupération des infos utilisateur au démarrage: $e');
        await clearAuthState();
      }
    }
    
    print('📊 État d\'authentification:');
    print('   - Authentifié: $_isAuthenticated');
    print('   - User ID: $_userId');
    print('   - Username: $_username');
    print('   - Entreprise ID: $_entrepriseId');
    print('   - Role: $_role');
    
    notifyListeners();
  }

  Future<void> setAuthState(String token, String userIdParam) async {
    print('🔄 Mise à jour de l\'état d\'authentification...');
    print('   - User ID reçu (param): $userIdParam');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
    _isAuthenticated = true;

    try {
      final userInfo = await AuthService().getUserInfo(_token!);
      _userId = userInfo['user_id']?.toString() ?? userInfo['id']?.toString();
      _username = userInfo['username'];
      _entrepriseId = userInfo['entreprise_id'];
      _role = userInfo['role'];
      print('   - User ID (from /me): $_userId');
      print('   - Username: $_username');
      print('   - Entreprise ID: $_entrepriseId');
      print('   - Role: $_role');
    } catch (e) {
      print('❌ Erreur lors de la récupération des infos utilisateur après connexion: $e');
      await clearAuthState();
    }
    
    print('✅ État d\'authentification mis à jour');
    notifyListeners();
  }

  Future<void> clearAuthState() async {
    print('🔄 Suppression de l\'état d\'authentification...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    _token = null;
    _userId = null;
    _username = null;
    _entrepriseId = null;
    _role = null;
    _isAuthenticated = false;
    
    print('✅ État d\'authentification supprimé');
    notifyListeners();
  }

  void setArmoireCount(int count) {
    _armoireCount = count;
    notifyListeners();
  }

  void setCasierCount(int count) {
    _casierCount = count;
    notifyListeners();
  }

  void setEntrepriseAndUser(int entrepriseId, Map<String, dynamic> user) {
    _entrepriseId = entrepriseId;
    _userId = user['user_id']?.toString() ?? user['id']?.toString();
    _username = user['username'];
    _role = user['role'];
    notifyListeners();
  }
} 