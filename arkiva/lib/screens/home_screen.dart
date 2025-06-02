import 'package:flutter/material.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/screens/armoires_screen.dart';
import 'package:arkiva/screens/casiers_screen.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/services/animation_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('ARKIVA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Bonjour [Nom Utilisateur]',
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
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              _navigateToScreen(context, const UploadScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              print('Notifications button pressed');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              print('Profile/Settings button pressed');
            },
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
                    '👋 Bonjour [Nom] !',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Vous avez : 📂 4 armoires | 🗄️ 20 casiers | 📄 235 documents',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      print('Voir les statistiques button pressed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      elevation: 4,
                    ),
                    child: Text('Voir les statistiques', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vos Armoires',
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
                        elevation: 3,
                        margin: EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: Icon(Icons.folder, size: 30, color: Colors.orange[700]),
                          title: Text('Armoire 1 - RH', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('4 casiers | Modifié le JJ/MM/AAAA', style: TextStyle(color: Colors.grey[700])),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            _navigateToScreen(context, CasiersScreen(armoire: Armoire(
                              id: '1',
                              nom: 'Armoire 1 - RH',
                              description: 'Documents administratifs',
                              dateCreation: DateTime.now(),
                              dateModification: DateTime.now(),
                            )));
                          },
                        ),
                      ),
                      Card(
                        elevation: 3,
                        margin: EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: Icon(Icons.folder, size: 30, color: Colors.orange[700]),
                          title: Text('Armoire 2 - Projets', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('2 casiers | Modifié le JJ/MM/AAAA', style: TextStyle(color: Colors.grey[700])),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            _navigateToScreen(context, CasiersScreen(armoire: Armoire(
                              id: '2',
                              nom: 'Armoire 2 - Projets',
                              description: 'Documents comptables',
                              dateCreation: DateTime.now(),
                              dateModification: DateTime.now(),
                            )));
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showCreateArmoireDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        elevation: 4,
                      ),
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text('Créer une nouvelle armoire', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
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
                            print('Tapped on Documents favoris');
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