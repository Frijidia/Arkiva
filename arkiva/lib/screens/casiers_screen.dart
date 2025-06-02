import 'package:flutter/material.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/screens/documents_screen.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Armoire 1 - RH'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              print('Téléverser button pressed');
            },
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: () {
              print('Scanner button pressed');
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
                        onPressed: () {
                          print('Create casier button pressed');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Créer un casier'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _casiers.length,
                  itemBuilder: (context, index) {
                    return _buildSimpleCasierCard(_casiers[index], index + 1);
                  },
                ),
    );
  }

  Widget _buildSimpleCasierCard(Casier casier, int casierNumber) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          print('Tapped on Casier C$casierNumber: ${casier.nom}');
        },
        onLongPress: () => _renommerCasier(casier),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (casierNumber == 1) ...[
                Icon(Icons.folder_open, size: 32, color: Colors.blue[700]),
                const SizedBox(height: 12),
              ],
              Text(
                'C$casierNumber',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 