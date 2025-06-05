import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_service.dart';
import 'package:arkiva/services/auth_state_service.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  String? _selectedRole = 'lecteur'; // Valeur par défaut pour le rôle

  bool _isLoading = false;

  final List<String> _roles = ['admin', 'contributeur', 'lecteur'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authStateService = Provider.of<AuthStateService>(context, listen: false);
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token == null || entrepriseId == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: non authentifié ou entreprise introuvable.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'username': _usernameController.text,
        'role': _selectedRole, // Utiliser le rôle sélectionné
      };

      try {
        await AuthService().createUser(
          entrepriseId,
          userData,
          token,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur créé avec succès !')),
        );
        _formKey.currentState!.reset();
         setState(() {
           _selectedRole = 'lecteur';
         });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la création de l\'utilisateur: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un nouvel utilisateur'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer l\'email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Mot de passe'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le mot de passe';
                        }
                         if (value.length < 6) {
                           return 'Le mot de passe doit contenir au moins 6 caractères';
                         }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le nom d\'utilisateur';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Rôle'),
                      value: _selectedRole,
                      items: _roles.map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role.capitalize()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner un rôle';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createUser,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Créer l\'utilisateur'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${this.substring(1)}";
    }
} 