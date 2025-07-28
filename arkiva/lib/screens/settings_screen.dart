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

  // Widget helper pour les cartes de paramètres
  Widget _buildSettingsCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // Widget helper pour les champs de formulaire modernes
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  // Widget helper pour les boutons modernes
  Widget _buildModernButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    bool isLoading = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    SizedBox(width: 8),
                  ],
                  Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
      ),
    );
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoadingCreate = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token != null && entrepriseId != null) {
        await _adminService.createUser(
          token,
          entrepriseId,
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
          _selectedRole!,
        );

        // Réinitialiser le formulaire
        _emailController.clear();
        _passwordController.clear();
        _usernameController.clear();
        setState(() => _selectedRole = 'lecteur');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur créé avec succès')),
        );
      }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      } finally {
      setState(() => _isLoadingCreate = false);
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
      );
      if (response.statusCode == 200) {
        setState(() {
          _2faMessage = 'Code envoyé par email. Vérifiez votre boîte de réception.';
        });
      } else {
        setState(() {
          _2faMessage = 'Erreur: ${jsonDecode(response.body)['message'] ?? 'Erreur lors de l\'activation'}';
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
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Paramètres',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: isAdmin ? TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _build2FASection(),
                SizedBox(height: 20),
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
    return Container(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[50]!, Colors.grey[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
      child: Column(
              mainAxisSize: MainAxisSize.min,
        children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
            Icons.admin_panel_settings,
            size: 64,
                    color: Colors.grey[600],
                  ),
          ),
                SizedBox(height: 24),
          Text(
            'Accès restreint',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
            ),
          ),
                SizedBox(height: 12),
          Text(
            'Seuls les administrateurs peuvent accéder aux paramètres d\'administration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateUserTab() {
    return _isLoadingCreate
        ? Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: EdgeInsets.all(40),
              child: Column(
                children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Création de l\'utilisateur...'),
                  ],
                ),
              ),
            ),
          )
        : _buildSettingsCard(
                            'Créer un nouvel utilisateur',
            Icons.person_add,
            Colors.green[600]!,
            [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildModernTextField(
                            controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer l\'email';
                              }
                              return null;
                            },
                          ),
                    _buildModernTextField(
                            controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock,
                      isPassword: true,
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
                    _buildModernTextField(
                            controller: _usernameController,
                      label: 'Nom d\'utilisateur',
                      icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le nom d\'utilisateur';
                              }
                              return null;
                            },
                          ),
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                              labelText: 'Rôle',
                          prefixIcon: Icon(Icons.admin_panel_settings, color: Colors.blue[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
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
                    ),
                    _buildModernButton(
                      text: 'Créer l\'utilisateur',
                      onPressed: _createUser,
                      color: Colors.green[600]!,
                      isLoading: _isLoadingCreate,
                      icon: Icons.person_add,
                  ),
                ],
              ),
            ),
            ],
          );
  }

  Widget _build2FASection() {
    return _buildSettingsCard(
              'Sécurité : Double authentification (2FA)',
      Icons.security,
      Colors.orange[600]!,
      [
            if (!_is2FAEnabled) ...[
          _buildModernButton(
            text: 'Activer la 2FA par email',
            onPressed: _enable2FA,
            color: Colors.orange[600]!,
            isLoading: _is2FALoading,
            icon: Icons.lock,
          ),
          SizedBox(height: 16),
          _buildModernTextField(
                controller: _code2FAController,
            label: 'Code reçu par email',
            icon: Icons.code,
                ),
          SizedBox(height: 8),
          _buildModernButton(
            text: 'Vérifier le code',
            onPressed: _verify2FA,
            color: Colors.blue[600]!,
            isLoading: _is2FALoading,
            icon: Icons.verified,
          ),
        ] else ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
              ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'La double authentification est activée sur votre compte.',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
            ],
            if (_2faMessage != null) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _2faMessage!,
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
          ],
        ),
      ),
        ],
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
} 