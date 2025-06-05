import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/screens/register_screen.dart';
import 'package:arkiva/services/auth_service.dart';
import 'package:arkiva/services/auth_state_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    print('🔄 Tentative de connexion...');

    try {
      final loginResponse = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Mettre à jour l'état d'authentification
      final authStateService = context.read<AuthStateService>();
      await authStateService.setAuthState(
        loginResponse['token'],
        loginResponse['userId'],
      );

      // Récupérer les informations complètes de l'utilisateur
      final userInfo = await _authService.getUserInfo(loginResponse['token']);
      final userRole = userInfo['role'];
      final entrepriseId = userInfo['entreprise_id'];

      if (!mounted) return;

      // Vérifier le rôle et l'entreprise_id
      if (userRole == 'admin' && (entrepriseId == 0 || entrepriseId == null)) {
        print('✅ Admin connecté sans entreprise, redirection vers la création d\'entreprise.');
        Navigator.of(context).pushReplacementNamed('/create-entreprise');
      } else {
        print('✅ Utilisateur connecté (Admin avec entreprise ou autre rôle), redirection vers l\'accueil.');
        Navigator.of(context).pushReplacementNamed('/home');
      }

    } catch (e) {
      print('❌ Erreur lors de la connexion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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