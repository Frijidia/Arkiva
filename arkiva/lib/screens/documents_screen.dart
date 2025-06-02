import 'package:flutter/material.dart';
import 'package:arkiva/models/casier.dart';
import 'package:arkiva/models/document.dart';
import 'package:arkiva/services/animation_service.dart';

class DocumentsScreen extends StatefulWidget {
  final Casier casier;

  const DocumentsScreen({
    super.key,
    required this.casier,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Document> _documents = [];
  List<Document> _filteredDocuments = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _chargerDocuments();
  }

  Future<void> _chargerDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Charger les documents depuis le backend
      // Pour l'instant, on utilise des données de test
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _documents = [
          Document(
            id: '1',
            nom: 'Document 1',
            description: 'Description du document 1',
            type: 'pdf',
            chemin: '/chemin/vers/document1.pdf',
            taille: 1024,
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
            tags: ['important', 'contrat'],
          ),
          Document(
            id: '2',
            nom: 'Document 2',
            description: 'Description du document 2',
            type: 'jpg',
            chemin: '/chemin/vers/document2.jpg',
            taille: 2048,
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
            tags: ['photo', 'personnel'],
          ),
        ];
        _filteredDocuments = _documents;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filtrerDocuments(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDocuments = _documents;
      } else {
        _filteredDocuments = _documents.where((doc) {
          return doc.nom.toLowerCase().contains(query.toLowerCase()) ||
              (doc.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              doc.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  Future<void> _ajouterDocument() async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du document',
                hintText: 'Ex: Rapport',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description du document',
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
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null) {
      // TODO: Envoyer le document au backend et gérer le fichier
      setState(() {
        _documents.add(
          Document(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            nom: result['nom']!,
            description: result['description']!,
            type: 'inconnu', // Type par défaut
            chemin: '', // Chemin par défaut
            taille: 0, // Taille par défaut
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
            tags: [], // Tags par défaut
            estChiffre: false, // Chiffrement par défaut
          ),
        );
        _filtrerDocuments(_searchQuery); // Rafraîchir la liste après ajout
      });
    }
  }

  Future<void> _supprimerDocument(Document document) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce document ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _documents.remove(document);
        _filtrerDocuments(_searchQuery);
      });
    }
  }

  IconData _getIconForDocumentType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.casier.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DocumentSearchDelegate(_documents, _filtrerDocuments, _getIconForDocumentType),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredDocuments.isEmpty
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
                        'Aucun document',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajoutez votre premier document',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _ajouterDocument,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un document'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredDocuments.length,
                  itemBuilder: (context, index) {
                    return _buildDocumentCard(_filteredDocuments[index]);
                  },
                ),
      floatingActionButton: _documents.isNotEmpty
          ? FloatingActionButton(
              onPressed: _ajouterDocument,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDocumentCard(Document document) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Ouvrir le document
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconForDocumentType(document.type),
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      document.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('Renommer'),
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Implémenter le renommage
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                _supprimerDocument(document);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (document.description != null && document.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  document.description!,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(document.taille / 1024).toStringAsFixed(2)} KB',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: document.tags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(fontSize: 10),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
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

class DocumentSearchDelegate extends SearchDelegate<Document?> {
  final List<Document> documents;
  final Function(String) onSearch;
  final IconData Function(String) getIconForDocumentType;

  DocumentSearchDelegate(this.documents, this.onSearch, this.getIconForDocumentType);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          // onSearch(''); // Removed redundant call
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = documents.where((doc) {
      return doc.nom.toLowerCase().contains(query.toLowerCase()) ||
          (doc.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          doc.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final document = results[index];
        return ListTile(
          leading: Icon(getIconForDocumentType(document.type)),
          title: Text(document.nom),
          subtitle: document.description != null && document.description!.isNotEmpty
              ? Text(document.description!)
              : null,
          onTap: () {
            close(context, document);
            // TODO: Ouvrir le document sélectionné
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = documents.where((doc) {
      return doc.nom.toLowerCase().contains(query.toLowerCase()) ||
          (doc.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          doc.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final document = results[index];
        return ListTile(
          leading: Icon(getIconForDocumentType(document.type)),
          title: Text(document.nom),
          subtitle: document.description != null && document.description!.isNotEmpty
              ? Text(document.description!)
              : null,
          onTap: () {
            query = document.nom;
            showResults(context);
          },
        );
      },
    );
  }
} 