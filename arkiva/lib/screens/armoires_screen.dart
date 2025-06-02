import 'package:flutter/material.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/models/document.dart';
import 'package:arkiva/screens/casiers_screen.dart';

class ArmoiresScreen extends StatefulWidget {
  const ArmoiresScreen({super.key});

  @override
  State<ArmoiresScreen> createState() => _ArmoiresScreenState();
}

class _ArmoiresScreenState extends State<ArmoiresScreen> {
  List<Armoire> _armoires = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArmoires();
  }

  void _loadArmoires() {
    // TODO: Charger les armoires depuis le backend
    setState(() {
      _armoires = [
        Armoire(
          id: '1',
          nom: 'Armoire Administrative',
          description: 'Documents administratifs et contrats',
          dateCreation: DateTime.now().subtract(const Duration(days: 30)),
          dateModification: DateTime.now(),
          casiers: [
            Casier(
              id: '1',
              nom: 'Contrats',
              description: 'Contrats et conventions',
              armoireId: '1',
              dateCreation: DateTime.now().subtract(const Duration(days: 25)),
              dateModification: DateTime.now(),
              dossiers: [
                Dossier(
                  id: '1',
                  nom: 'Contrats de travail',
                  casierId: '1',
                  description: 'Contrats de travail des employés',
                  dateCreation: DateTime.now().subtract(const Duration(days: 20)),
                  dateModification: DateTime.now(),
                  documents: [
                    Document(
                      id: '1',
                      nom: 'Contrat CDI.pdf',
                      type: 'pdf',
                      chemin: '',
                      taille: 1024 * 1024, // 1 Mo
                      dateAjout: DateTime.now().subtract(const Duration(days: 15)),
                      dateCreation: DateTime.now().subtract(const Duration(days: 15)),
                      dateModification: DateTime.now(),
                      description: 'Contrat type CDI',
                    ),
                    Document(
                      id: '2',
                      nom: 'Contrat CDD.pdf',
                      type: 'pdf',
                      chemin: '',
                      taille: 1024 * 512, // 512 Ko
                      dateAjout: DateTime.now().subtract(const Duration(days: 14)),
                      dateCreation: DateTime.now().subtract(const Duration(days: 14)),
                      dateModification: DateTime.now(),
                      description: 'Contrat type CDD',
                    ),
                  ],
                ),
                Dossier(
                  id: '2',
                  nom: 'Conventions',
                  casierId: '1',
                  description: 'Conventions avec les partenaires',
                  dateCreation: DateTime.now().subtract(const Duration(days: 18)),
                  dateModification: DateTime.now(),
                  documents: [
                    Document(
                      id: '3',
                      nom: 'Convention partenariat.docx',
                      type: 'docx',
                      chemin: '',
                      taille: 1024 * 256, // 256 Ko
                      dateAjout: DateTime.now().subtract(const Duration(days: 12)),
                      dateCreation: DateTime.now().subtract(const Duration(days: 12)),
                      dateModification: DateTime.now(),
                      description: 'Convention de partenariat avec XYZ',
                    ),
                  ],
                ),
              ],
            ),
            Casier(
              id: '2',
              nom: 'Factures',
              description: 'Factures clients et fournisseurs',
              armoireId: '1',
              dateCreation: DateTime.now().subtract(const Duration(days: 22)),
              dateModification: DateTime.now(),
              dossiers: [
                Dossier(
                  id: '3',
                  nom: 'Factures clients',
                  casierId: '2',
                  description: 'Factures émises aux clients',
                  dateCreation: DateTime.now().subtract(const Duration(days: 16)),
                  dateModification: DateTime.now(),
                  documents: [
                    Document(
                      id: '4',
                      nom: 'Facture 2024-001.pdf',
                      type: 'pdf',
                      chemin: '',
                      taille: 1024 * 128, // 128 Ko
                      dateAjout: DateTime.now().subtract(const Duration(days: 10)),
                      dateCreation: DateTime.now().subtract(const Duration(days: 10)),
                      dateModification: DateTime.now(),
                      description: 'Facture client ABC',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Armoire(
          id: '2',
          nom: 'Armoire RH',
          description: 'Documents ressources humaines',
          dateCreation: DateTime.now().subtract(const Duration(days: 20)),
          dateModification: DateTime.now(),
          casiers: [
            Casier(
              id: '3',
              nom: 'Personnel',
              description: 'Dossiers du personnel',
              armoireId: '2',
              dateCreation: DateTime.now().subtract(const Duration(days: 15)),
              dateModification: DateTime.now(),
              dossiers: [
                Dossier(
                  id: '4',
                  nom: 'Fiches de paie',
                  casierId: '3',
                  description: 'Fiches de paie des employés',
                  dateCreation: DateTime.now().subtract(const Duration(days: 12)),
                  dateModification: DateTime.now(),
                  documents: [
                    Document(
                      id: '5',
                      nom: 'Fiche paie Janvier 2024.pdf',
                      type: 'pdf',
                      chemin: '',
                      taille: 1024 * 64, // 64 Ko
                      dateAjout: DateTime.now().subtract(const Duration(days: 8)),
                      dateCreation: DateTime.now().subtract(const Duration(days: 8)),
                      dateModification: DateTime.now(),
                      description: 'Fiche de paie - Janvier 2024',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _creerArmoire() async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle armoire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'armoire',
                hintText: 'Ex: Armoire 1',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description de l\'armoire',
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
      // TODO: Créer l'armoire dans le backend
      setState(() {
        _armoires.add(
          Armoire(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            nom: result['nom']!,
            description: result['description'] ?? '',
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _modifierArmoire(Armoire armoire) async {
    final TextEditingController nomController = TextEditingController(text: armoire.nom);
    final TextEditingController descriptionController = TextEditingController(text: armoire.description);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'armoire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'armoire',
                hintText: 'Ex: Armoire 1',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description de l\'armoire',
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
      // TODO: Mettre à jour l'armoire dans le backend
      setState(() {
        final index = _armoires.indexWhere((a) => a.id == armoire.id);
        if (index != -1) {
          _armoires[index] = Armoire(
            id: armoire.id,
            nom: result['nom']!,
            description: result['description'] ?? '',
            dateCreation: armoire.dateCreation,
            dateModification: DateTime.now(),
            casiers: armoire.casiers,
          );
        }
      });
    }
  }

  Future<void> _supprimerArmoire(Armoire armoire) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'armoire'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette armoire ? Cette action est irréversible.'),
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
      // TODO: Supprimer l'armoire dans le backend
      setState(() {
        _armoires.removeWhere((a) => a.id == armoire.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes armoires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implémenter la recherche d'armoires
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _armoires.isEmpty
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
                        'Aucune armoire',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Créez votre première armoire pour commencer',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _creerArmoire,
                        icon: const Icon(Icons.add),
                        label: const Text('Créer une armoire'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _armoires.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _armoires.length) {
                      return _buildAddArmoireCard();
                    }
                    return _buildArmoireCard(_armoires[index]);
                  },
                ),
      floatingActionButton: _armoires.isNotEmpty
          ? FloatingActionButton(
              onPressed: _creerArmoire,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildAddArmoireCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _creerArmoire,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.add,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Nouvelle armoire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArmoireCard(Armoire armoire) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CasiersScreen(armoire: armoire),
            ),
          );
        },
        onLongPress: () => _modifierArmoire(armoire),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      armoire.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'modifier':
                          _modifierArmoire(armoire);
                          break;
                        case 'supprimer':
                          _supprimerArmoire(armoire);
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
                ],
              ),
              if (armoire.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  armoire.description,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${armoire.casiers.length} casiers',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Créée le ${armoire.dateCreation.day}/${armoire.dateCreation.month}/${armoire.dateCreation.year}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 