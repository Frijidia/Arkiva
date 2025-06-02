import 'package:flutter/material.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/screens/dossiers_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/screens/scan_screen.dart';

class CasiersScreen extends StatefulWidget {
  final Armoire armoire;

  const CasiersScreen({
    super.key,
    required this.armoire,
  });

  @override
  State<CasiersScreen> createState() => _CasiersScreenState();
}

class _CasiersScreenState extends State<CasiersScreen> {
  late List<Casier> _casiers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _casiers = widget.armoire.casiers;
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
      // TODO: Mettre à jour le casier dans le backend
      setState(() {
        final index = _casiers.indexWhere((c) => c.id == casier.id);
        if (index != -1) {
          _casiers[index] = Casier(
            id: casier.id,
            nom: result['nom']!,
            armoireId: casier.armoireId,
            description: result['description'] ?? '',
            dossiers: casier.dossiers,
            dateCreation: casier.dateCreation,
            dateModification: DateTime.now(),
          );
        }
      });
    }
  }

  Future<void> _creerCasier() async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau casier'),
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null) {
      // TODO: Créer le casier dans le backend
      setState(() {
        _casiers.add(
          Casier(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            nom: result['nom']!,
            armoireId: widget.armoire.id,
            description: result['description'] ?? '',
            dossiers: [],
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
          ),
        );
      });
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
      // TODO: Mettre à jour le casier dans le backend
      setState(() {
        final index = _casiers.indexWhere((c) => c.id == casier.id);
        if (index != -1) {
          _casiers[index] = Casier(
            id: casier.id,
            nom: result['nom']!,
            armoireId: casier.armoireId,
            description: result['description'] ?? '',
            dossiers: casier.dossiers,
            dateCreation: casier.dateCreation,
            dateModification: DateTime.now(),
          );
        }
      });
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
      // TODO: Supprimer le casier dans le backend
      setState(() {
        _casiers.removeWhere((c) => c.id == casier.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.armoire.nom),
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _casiers.isEmpty
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
              : GridView.builder(
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
                ),
      floatingActionButton: _casiers.isNotEmpty
          ? FloatingActionButton(
              onPressed: _creerCasier,
              child: const Icon(Icons.add),
            )
          : null,
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
          print('Clic sur le casier: ${casier.nom}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DossiersScreen(casier: casier),
            ),
          );
        },
        onLongPress: () => _modifierCasier(casier),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFirstCasier) ...[
                    Icon(Icons.folder_open, size: 48, color: Colors.blue[700]),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: Text(
                      isFirstCasier ? 'C${casierIndex + 1}' : 'C${casierIndex + 1}',
                      style: TextStyle(
                        fontSize: isFirstCasier ? 24 : 20,
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
                    width: isFirstCasier ? 60 : 40,
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
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'modifier':
                      _modifierCasier(casier);
                      break;
                    case 'supprimer':
                      _supprimerCasier(casier);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'modifier',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'supprimer',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
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