import 'package:flutter/material.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/screens/dossiers_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/services/casier_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/widgets/deplacement_dialog.dart';
import 'package:provider/provider.dart';

class CasiersScreen extends StatefulWidget {
  final int armoireId;
  final String armoireNom;
  final int entrepriseId;

  const CasiersScreen({
    super.key,
    required this.armoireId,
    required this.armoireNom,
    required this.entrepriseId,
  });

  @override
  State<CasiersScreen> createState() => _CasiersScreenState();
}

class _CasiersScreenState extends State<CasiersScreen> {
  final CasierService _casierService = CasierService();
  List<Casier> _casiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCasiers();
  }

  Future<void> _loadCasiers() async {
    setState(() => _isLoading = true);
    try {
      final casiers = await _casierService.getCasiersByArmoire(widget.armoireId);
      setState(() {
        _casiers = casiers;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _renommerCasier(Casier casier) async {
    final TextEditingController nomController = TextEditingController(text: casier.nom);
    final TextEditingController descriptionController = TextEditingController(text: casier.description ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le casier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du casier',
                hintText: 'Ex: Casier 1',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description du casier',
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedCasier = await _casierService.renameCasier(casier.casierId, result['description'] ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sous-titre du casier mis à jour avec succès')),
        );
        await _loadCasiers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _creerCasier() async {
    final authStateService = context.read<AuthStateService>();
    final userId = authStateService.userId;

    if (userId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: Informations utilisateur manquantes')),
      );
      return;
    }

    try {
       await _casierService.createCasier(
         widget.armoireId,
         int.parse(userId),
       );
       await _loadCasiers();
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Casier créé avec succès')),
       );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création: ${e.toString()}')),
      );
    }
  }

  Future<void> _modifierCasier(Casier casier) async {
    final TextEditingController nomController = TextEditingController(text: casier.nom);
    final TextEditingController descriptionController = TextEditingController(text: casier.description ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le casier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description du casier',
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
              Navigator.pop(context, {
                'description': descriptionController.text,
              });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _casierService.renameCasier(casier.casierId, result['description'] ?? '');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _supprimerCasier(Casier casier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le casier'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce casier ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _casierService.deleteCasier(casier.casierId);
        await _loadCasiers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Casier supprimé avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deplacerCasier(Casier casier) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const DeplacementDialog(typeElement: 'casier'),
    );

    if (result != null) {
      try {
        await _casierService.deplacerCasier(casier.casierId, result['armoire_id']);
        await _loadCasiers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Casier déplacé avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du déplacement: $e')),
        );
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.armoireNom),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              print('Téléverser button pressed');
              // TODO: Naviguer vers l'écran de téléversement
            },
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: () {
              print('Scanner button pressed');
              // TODO: Naviguer vers l'écran de scan
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _creerCasier,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCasiers,
        child: _casiers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun casier dans cette armoire',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Créez votre premier casier',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _creerCasier,
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un casier'),
                    ),
                  ],
                ),
              )
            : Builder(
                builder: (context) {
                  print('Nombre de casiers à afficher : \\${_casiers.length}');
                  for (var casier in _casiers) {
                    print('Casier: \\${casier.casierId} - \\${casier.nom}');
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 casiers par ligne
                      childAspectRatio: 0.9, // Réduire le rapport d'aspect pour diminuer la largeur relative
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _casiers.length,
                    itemBuilder: (context, index) {
                      return _buildCasierCard(_casiers[index], index);
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _creerCasier,
        child: const Icon(Icons.add),
        tooltip: 'Créer un nouveau casier',
      ),
    );
  }

  Widget _buildCasierCard(Casier casier, int casierIndex) {
    bool isFirstCasier = casierIndex == 0;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DossiersScreen(
                casier: casier,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFirstCasier) ...[
                    Icon(Icons.folder_open, size: 40, color: Colors.orange[700]),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: Text(
                      casier.nom,
                      style: TextStyle(
                        fontSize: isFirstCasier ? 20 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: isFirstCasier ? 40 : 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (isFirstCasier && casier.description != null && casier.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        casier.description!,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Modifier le casier',
                    onPressed: () => _modifierCasier(casier),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: 'Supprimer le casier',
                    onPressed: () => _supprimerCasier(casier),
                  ),
                  IconButton(
                    icon: const Icon(Icons.move_to_inbox, size: 20),
                    tooltip: 'Déplacer le casier',
                    onPressed: () => _deplacerCasier(casier),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 