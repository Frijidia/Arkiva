import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/screens/register_screen.dart';
import 'package:arkiva/services/auth_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/config/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _code2FAController = TextEditingController();
  bool _show2FA = false;
  String? _token;
  String? _errorMsg;
  bool _isLoading = false;
  final _authService = AuthService();
  int? _userId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _code2FAController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      }),
      );
    final data = jsonDecode(response.body);
    print('Réponse backend : ${response.body}'); // Log la réponse brute
    if (response.statusCode == 200) {
      final user = data['user'];
      if (user == null || user['user_id'] == null || user['role'] == null) {
        setState(() {
          _errorMsg = "Réponse du serveur incomplète. Veuillez contacter l'administrateur.";
          _isLoading = false;
        });
        print('Réponse inattendue : $data');
        return;
      }
      _token = data['token'];
      _userId = user['user_id'];
      if (user['two_factor_enabled'] == true) {
        setState(() { _show2FA = true; });
        // Optionnel : renvoyer un code à chaque tentative de login
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/2fa/enable'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'method': 'email'}),
        );
      } else {
        // Connexion normale
      final authStateService = context.read<AuthStateService>();
      await authStateService.setAuthState(
          _token!,
          _userId!.toString(),
        );
        final userInfo = await _authService.getUserInfo(_token!);
        final userRole = userInfo['role'];
        final entrepriseId = userInfo['entreprise_id'];
        if (!mounted) return;
        if (userRole == 'admin' && (entrepriseId == 0 || entrepriseId == null)) {
          print('✅ Admin connecté sans entreprise, redirection vers la création d\'entreprise.');
          Navigator.of(context).pushReplacementNamed('/create-entreprise');
        } else {
          print('✅ Utilisateur connecté (Admin avec entreprise ou autre rôle), redirection vers l\'accueil.');
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } else {
      setState(() { _errorMsg = data['message'] ?? 'Erreur de connexion'; });
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _verify2FA() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/2fa/verify'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': _code2FAController.text.trim()}),
      );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final newToken = data['token'];
      // Récupérer les informations complètes de l'utilisateur avec le nouveau token
      final userInfo = await _authService.getUserInfo(newToken);
      final userId = userInfo['user_id'].toString();
      final userRole = userInfo['role'];
      final entrepriseId = userInfo['entreprise_id'];
      final authStateService = context.read<AuthStateService>();
      await authStateService.setAuthState(
        newToken,
        userId,
      );
      if (!mounted) return;
      if (userRole == 'admin' && (entrepriseId == 0 || entrepriseId == null)) {
        print('✅ Admin connecté sans entreprise, redirection vers la création d\'entreprise.');
        Navigator.of(context).pushReplacementNamed('/create-entreprise');
      } else {
        print('✅ Utilisateur connecté (Admin avec entreprise ou autre rôle), redirection vers l\'accueil.');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      setState(() { _errorMsg = data['message'] ?? 'Code 2FA invalide'; });
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_show2FA) ...[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Se connecter'),
                ),
                ] else ...[
                  const Text('Un code de vérification a été envoyé à votre email.'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _code2FAController,
                    decoration: const InputDecoration(
                      labelText: 'Code 2FA',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le code de vérification';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verify2FA,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Vérifier le code'),
                  ),
                ],
                if (_errorMsg != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Pas encore de compte ? S\'inscrire'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 