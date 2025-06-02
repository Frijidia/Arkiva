import 'package:flutter/material.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/screens/documents_screen.dart';

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
            description: result['description'],
            dateCreation: casier.dateCreation,
            documents: casier.documents,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.armoire.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implémenter la recherche dans les casiers
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _casiers.length,
              itemBuilder: (context, index) {
                return _buildCasierCard(_casiers[index]);
              },
            ),
    );
  }

  Widget _buildCasierCard(Casier casier) {
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
              builder: (context) => DocumentsScreen(casier: casier),
            ),
          );
        },
        onLongPress: () => _renommerCasier(casier),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_open, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      casier.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (casier.description != null && casier.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  casier.description!,
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
                    '${casier.documents.length} documents',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Créé le ${casier.dateCreation.day}/${casier.dateCreation.month}/${casier.dateCreation.year}',
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