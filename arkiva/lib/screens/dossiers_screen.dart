import 'package:flutter/material.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/services/dossier_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';

class DossiersScreen extends StatefulWidget {
  final Casier casier;

  const DossiersScreen({super.key, required this.casier});

  @override
  State<DossiersScreen> createState() => _DossiersScreenState();
}

class _DossiersScreenState extends State<DossiersScreen> {
  final DossierService _dossierService = DossierService();
  List<Dossier> _dossiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDossiers();
  }

  Future<void> _loadDossiers() async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token != null) {
        final dossiers = await _dossierService.getDossiers(token, widget.casier.casierId);
    setState(() {
          _dossiers = dossiers;
      _isLoading = false;
    });
  }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _creerDossier() async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau dossier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du dossier',
                hintText: 'Ex: Dossier 1',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description du dossier',
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
          TextButton(
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
      try {
        final token = context.read<AuthStateService>().token;
        if (token != null) {
          await _dossierService.createDossier(
            token,
            widget.casier.casierId,
            result['nom']!,
            result['description'] ?? '',
          );
          await _loadDossiers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dossier créé avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
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
        title: Text(widget.casier.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _creerDossier,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDossiers,
        child: _dossiers.isEmpty
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
                      'Aucun dossier dans ce casier',
                                style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                                ),
                              ),
                                const SizedBox(height: 8),
                    const Text(
                      'Créez votre premier dossier',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                                ElevatedButton.icon(
                      onPressed: _creerDossier,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Créer un dossier'),
                                ),
                            ],
                          ),
                        )
            : ListView.builder(
                          padding: const EdgeInsets.all(16),
                itemCount: _dossiers.length,
                          itemBuilder: (context, index) {
                  final dossier = _dossiers[index];
                  return Card(
                    child: ListTile(
                      title: Text(dossier.nom),
                      subtitle: Text(dossier.description),
                      onTap: () {
                        // TODO: Naviguer vers l'écran des documents
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}