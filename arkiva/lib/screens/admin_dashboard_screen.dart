import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>>? _users;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserRole(int userId, String newRole) async {
    try {
      final token = context.read<AuthStateService>().token;
      if (token != null) {
        await _adminService.updateUserRole(token, userId, newRole);
        await _loadData();
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
        await _loadData();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord administrateur'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistiques de l\'entreprise',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_stats != null) ...[
                        _buildStatItem('Nombre d\'utilisateurs', _stats!['nombre_utilisateurs']),
                        _buildStatItem('Nombre d\'armoires', _stats!['nombre_armoires']),
                        _buildStatItem('Nombre de fichiers', _stats!['nombre_fichiers']),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Liste des utilisateurs
              const Text(
                'Liste des utilisateurs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_users != null)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _users!.length,
                  itemBuilder: (context, index) {
                    final user = _users![index];
                    return Card(
                      child: ListTile(
                        title: Text(user['username'] ?? 'Sans nom'),
                        subtitle: Text('${user['email']} - ${user['role']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bouton pour modifier le rôle
                            PopupMenuButton<String>(
                              onSelected: (String newRole) {
                                _updateUserRole(user['user_id'], newRole);
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(
                                  value: 'admin',
                                  child: Text('Admin'),
                                ),
                                const PopupMenuItem(
                                  value: 'contributeur',
                                  child: Text('Contributeur'),
                                ),
                                const PopupMenuItem(
                                  value: 'lecteur',
                                  child: Text('Lecteur'),
                                ),
                              ],
                              child: const Icon(Icons.edit),
                            ),
                            // Bouton pour supprimer l'utilisateur
                            if (user['role'] != 'admin')
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmer la suppression'),
                                      content: Text(
                                          'Voulez-vous vraiment supprimer l\'utilisateur ${user['username']} ?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteUser(user['user_id']);
                                          },
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
} 