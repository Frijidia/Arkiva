import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/admin_service.dart';
import 'package:arkiva/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/config/api_config.dart';
import 'package:arkiva/screens/admin_dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  
  // Variables pour le dashboard admin
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>>? _users;
  bool _isLoadingAdmin = true;
  
  // Variables pour la création d'utilisateur
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  String? _selectedRole = 'lecteur';
  bool _isLoadingCreate = false;
  final List<String> _roles = ['admin', 'contributeur', 'lecteur'];

  // Ajout des variables pour la 2FA
  bool _is2FAEnabled = false;
  bool _is2FALoading = false;
  final TextEditingController _code2FAController = TextEditingController();
  String? _2faMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _code2FAController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoadingAdmin = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token != null && entrepriseId != null) {
        _stats = await _adminService.getEntrepriseStats(entrepriseId, token);
        _users = await _adminService.getUsers(token, entrepriseId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingAdmin = false);
    }
  }

  Future<void> _updateUserRole(int userId, String newRole) async {
    try {
      final token = context.read<AuthStateService>().token;
      if (token != null) {
        await _adminService.updateUserRole(token, userId, newRole);
        await _loadAdminData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rôle mis à jour avec succès')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final token = context.read<AuthStateService>().token;
      if (token != null) {
        await _adminService.deleteUser(token, userId);
        await _loadAdminData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur supprimé avec succès')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoadingCreate = true;
      });

      final authStateService = Provider.of<AuthStateService>(context, listen: false);
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token == null || entrepriseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: non authentifié ou entreprise introuvable.')),
        );
        setState(() {
          _isLoadingCreate = false;
        });
        return;
      }

      final userData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'username': _usernameController.text,
        'role': _selectedRole,
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
        await _loadAdminData(); // Recharger les données admin

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la création de l\'utilisateur: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoadingCreate = false;
        });
      }
    }
  }

  Future<void> _enable2FA() async {
    setState(() {
      _is2FALoading = true;
      _2faMessage = null;
    });
    try {
      final authStateService = Provider.of<AuthStateService>(context, listen: false);
      final token = authStateService.token;
      if (token == null) {
        setState(() {
          _2faMessage = 'Non authentifié.';
          _is2FALoading = false;
        });
        return;
      }
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/2fa/enable'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'method': 'email'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _2faMessage = 'Un code a été envoyé à votre email.';
        });
      } else {
        setState(() {
          _2faMessage = 'Erreur: ${jsonDecode(response.body)['message'] ?? 'Erreur lors de l\'activation de la 2FA'}';
        });
      }
    } catch (e) {
      setState(() {
        _2faMessage = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _is2FALoading = false;
      });
    }
  }

  Future<void> _verify2FA() async {
    setState(() {
      _is2FALoading = true;
      _2faMessage = null;
    });
    try {
      final authStateService = Provider.of<AuthStateService>(context, listen: false);
      final token = authStateService.token;
      if (token == null) {
        setState(() {
          _2faMessage = 'Non authentifié.';
          _is2FALoading = false;
        });
        return;
      }
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/2fa/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'code': _code2FAController.text.trim()}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _is2FAEnabled = true;
          _2faMessage = '2FA activée avec succès !';
        });
      } else {
        setState(() {
          _2faMessage = 'Erreur: ${jsonDecode(response.body)['message'] ?? 'Erreur lors de la vérification du code'}';
        });
      }
    } catch (e) {
      setState(() {
        _2faMessage = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _is2FALoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStateService = context.read<AuthStateService>();
    final userRole = authStateService.role;
    final isAdmin = userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        bottom: isAdmin ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.person_add),
              text: 'Créer Utilisateur',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: 'Dashboard Admin',
            ),
          ],
        ) : null,
      ),
      body: isAdmin ? TabBarView(
        controller: _tabController,
        children: [
          // Onglet Créer Utilisateur + 2FA
          SingleChildScrollView(
            child: Column(
              children: [
                _build2FASection(),
                _buildCreateUserTab(),
              ],
            ),
          ),
          // Onglet Dashboard Admin (nouveau dashboard moderne)
          AdminDashboardScreen(),
        ],
      ) : _buildNonAdminView(),
    );
  }

  Widget _buildNonAdminView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Accès restreint',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Seuls les administrateurs peuvent accéder aux paramètres d\'administration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateUserTab() {
    return _isLoadingCreate
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Créer un nouvel utilisateur',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Nom d\'utilisateur',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le nom d\'utilisateur';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Rôle',
                              border: OutlineInputBorder(),
                            ),
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoadingCreate ? null : _createUser,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoadingCreate
                                  ? const CircularProgressIndicator()
                                  : const Text('Créer l\'utilisateur'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _build2FASection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sécurité : Double authentification (2FA)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (!_is2FAEnabled) ...[
              ElevatedButton.icon(
                onPressed: _is2FALoading ? null : _enable2FA,
                icon: const Icon(Icons.lock),
                label: const Text('Activer la 2FA par email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _code2FAController,
                decoration: const InputDecoration(
                  labelText: 'Code reçu par email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _is2FALoading ? null : _verify2FA,
                child: _is2FALoading ? const CircularProgressIndicator() : const Text('Vérifier le code'),
              ),
            ] else ...[
              const Text('La double authentification est activée sur votre compte.', style: TextStyle(color: Colors.green)),
            ],
            if (_2faMessage != null) ...[
              const SizedBox(height: 8),
              Text(_2faMessage!, style: TextStyle(color: Colors.blue)),
            ],
          ],
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