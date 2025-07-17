import 'package:flutter/material.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/models/document.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/screens/document_viewer_screen.dart';
import 'package:arkiva/widgets/deplacement_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/upload_service.dart';
import 'package:arkiva/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:arkiva/screens/tags_screen.dart';
import 'package:arkiva/services/tag_service.dart';
import 'package:arkiva/services/search_service.dart';
import 'package:arkiva/services/favoris_service.dart';
import 'package:arkiva/widgets/favori_button.dart';
import 'package:arkiva/screens/merge_files_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:arkiva/screens/scan_document_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:arkiva/services/backup_service.dart';
import 'package:arkiva/services/version_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';

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
  final SearchService _searchService = SearchService();
  final FavorisService _favorisService = FavorisService();
  List<Document> _documents = [];
  List<Document> _allDocuments = [];
  List<dynamic> _allTags = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PlatformFile? _selectedFile;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  // Filtres avancés pour la recherche
  String? _selectedArmoire;
  String? _selectedCasier;
  String? _selectedDossier;
  dynamic _selectedTag;
  DateTimeRange? _selectedDateRange;
  List<dynamic> _allArmoires = [];
  List<dynamic> _allCasiers = [];
  List<dynamic> _allDossiers = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final tags = await _tagService.getAllTags(token, entrepriseId);
        setState(() {
          _allTags = tags;
        });
      }
    } catch (e) {
      // ignore erreur silencieusement
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      if (token != null) {
        if (widget.dossier.dossierId == null) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Erreur: ID du dossier manquant.')),
          );
          setState(() => _isLoading = false);
          return;
        }
        final documents = await _documentService.getDocuments(token, widget.dossier.dossierId);
        setState(() {
          _allDocuments = documents;
          _documents = documents;
          _isLoading = false;
        });
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
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
    final TextEditingController descriptionController = TextEditingController();
    _selectedFile = null;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateSB) {
        return AlertDialog(
          title: const Text('Ajouter un document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Suppression du champ Nom du document
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
                if (_selectedFile != null) {
                  Navigator.pop(context, {
                    'nom': _selectedFile!.name, // Utilise le vrai nom du fichier
                    'description': descriptionController.text.trim(),
                  });
                } else {
                  Navigator.pop(context, {'erreur': 'Veuillez sélectionner un fichier'});
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      }),
    );

    if (result != null && result['erreur'] != null) {
      if (!mounted) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(result['erreur']!)),
      );
      return;
    }

    if (result != null && _selectedFile != null) {
      try {
        final authStateService = context.read<AuthStateService>();
        final token = authStateService.token;

        if (token != null && widget.dossier.dossierId != null) {
          final entrepriseId = authStateService.entrepriseId;
          if (entrepriseId == null) {
            if (!mounted) return;
            _scaffoldMessengerKey.currentState?.showSnackBar(
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
          if (!mounted) return;
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Document ajouté avec succès')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Erreur: \\${e.toString()}')),
        );
      }
    }
  }

  Future<void> _modifierDocument(Document document) async {
    if (document.id == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
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
          
          if (!mounted) return;
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Document mis à jour avec succès')),
          );
        }
      } catch (e) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _supprimerDocument(Document document) async {
    if (document.id == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
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
          if (!mounted) return;
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Document supprimé avec succès')),
          );
        }
      } catch (e) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deplacerFichier(Document document) async {
    if (document.id == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour le déplacement.')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const DeplacementDialog(typeElement: 'fichier'),
    );

    if (result != null) {
      try {
        final token = context.read<AuthStateService>().token;
        if (token != null) {
          await _documentService.deplacerFichier(token, document.id!, result['dossier_id']);
          await _loadDocuments();
          if (!mounted) return;
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Fichier déplacé avec succès')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Erreur lors du déplacement: $e')),
        );
      }
    }
  }

  Future<void> _sauvegarderFichier(Document document) async {
    if (document.id == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour la sauvegarde.')),
      );
      return;
    }

    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token == null || entrepriseId == null) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Erreur: Informations d\'authentification manquantes')),
        );
        return;
      }

      await BackupService.createBackup(
        token: token,
        type: 'fichier',
        cibleId: int.parse(document.id),
        entrepriseId: entrepriseId,
      );

      if (!mounted) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Sauvegarde créée avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  Future<void> _creerVersionFichier(Document document) async {
    if (document.id == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour la création de version.')),
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description (facultatif)',
                hintText: 'Ex: Correction de la section 2.1',
                prefixIcon: Icon(Icons.description),
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
                'description': 'Version créée depuis l\'écran fichiers',
              });
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final authStateService = context.read<AuthStateService>();
        final token = authStateService.token;

        if (token == null) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Token d\'authentification manquant')),
          );
          return;
        }

        await VersionService.createVersion(
          token: token,
          cibleId: int.parse(document.id),
          type: 'fichier',
          description: result['description'],
        );

        if (!mounted) return;
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Version créée avec succès')),
        );
      } catch (e) {
        if (!mounted) return;
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Erreur lors de la création de version: $e')),
        );
      }
    }
  }

  Future<void> _displayDocument(Document document) async {
    if (document.id == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
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
      final url = Uri.parse('${ApiConfig.baseUrl}/api/fichier/${document.id}/$entrepriseId');
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'affichage du document: ${e.toString()}')),
      );
    }
  }

  Future<void> _telechargerDocument(Document document) async {
    if (document.id == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
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
      final token = authStateService.token;
      if (token == null) {
        throw 'Token manquant';
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/api/fichier/${document.id}/$entrepriseId?token=$token');
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement du document: ${e.toString()}')),
      );
    }
  }

  Future<void> _ouvrirOuTelechargerDocument(Document document) async {
    final authStateService = context.read<AuthStateService>();
    final token = authStateService.token;
    final entrepriseId = authStateService.entrepriseId;
    if (token == null || entrepriseId == null) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Erreur: Token ou ID entreprise manquant'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    if (kIsWeb) {
      // Pour le web, on utilise url_launcher
      final url = '${ApiConfig.baseUrl}/api/fichier/${document.id}/$entrepriseId?token=$token';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Pour mobile, on télécharge et ouvre avec open_filex
      try {
        final url = '${ApiConfig.baseUrl}/api/fichier/${document.id}/$entrepriseId?token=$token';
        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (response.statusCode == 200) {
          final fileName = document.nomOriginal ?? document.nom;
          
          // Sauvegarder temporairement et ouvrir
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          
          // Ouvrir avec open_filex
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done) {
            if (mounted) {
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text('Erreur lors de l\'ouverture: ${result.message}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            _scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text('Erreur lors du téléchargement: ${response.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
      final query = _searchQuery.toLowerCase();
      return doc.nom.toLowerCase().contains(query) ||
          (doc.description?.toLowerCase().contains(query) ?? false) ||
          (doc.contenuOcr?.toLowerCase().contains(query) ?? false) ||
          doc.tags.any((tag) => (tag['name'] ?? '').toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _assignTagToFile(Document document) async {
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    if (token == null || entrepriseId == null) return;
    List<dynamic> tags = [];
    List<dynamic> suggestedTags = [];
    List<dynamic> popularTags = [];
    String? selectedTag;
    String search = '';
    bool isLoading = true;
    String? error;
    final tagName = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          Future<void> loadTags() async {
            setStateSB(() { isLoading = true; error = null; });
            try {
              tags = await _tagService.getAllTags(token, entrepriseId);
              // Tags suggérés (OCR) - gérer l'erreur silencieusement
              try {
                suggestedTags = await _tagService.getSuggestedTags(token, entrepriseId, document.id);
              } catch (e) {
                print('Erreur suggestions de tags (ignorée): $e');
                suggestedTags = [];
              }
              // Tags populaires
              try {
                popularTags = await _tagService.getPopularTags(token, entrepriseId);
              } catch (e) {
                print('Erreur tags populaires (ignorée): $e');
                popularTags = [];
              }
            } catch (e) {
              error = 'Erreur lors du chargement des tags';
            }
            setStateSB(() { isLoading = false; });
          }
          if (isLoading) loadTags();
          final filteredTags = tags.where((tag) => tag['name'].toLowerCase().contains(search.toLowerCase())).toList();
          return AlertDialog(
            title: const Text('Assigner un tag'),
            content: SizedBox(
              width: 400,
              child: isLoading
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
                            if (suggestedTags.isNotEmpty) ...[
                              const Text(
                                'Tags suggérés',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: suggestedTags.map<Widget>((tag) => ActionChip(
                                    avatar: const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                                    label: Text(tag['name']),
                                    backgroundColor: Colors.white,
                                    onPressed: () => Navigator.pop(context, tag['name']),
                                    tooltip: 'Cliquez pour assigner ce tag suggéré',
                                  )).toList(),
                                ),
                              ),
                              const Divider(height: 24),
                            ],
                            if (popularTags.isNotEmpty) ...[
                              const Text(
                                'Tags populaires',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: popularTags.map<Widget>((tag) => ActionChip(
                                    avatar: const Icon(Icons.trending_up, size: 16, color: Colors.green),
                                    label: Text(tag),
                                    backgroundColor: Colors.white,
                                    onPressed: () => Navigator.pop(context, tag),
                                    tooltip: 'Cliquez pour assigner ce tag populaire',
                                  )).toList(),
                                ),
                              ),
                              const Divider(height: 24),
                            ],
                            const Text(
                              'Tous les tags',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 180,
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
    );
    if (tagName != null && tagName.isNotEmpty) {
      await _tagService.addTagToFile(token, entrepriseId, document.id, tagName);
      await _loadDocuments();
      if (!mounted) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Tag "$tagName" assigné au document.')),
      );
    }
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

  void _searchLocal(String query) {
    setState(() {
      _searchQuery = query;
      _documents = _allDocuments.where((doc) {
        final lower = query.toLowerCase();
        final inNom = doc.nom.toLowerCase().contains(lower);
        final inDesc = (doc.description ?? '').toLowerCase().contains(lower);
        final inOcr = (doc.contenuOcr ?? '').toLowerCase().contains(lower);
        final inTags = doc.tags.any((tag) => (tag['name'] ?? '').toLowerCase().contains(lower));
        return inNom || inDesc || inOcr || inTags;
      }).toList();
    });
  }

  Future<void> _loadArmoires() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/armoire/$entrepriseId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          print('Armoires chargées: $data'); // Debug log
          setState(() {
            _allArmoires = data;
          });
        } else {
          print('Erreur chargement armoires: ${response.statusCode} - ${response.body}'); // Debug log
        }
      }
    } catch (e) {
      print('Exception chargement armoires: $e'); // Debug log
    }
  }

  Future<void> _loadCasiers(String armoireId) async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/casier/$armoireId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          print('Casiers chargés: $data'); // Debug log
          setState(() {
            _allCasiers = data;
          });
        } else {
          print('Erreur chargement casiers: ${response.statusCode} - ${response.body}'); // Debug log
        }
      }
    } catch (e) {
      print('Exception chargement casiers: $e'); // Debug log
    }
  }

  Future<void> _loadDossiers(String casierId) async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/dosier/$casierId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          print('Dossiers chargés: $data'); // Debug log
          setState(() {
            _allDossiers = data;
          });
        } else {
          print('Erreur chargement dossiers: ${response.statusCode} - ${response.body}'); // Debug log
        }
      }
    } catch (e) {
      print('Exception chargement dossiers: $e'); // Debug log
    }
  }

  void _openFiltersRechercheService() async {
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    
    // Charger les données si nécessaire
    if (_allTags.isEmpty && token != null && entrepriseId != null) {
      final tags = await _tagService.getAllTags(token, entrepriseId);
      setState(() { _allTags = tags; });
    }
    if (_allArmoires.isEmpty) {
      await _loadArmoires();
    }
    if (_selectedArmoire != null && _allCasiers.isEmpty) {
      await _loadCasiers(_selectedArmoire!);
    }
    if (_selectedCasier != null && _allDossiers.isEmpty) {
      await _loadDossiers(_selectedCasier!);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Filtres avancés', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 20),
                DropdownButtonFormField<dynamic>(
                  value: _selectedArmoire,
                  items: _allArmoires.map<DropdownMenuItem<dynamic>>((armoire) => DropdownMenuItem(
                    value: armoire['armoire_id'].toString(),
                    child: Text(armoire['nom']),
                  )).toList(),
                  onChanged: (value) async {
                    setStateSB(() {
                      _selectedArmoire = value;
                      _selectedCasier = null;
                      _selectedDossier = null;
                      _allCasiers = [];
                      _allDossiers = [];
                    });
                    if (value != null) {
                      await _loadCasiers(value);
                      setStateSB(() {});
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Armoire',
                    prefixIcon: Icon(Icons.warehouse),
                  ),
                  isExpanded: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<dynamic>(
                  value: _selectedCasier,
                  items: _allCasiers.map<DropdownMenuItem<dynamic>>((casier) => DropdownMenuItem(
                    value: casier['cassier_id'].toString(),
                    child: Text('${casier['nom']}${casier['sous_titre'] != null && casier['sous_titre'].isNotEmpty ? ' - ${casier['sous_titre']}' : ''}'),
                  )).toList(),
                  onChanged: (value) async {
                    setStateSB(() {
                      _selectedCasier = value;
                      _selectedDossier = null;
                      _allDossiers = [];
                    });
                    if (value != null) {
                      await _loadDossiers(value);
                      setStateSB(() {});
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Casier',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  isExpanded: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<dynamic>(
                  value: _selectedDossier,
                  items: _allDossiers.map<DropdownMenuItem<dynamic>>((dossier) => DropdownMenuItem(
                    value: dossier['dossier_id'].toString(),
                    child: Text(dossier['nom']),
                  )).toList(),
                  onChanged: (value) => setStateSB(() => _selectedDossier = value),
                  decoration: const InputDecoration(
                    labelText: 'Dossier',
                    prefixIcon: Icon(Icons.folder),
                  ),
                  isExpanded: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<dynamic>(
                  value: _selectedTag,
                  items: _allTags.map<DropdownMenuItem<dynamic>>((tag) => DropdownMenuItem(
                    value: tag,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _parseColor(tag['color']),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(tag['name']),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedTag = value),
                  decoration: const InputDecoration(
                    labelText: 'Tag',
                    prefixIcon: Icon(Icons.label),
                  ),
                  isExpanded: true,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.date_range),
                            SizedBox(width: 8),
                            Text('Période de création', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedDateRange == null 
                            ? 'Non sélectionnée' 
                            : 'Du ${_selectedDateRange!.start.toString().substring(0,10)} au ${_selectedDateRange!.end.toString().substring(0,10)}',
                          style: TextStyle(
                            color: _selectedDateRange == null ? Colors.grey : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              helpText: 'Sélectionner une période',
                              cancelText: 'Annuler',
                              confirmText: 'OK',
                              saveText: 'Enregistrer',
                              errorFormatText: 'Format invalide',
                              errorInvalidText: 'Date invalide',
                              errorInvalidRangeText: 'Plage de dates invalide',
                              fieldStartHintText: 'Début',
                              fieldEndHintText: 'Fin',
                              fieldStartLabelText: 'Date de début',
                              fieldEndLabelText: 'Date de fin',
                            );
                            if (picked != null) setState(() => _selectedDateRange = picked);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_selectedDateRange == null ? 'Sélectionner une période' : 'Modifier la période'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedArmoire = null;
                          _selectedCasier = null;
                          _selectedDossier = null;
                          _selectedTag = null;
                          _selectedDateRange = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réinitialiser'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _performSearchRechercheService();
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Rechercher'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performSearchRechercheService() async {
    // Ne faire la recherche serveur que s'il y a du texte
    if (_searchController.text.isEmpty) {
      return;
    }
    
    setState(() => _isLoading = true);
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    if (token == null || entrepriseId == null) return;
    try {
      List<dynamic> results = [];
      if (_selectedTag != null) {
        print('DEBUG: Recherche par tag sélectionné: $_selectedTag');
        print('DEBUG: tag_id = ${_selectedTag['tag_id']}');
        results = await _searchService.getFilesByTag(token, _selectedTag['tag_id'], entrepriseId);
        print('DEBUG: Résultats de la recherche par tag reçus: ${results.length} éléments');
      } else if (_selectedDateRange != null) {
        final debut = _selectedDateRange!.start.toIso8601String().substring(0, 10);
        final fin = _selectedDateRange!.end.toIso8601String().substring(0, 10);
        results = await _searchService.searchByDate(token, debut, fin, entrepriseId);
      } else if (_selectedArmoire != null || _selectedCasier != null || _selectedDossier != null) {
        results = await _searchService.searchFlexible(
          token,
          entrepriseId,
          armoire: _selectedArmoire,
          casier: _selectedCasier,
          dossier: _selectedDossier,
          nom: _searchController.text.isNotEmpty ? _searchController.text : null,
        );
      } else if (_searchController.text.isNotEmpty) {
        // Recherche OCR uniquement si aucun filtre avancé n'est actif
        print('DEBUG: Déclenchement de la recherche OCR pour: "${_searchController.text}"');
        results = await _searchService.searchByOcr(token, _searchController.text, entrepriseId);
      }
      
      print('DEBUG: Avant setState - results.length = ${results.length}');
      print('DEBUG: Premier résultat (si existe): ${results.isNotEmpty ? results.first : "Aucun"}');
      
      // Mettre à jour _searchQuery pour que _filteredDocuments fonctionne correctement
      setState(() {
        _searchQuery = _searchController.text;
        _documents = results.map((json) => Document.fromJson(json)).toList();
        _isLoading = false;
      });
      
      // Debug: afficher le nombre de résultats
      print('DEBUG: Recherche terminée avec ${results.length} résultats');
      print('DEBUG: _searchQuery = "$_searchQuery"');
      print('DEBUG: _documents.length = ${_documents.length}');
      print('DEBUG: _filteredDocuments.length = ${_filteredDocuments.length}');
      
    } catch (e) {
      print('DEBUG: Erreur lors de la recherche: $e');
      setState(() => _isLoading = false);
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche: $e')),
      );
    }
  }

  // Méthodes pour gérer les favoris
  Future<void> _toggleFavori(Document document) async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final userId = authState.userId;
      final entrepriseId = authState.entrepriseId;

      if (token == null || userId == null || entrepriseId == null) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Erreur: Informations d\'authentification manquantes')),
        );
        return;
      }

      final isFavori = await _favorisService.isFavori(token, int.parse(userId), int.parse(document.id));
      
      if (isFavori) {
        // Retirer des favoris
        await _favorisService.removeFavori(token, int.parse(userId), int.parse(document.id));
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Document retiré des favoris')),
        );
      } else {
        // Ajouter aux favoris
        await _favorisService.addFavori(token, int.parse(userId), int.parse(document.id), entrepriseId!);
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Document ajouté aux favoris')),
        );
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Erreur lors de la gestion des favoris: $e')),
      );
    }
  }

  Future<bool> _isDocumentFavori(Document document) async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final userId = authState.userId;

      if (token == null || userId == null) return false;

      return await _favorisService.isFavori(token, int.parse(userId), int.parse(document.id));
    } catch (e) {
      return false;
    }
  }

  Future<void> _ouvrirDansNouvelOnglet(Document document) async {
    if (document.id == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour l\'ouverture.')),
      );
      return;
    }
    
    final authStateService = context.read<AuthStateService>();
    final token = authStateService.token;
    final entrepriseId = authStateService.entrepriseId;
    
    if (token == null || entrepriseId == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Erreur: Token ou ID entreprise manquant')),
      );
      return;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/fichier/${document.id}/$entrepriseId?token=$token');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Document ouvert dans un nouvel onglet')),
        );
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le document dans un nouvel onglet')),
        );
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.dossier.nom),
          actions: [
            IconButton(
              icon: const Icon(Icons.merge),
              onPressed: () async {
                final fusionEffectuee = await Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => MergeFilesScreen(dossier: widget.dossier),
                ),
                );
                if (fusionEffectuee == true) {
                  await _loadDocuments();
                }
              },
              tooltip: 'Fusionner des fichiers',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _ajouterDocument,
            ),
            IconButton(
              icon: const Icon(Icons.label),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TagsScreen())),
              tooltip: 'Tags',
            ),
            if (!kIsWeb)
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () async {
                  final scanEffectue = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScanDocumentScreen(dossier: widget.dossier),
                    ),
                  );
                  if (scanEffectue == true) {
                    await _loadDocuments();
                  }
                },
                tooltip: 'Scanner un document',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Recherche OCR, nom, ...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchLocal('');
                                });
                              },
                            )
                          : null,
                      ),
                      onChanged: (value) {
                        // Si on tape dans la barre, faire une recherche locale
                        if (value.isEmpty) {
                          // Si la barre est vide, recharger tous les documents
                          setState(() {
                            _searchQuery = '';
                            _documents = _allDocuments;
                          });
                        } else {
                          // Sinon, faire une recherche locale
                          _searchLocal(value);
                        }
                      },
                      onSubmitted: (value) => _performSearchRechercheService(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_alt),
                    onPressed: _openFiltersRechercheService,
                    tooltip: 'Filtres avancés',
                  ),
                ],
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
                          // Debug: afficher les informations du document
                          print('DEBUG: Affichage document ${index + 1}/${_filteredDocuments.length}: ${document.nom}');
                          
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.description),
                              title: Text(document.nomOriginal ?? document.nom),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (document.description != null && document.description!.isNotEmpty)
                                    Text(document.description!),
                                  // Suppression de l'affichage OCR
                                  // if (document.contenuOcr != null && document.contenuOcr!.isNotEmpty)
                                  //   Container(
                                  //     margin: const EdgeInsets.only(top: 4.0),
                                  //     padding: const EdgeInsets.all(8.0),
                                  //     decoration: BoxDecoration(
                                  //       color: Colors.blue.withOpacity(0.1),
                                  //       borderRadius: BorderRadius.circular(4.0),
                                  //     ),
                                  //     child: Text(
                                  //       'OCR: ${document.contenuOcr!.length > 100 ? '${document.contenuOcr!.substring(0, 100)}...' : document.contenuOcr!}',
                                  //       style: const TextStyle(
                                  //         fontSize: 12,
                                  //         fontStyle: FontStyle.italic,
                                  //         color: Colors.blue,
                                  //       ),
                                  //     ),
                                  //   ),
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
                                                final bool? removed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Retirer le tag'),
                                                    content: Text('Voulez-vous vraiment retirer le tag "${tag['name']}" de ce document ?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retirer')),
                                                    ],
                                                  ),
                                                );
                                                if (removed == true) {
                                                  await _tagService.removeTagFromFile(token, entrepriseId, document.id, tagObj['tag_id']);
                                                  await _loadDocuments();
                                                  if (!mounted) return;
                                                  _scaffoldMessengerKey.currentState?.showSnackBar(
                                                    SnackBar(content: Text('Tag "${tag['name']}" retiré du document.')),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                        )).toList(),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FavoriButton(
                                    document: document,
                                    size: 20,
                                    onToggle: () {
                                      // Optionnel : rafraîchir la liste si nécessaire
                                    },
                                  ),
                                  PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'telecharger':
                                      _telechargerDocument(document);
                                      break;
                                    case 'modifier':
                                      _modifierDocument(document);
                                      break;
                                    case 'deplacer':
                                      _deplacerFichier(document);
                                      break;
                                    case 'supprimer':
                                      _supprimerDocument(document);
                                      break;
                                    case 'assigner_tag':
                                      _assignTagToFile(document);
                                      break;
                                        case 'favoris':
                                          _toggleFavori(document);
                                          break;
                                        case 'ouvrir_nouvel_onglet':
                                          _ouvrirDansNouvelOnglet(document);
                                          break;
                                        case 'sauvegarder':
                                          _sauvegarderFichier(document);
                                          break;
                                        case 'creer_version':
                                          _creerVersionFichier(document);
                                          break;
                                  }
                                },
                                itemBuilder: (context) => [
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
                                            Text('Renommer'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                        value: 'deplacer',
                                    child: Row(
                                      children: [
                                            Icon(Icons.move_to_inbox),
                                        SizedBox(width: 8),
                                            Text('Déplacer'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                        value: 'ouvrir_nouvel_onglet',
                                    child: Row(
                                      children: [
                                            Icon(Icons.open_in_new),
                                        SizedBox(width: 8),
                                            Text('Ouvrir dans un nouvel onglet'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                        value: 'favoris',
                                    child: Row(
                                      children: [
                                            Icon(Icons.favorite_border),
                                        SizedBox(width: 8),
                                            Text('Ajouter/Retirer des favoris'),
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
                                        value: 'sauvegarder',
                                        child: Row(
                                          children: [
                                            Icon(Icons.backup, color: Colors.orange),
                                            SizedBox(width: 8),
                                            Text('Sauvegarder'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'creer_version',
                                        child: Row(
                                          children: [
                                            Icon(Icons.history, color: Colors.purple),
                                            SizedBox(width: 8),
                                            Text('Créer une version'),
                                          ],
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }
} 

//sur mobile on va ajouter un systeme pour scanner les fichiers 