import 'package:flutter/material.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/models/document.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/screens/document_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/upload_service.dart';
import 'package:arkiva/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:arkiva/screens/tags_screen.dart';
import 'package:arkiva/services/tag_service.dart';

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
  final DocumentService _documentService = DocumentService();
  final UploadService _uploadService = UploadService();
  final TagService _tagService = TagService();
  List<Document> _documents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token != null) {
        if (widget.dossier.dossierId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: ID du dossier manquant.')),
          );
          setState(() => _isLoading = false);
          return;
        }
        final documents = await _documentService.getDocuments(token, widget.dossier.dossierId);
        setState(() {
          _documents = documents;
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

  Future<void> _ajouterDocument() async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    _selectedFile = null;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateSB) {
        return AlertDialog(
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
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (facultatif)',
                  hintText: 'Entrez la description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await _pickFile();
                  setStateSB(() {});
                },
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
                  Navigator.pop(context, {
                    'nom': nom,
                    'description': descriptionController.text.trim(),
                  });
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
        );
      }),
    );

    if (result != null && _selectedFile != null) {
      try {
        final authStateService = context.read<AuthStateService>();
        final token = authStateService.token;

        if (token != null && widget.dossier.dossierId != null) {
          final entrepriseId = authStateService.entrepriseId;
          if (entrepriseId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur: ID de l\'entreprise manquant.')),
            );
            return;
          }
          await _uploadService.uploadFile(
            token,
            widget.dossier.dossierId!,
            entrepriseId,
            _selectedFile!,
          );
          await _loadDocuments();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document ajouté avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _modifierDocument(Document document) async {
    if (document.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour la modification.')),
      );
      return;
    }

    final TextEditingController nomController = TextEditingController(text: document.nom);
    final TextEditingController descriptionController = TextEditingController(text: document.description ?? '');

    final result = await showDialog<Map<String, String>>(
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
              final nom = nomController.text.trim();
              if (nom.isNotEmpty) {
                Navigator.pop(context, {
                  'nom': nom,
                  'description': descriptionController.text.trim(),
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
        final authStateService = context.read<AuthStateService>();
        final token = authStateService.token;

        if (token != null) {
          final updatedDocument = await _documentService.updateDocument(
            token,
            document.id,
            result['nom']!,
            result['description'] ?? '',
          );
          
          setState(() {
            final index = _documents.indexWhere((d) => d.id == document.id);
            if (index != -1) {
              _documents[index] = updatedDocument;
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document mis à jour avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _supprimerDocument(Document document) async {
    if (document.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour la suppression.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${document.nom}" ?'),
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
        final authStateService = context.read<AuthStateService>();
        final token = authStateService.token;

        if (token != null) {
          await _documentService.deleteDocument(token, document.id);
          await _loadDocuments();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document supprimé avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _displayDocument(Document document) async {
    if (document.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour l\'affichage.')),
      );
      return;
    }
    try {
      final authStateService = context.read<AuthStateService>();
      final entrepriseId = authStateService.entrepriseId;
      if (entrepriseId == null) {
        throw 'ID de l\'entreprise manquant';
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/fichier/${document.id}/$entrepriseId');
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'affichage du document: ${e.toString()}')),
      );
    }
  }

  Future<void> _telechargerDocument(Document document) async {
    if (document.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour le téléchargement.')),
      );
      return;
    }
    try {
      final authStateService = context.read<AuthStateService>();
      final entrepriseId = authStateService.entrepriseId;
      if (entrepriseId == null) {
        throw 'ID de l\'entreprise manquant';
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/fichier/${document.id}/$entrepriseId');
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement du document: ${e.toString()}')),
      );
    }
  }

  void _ouvrirOuTelechargerDocument(Document document) {
    final authStateService = context.read<AuthStateService>();
    final token = authStateService.token;
    final entrepriseId = authStateService.entrepriseId;
    if (token == null || entrepriseId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Token ou ID entreprise manquant'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final url = '${ApiConfig.baseUrl}/fichier/${document.id}/$entrepriseId';
    http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    ).then((response) {
      if (response.statusCode == 200) {
        final fileName = document.nomOriginal ?? document.nom;
        final mimeType = _getMimeType(fileName);
        print('DEBUG: nom=$fileName, mimeType=$mimeType');
        final blob = html.Blob([response.bodyBytes], mimeType);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        if (mimeType.startsWith('application/pdf')) {
          html.window.open(blobUrl, '_blank');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ce type de fichier n\'est pas prévisualisable. Il va être téléchargé.')),
            );
          }
          final anchor = html.AnchorElement(href: blobUrl)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(blobUrl);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ouverture du document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt': return 'text/plain';
      case 'zip': return 'application/zip';
      case 'rar': return 'application/x-rar-compressed';
      default: return 'application/octet-stream';
    }
  }

  List<Document> get _filteredDocuments {
    if (_searchQuery.isEmpty) {
      return _documents;
    }
    return _documents.where((doc) {
      return doc.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (doc.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  Future<void> _assignTagToFile(Document document) async {
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    if (token == null || entrepriseId == null) return;
    List<dynamic> tags = [];
    String? selectedTag;
    String search = '';
    bool isLoading = true;
    String? error;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          Future<void> loadTags() async {
            setStateSB(() { isLoading = true; error = null; });
            try {
              tags = await _tagService.getAllTags(token, entrepriseId);
            } catch (e) {
              error = 'Erreur lors du chargement des tags';
            }
            setStateSB(() { isLoading = false; });
          }
          if (isLoading) loadTags();
          final filteredTags = tags.where((tag) => tag['name'].toLowerCase().contains(search.toLowerCase())).toList();
          return AlertDialog(
            title: const Text('Assigner un tag'),
            content: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Text(error!, style: const TextStyle(color: Colors.red))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Rechercher un tag',
                            ),
                            onChanged: (value) => setStateSB(() => search = value),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            width: 300,
                            child: ListView(
                              children: filteredTags.map<Widget>((tag) => ListTile(
                                title: Text(tag['name']),
                                onTap: () => setStateSB(() => selectedTag = tag['name']),
                                selected: selectedTag == tag['name'],
                                trailing: selectedTag == tag['name'] ? const Icon(Icons.check, color: Colors.blue) : null,
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: selectedTag == null ? null : () => Navigator.pop(context, selectedTag),
                child: const Text('Assigner'),
              ),
            ],
          );
        },
      ),
    ).then((tagName) async {
      if (tagName != null && tagName is String && tagName.isNotEmpty) {
        await _tagService.addTagToFile(token, entrepriseId, int.parse(document.id.toString()), tagName);
        await _loadDocuments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "$tagName" assigné au document.')),
        );
      }
    });
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return Colors.grey;
    try {
      if (colorString.startsWith('#') && (colorString.length == 7)) {
        return Color(int.parse(colorString.replaceFirst('#', '0xff')));
      }
    } catch (_) {}
    return Colors.grey;
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
        title: Text(widget.dossier.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _ajouterDocument,
          ),
          IconButton(
            icon: const Icon(Icons.label),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TagsScreen())),
            tooltip: 'Tags',
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
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDocuments,
              child: _filteredDocuments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.description,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun document dans ce dossier',
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
                        final document = _filteredDocuments[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.description),
                            title: Text(document.nomOriginal ?? document.nom),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (document.description != null && document.description!.isNotEmpty)
                                  Text(document.description!),
                                if (document.tags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Wrap(
                                      spacing: 6,
                                      children: document.tags.map((tag) => Chip(
                                        label: Text(tag['name'] ?? ''),
                                        backgroundColor: _parseColor(tag['color']),
                                        onDeleted: () async {
                                          final authState = context.read<AuthStateService>();
                                          final token = authState.token;
                                          final entrepriseId = authState.entrepriseId;
                                          if (token != null && entrepriseId != null && tag['name'] != null) {
                                            final allTags = await _tagService.getAllTags(token, entrepriseId);
                                            final tagObj = allTags.firstWhere((t) => t['name'] == tag['name'], orElse: () => null);
                                            if (tagObj != null) {
                                              await _tagService.removeTagFromFile(token, entrepriseId, int.parse(document.id), tagObj['tag_id']);
                                              await _loadDocuments();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Tag "${tag['name']}" retiré du document.')),
                                              );
                                            }
                                          }
                                        },
                                      )).toList(),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'afficher':
                                    _ouvrirOuTelechargerDocument(document);
                                    break;
                                  case 'telecharger':
                                    _telechargerDocument(document);
                                    break;
                                  case 'modifier':
                                    _modifierDocument(document);
                                    break;
                                  case 'supprimer':
                                    _supprimerDocument(document);
                                    break;
                                  case 'assigner_tag':
                                    _assignTagToFile(document);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'afficher',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 8),
                                      Text('Afficher'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'telecharger',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download),
                                      SizedBox(width: 8),
                                      Text('Télécharger'),
                                    ],
                                  ),
                                ),
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
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'assigner_tag',
                                  child: Row(
                                    children: [
                                      Icon(Icons.label, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Assigner un tag'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _ouvrirOuTelechargerDocument(document);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterDocument,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un document',
      ),
    );
  }
} 

//sur mobile on va ajouter un systeme pour scanner les fichiers 