import 'package:flutter/material.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/screens/armoires_screen.dart';
import 'package:arkiva/screens/casiers_screen.dart';
import 'package:arkiva/screens/favoris_screen.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/services/animation_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/screens/entreprise_detail_screen.dart';
import 'package:arkiva/screens/create_user_screen.dart';
import 'package:arkiva/screens/admin_dashboard_screen.dart';
import 'package:arkiva/screens/login_screen.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/screens/tags_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _showCreateArmoireDialog(BuildContext context) async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une nouvelle armoire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'armoire',
                hintText: 'Ex: Armoire personnelle',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (facultatif)',
                hintText: 'Ex: Documents importants',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'nom': nomController.text,
                  'description': descriptionController.text,
                });
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null) {
      print('Nouvelle armoire à créer: Nom - ${result['nom']}, Description - ${result['description']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStateService = context.watch<AuthStateService>();
    final username = authStateService.username ?? 'Utilisateur';
    final userRole = authStateService.role;
    final token = authStateService.token;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('ARKIVA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Bonjour $username',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              _navigateToScreen(context, const ScanScreen());
            },
            tooltip: 'Scanner un document',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              _navigateToScreen(context, const UploadScreen());
            },
            tooltip: 'Téléverser un fichier',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              print('Notifications button pressed');
            },
            tooltip: 'Notifications',
          ),
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () {
                _navigateToScreen(context, const AdminDashboardScreen());
              },
              tooltip: 'Tableau de bord administrateur',
            ),
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                _navigateToScreen(context, const CreateUserScreen());
              },
              tooltip: 'Créer un utilisateur',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              print('Profile/Settings button pressed');
            },
            tooltip: 'Paramètres',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthStateService>().clearAuthState();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👋 Bonjour $username !',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 12),
                  FutureBuilder<int>(
                    future: token != null ? DocumentService().fetchDocumentsCount(token) : Future.value(0),
                    builder: (context, snapshot) {
                      final docCount = snapshot.data ?? 0;
                      return Text(
                        'Vous avez : 📂 ${authStateService.armoireCount ?? 0} armoires | 🗄️ ${authStateService.casierCount ?? 0} casiers',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  if (userRole == 'admin')
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _navigateToScreen(context, const EntrepriseDetailScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          elevation: 4,
                        ),
                        icon: Icon(Icons.business, color: Colors.white),
                        label: Text('Voir infos entreprise', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 30),

            InkWell(
              onTap: () {
                final authStateService = context.read<AuthStateService>();
                final entrepriseId = authStateService.entrepriseId;
                final userId = authStateService.userId;
                
                if (entrepriseId != null && userId != null) {
                  _navigateToScreen(
                    context,
                    ArmoiresScreen(
                      entrepriseId: entrepriseId,
                      userId: int.parse(userId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur: Informations d\'entreprise manquantes'),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vos Armoires',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                      ],
                    ),
                    SizedBox(height: 16),

                    // TODO: Afficher ici les armoires récentes ou un aperçu si nécessaire
                    // Pour l'instant, cette section est un raccourci vers ArmoiresScreen
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recherche Rapide',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '🔍 Rechercher un document, un dossier ou un mot-clé...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          ),
                          onChanged: (text) {
                            print('Search term: $text');
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          print('Filtres button pressed');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          elevation: 4,
                        ),
                        icon: Icon(Icons.filter_list, color: Colors.white),
                        label: Text('Filtres', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accès Rapide',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),

                  Column(
                    children: [
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.star, size: 28, color: Colors.amber[700]),
                          title: Text('Documents favoris', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            _navigateToScreen(context, const FavorisScreen());
                          },
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.history, size: 28, color: Colors.blue[700]),
                          title: Text('Documents récemment consultés', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            print('Tapped on Documents récemment consultés');
                          },
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.recent_actors, size: 28, color: Colors.green[700]),
                          title: Text('Derniers documents', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            print('Tapped on Derniers documents');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 