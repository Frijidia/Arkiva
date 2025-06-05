import 'package:flutter/material.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/models/document.dart';
import 'package:arkiva/services/animation_service.dart';
import 'package:arkiva/screens/document_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class FichiersScreen extends StatefulWidget {
  final Dossier dossier;

  const FichiersScreen({
    super.key,
    required this.dossier,
  });

  @override
  State<FichiersScreen> createState() => _FichiersScreenState();
}

class _FichiersScreenState extends State<FichiersScreen> {
  late List<Document> _documents;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _documents = widget.dossier.documents;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
      print('Fichier sélectionné: ${_selectedFile!.name}');
    } else {
      print('Sélection de fichier annulée');
    }
  }

  void _ajouterDocument() {
    final TextEditingController nomController = TextEditingController();
    _selectedFile = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du document',
                hintText: 'Entrez le nom du document',
              ),
              onChanged: (value) {
                // TODO: Gérer le changement de nom si nécessaire
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_selectedFile != null ? _selectedFile!.name : 'Sélectionner un fichier'),
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
              final nom = nomController.text.trim();
              if (nom.isNotEmpty && _selectedFile != null) {
                print('Ajouter document: $nom avec fichier ${_selectedFile!.name}');
                final nouveauDocument = Document(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nom: nom,
                  type: _selectedFile!.extension ?? '',
                  chemin: '',
                  taille: _selectedFile!.size,
                  dateAjout: DateTime.now(),
                  dateCreation: DateTime.now(),
                  dateModification: DateTime.now(),
                  description: null,
                );
                setState(() {
                  _documents.add(nouveauDocument);
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez saisir un nom et sélectionner un fichier'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _modifierDocument(Document document) {
    final TextEditingController nomController = TextEditingController(text: document.nom);
    final TextEditingController descriptionController = TextEditingController(text: document.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du document',
                hintText: 'Entrez le nouveau nom',
              ),
            ),
             const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (facultatif)',
                hintText: 'Entrez la nouvelle description',
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
              // TODO: Implémenter la modification réelle dans le backend plus tard
              final nom = nomController.text.trim();
              final description = descriptionController.text.trim();

              if (nom.isNotEmpty) {
                setState(() {
                  final index = _documents.indexWhere((doc) => doc.id == document.id);
                  if (index != -1) {
                    _documents[index] = Document(
                      id: document.id,
                      nom: nom,
                      type: document.type,
                      chemin: document.chemin,
                      taille: document.taille,
                      dateAjout: document.dateAjout,
                      dateCreation: document.dateCreation,
                      dateModification: DateTime.now(), // Mettre à jour la date de modification
                      description: description.isNotEmpty ? description : null,
                      tags: document.tags,
                      estChiffre: document.estChiffre,
                    );
                     _searchQuery = ''; // Réinitialiser la recherche après modification
                     _searchController.clear();
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _supprimerDocument(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${document.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _documents.remove(document);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _ouvrirDocument(Document document) {
    print('Ouvrir le document: ${document.nom}');
    if (document.chemin.startsWith('http')) {
      launchUrl(Uri.parse(document.chemin));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'ouverture de fichiers locaux n\'est pas encore implémentée'),
        ),
      );
    }
  }

  List<Document> get _filteredDocuments {
    if (_searchQuery.isEmpty) {
      return _documents;
    }
    return _documents
        .where((doc) =>
            doc.nom.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  IconData _getIconForDocumentType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dossier.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _ajouterDocument,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un document...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _filteredDocuments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Aucun document dans ce dossier'
                              : 'Aucun résultat trouvé',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _ajouterDocument,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un document'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredDocuments.length,
                    itemBuilder: (context, index) {
                      final document = _filteredDocuments[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            _getIconForDocumentType(document.type),
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(document.nom),
                          subtitle: Text(
                            'Ajouté le ${document.dateAjout.toString().split(' ')[0]}',
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'modifier',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Modifier'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'supprimer',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete),
                                    SizedBox(width: 8),
                                    Text('Supprimer'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'modifier':
                                  _modifierDocument(document);
                                  break;
                                case 'supprimer':
                                  _supprimerDocument(document);
                                  break;
                              }
                            },
                          ),
                          onTap: () => _ouvrirDocument(document),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterDocument,
        child: const Icon(Icons.add),
      ),
    );
  }
} 