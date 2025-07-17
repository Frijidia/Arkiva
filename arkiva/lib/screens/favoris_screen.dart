import 'package:flutter/material.dart';
import 'package:arkiva/models/document.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/favoris_service.dart';
import 'package:arkiva/services/search_service.dart';
import 'package:arkiva/services/tag_service.dart';
import 'package:arkiva/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/widgets/favori_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final FavorisService _favorisService = FavorisService();
  final DocumentService _documentService = DocumentService();
  final TagService _tagService = TagService();
  List<Document> _favoris = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedType;
  DateTimeRange? _selectedDateRange;
  bool _showFilters = false;

  final List<String> _documentTypes = [
    'Tous',
    'PDF',
    'Image',
    'Document',
    'Tableur',
    'Présentation',
    'Archive',
  ];

  @override
  void initState() {
    super.initState();
    _loadFavoris();
  }

  Future<void> _loadFavoris() async {
    setState(() => _isLoading = true);
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final userId = authState.userId;
      final entrepriseId = authState.entrepriseId;

      if (token != null && userId != null && entrepriseId != null) {
        final documents = await _favorisService.getFavoris(token, int.parse(userId));
        setState(() {
          _favoris = documents;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des favoris: $e')),
        );
      }
    }
  }

  List<Document> get _filteredFavoris {
    return _favoris.where((doc) {
      // Filtre par recherche
      final matchesSearch = _searchQuery.isEmpty ||
          doc.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (doc.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      // Filtre par type
      final matchesType = _selectedType == null || _selectedType == 'Tous' ||
          (_selectedType == 'PDF' && doc.type.contains('pdf')) ||
          (_selectedType == 'Image' && doc.type.contains('image')) ||
          (_selectedType == 'Document' && doc.type.contains('document')) ||
          (_selectedType == 'Tableur' && doc.type.contains('spreadsheet')) ||
          (_selectedType == 'Présentation' && doc.type.contains('presentation')) ||
          (_selectedType == 'Archive' && doc.type.contains('archive'));

      // Filtre par date
      final matchesDate = _selectedDateRange == null ||
          (doc.dateCreation != null &&
              doc.dateCreation!.isAfter(_selectedDateRange!.start) &&
              doc.dateCreation!.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));

      return matchesSearch && matchesType && matchesDate;
    }).toList();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type de document',
                  prefixIcon: Icon(Icons.description),
                ),
                items: _documentTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value);
                  setStateSB(() {});
                },
              ),
              const SizedBox(height: 16),
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
                          Text('Période d\'ajout', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            lastDate: DateTime.now(),
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
                          if (picked != null) {
                            setState(() => _selectedDateRange = picked);
                            setStateSB(() {});
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_selectedDateRange == null ? 'Sélectionner une période' : 'Modifier la période'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _selectedDateRange = null;
                      });
                      setStateSB(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réinitialiser'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Appliquer'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDocument(Document document) async {
    if (document.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour l\'ouverture.')),
      );
      return;
    }
    
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    
    if (token == null || entrepriseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Token ou ID entreprise manquant')),
      );
      return;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/fichier/${document.id}/$entrepriseId?token=$token');
      if (kIsWeb) {
        // For web, you might want to open a new tab or window
        // For now, we'll just show a snackbar
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ouverture du document non supportée sur le web.')),
        );
      } else {
        // For mobile, use open_filex
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/${document.nomOriginal ?? document.nom}');
          await file.writeAsBytes(response.bodyBytes);
          await OpenFilex.open(file.path);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'ouverture du document: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
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
      final token = authStateService.token;
      if (entrepriseId == null || token == null) {
        throw 'ID de l\'entreprise ou token manquant';
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/api/fichier/${document.id}/$entrepriseId?token=$token');
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement du document: \\${e.toString()}')),
      );
    }
  }

  Future<void> _modifierDocument(Document document) async {
    if (document.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: ID du document manquant pour la modification.')),
      );
      return;
    }
    final TextEditingController nomController = TextEditingController(text: document.nomOriginal ?? document.nom);
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
            final index = _favoris.indexWhere((d) => d.id == document.id);
            if (index != -1) {
              _favoris[index] = updatedDocument;
            }
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document mis à jour avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: \\${e.toString()}')),
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
        content: Text('Êtes-vous sûr de vouloir supprimer "${document.nomOriginal ?? document.nom.replaceAll('.enc', '')}" ?'),
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
          setState(() {
            _favoris.removeWhere((d) => d.id == document.id);
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document supprimé avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: \\${e.toString()}')),
        );
      }
    }
  }

  Future<void> _assignTagToFile(Document document) async {
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    if (token == null || entrepriseId == null) return;
    List<dynamic> tags = [];
    List<dynamic> suggestedTags = [];
    List<String> popularTags = [];
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
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: suggestedTags.map<Widget>((tag) => ActionChip(
                                    avatar: const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                                    label: Text(tag['name']),
                                    backgroundColor: Colors.white,
                                    onPressed: () => Navigator.pop(context, tag['name']),
                                    tooltip: 'Cliquez pour assigner ce tag suggéré',
                                  )).toList(),
                                ),
                                const Divider(height: 24),
                              ],
                              if (popularTags.isNotEmpty) ...[
                                const Text(
                                  'Tags populaires',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: popularTags.map<Widget>((tag) => ActionChip(
                                    avatar: const Icon(Icons.trending_up, size: 16, color: Colors.green),
                                    label: Text(tag),
                                    backgroundColor: Colors.white,
                                    onPressed: () => Navigator.pop(context, tag),
                                    tooltip: 'Cliquez pour assigner ce tag populaire',
                                  )).toList(),
                                ),
                                const Divider(height: 24),
                              ],
                              const Text(
                                'Tous les tags',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      await _loadFavoris();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tag "$tagName" assigné au document.')),
      );
    }
  }

  Future<void> _toggleFavori(Document document) async {
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final userId = authState.userId;
    final entrepriseId = authState.entrepriseId;
    if (token == null || userId == null || entrepriseId == null) return;
    final isFavori = await _favorisService.isFavori(token, int.parse(userId), int.parse(document.id));
    if (isFavori) {
      await _favorisService.removeFavori(token, int.parse(userId), int.parse(document.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retiré des favoris.')),
      );
    } else {
      await _favorisService.addFavori(token, int.parse(userId), int.parse(document.id), entrepriseId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté aux favoris.')),
      );
    }
    await _loadFavoris();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: const Text('Favoris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilters,
            tooltip: 'Filtres',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoris,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher dans les favoris...',
                prefixIcon: const Icon(Icons.search),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          if (_selectedType != null || _selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedType != null)
                    Chip(
                      label: Text('Type: $_selectedType'),
                      onDeleted: () => setState(() => _selectedType = null),
                    ),
                  if (_selectedDateRange != null)
                    Chip(
                      label: Text(
                        'Du ${_selectedDateRange!.start.toString().substring(0,10)} au ${_selectedDateRange!.end.toString().substring(0,10)}',
                      ),
                      onDeleted: () => setState(() => _selectedDateRange = null),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _filteredFavoris.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.star_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Aucun résultat trouvé'
                              : 'Aucun document favori',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Essayez avec d\'autres termes de recherche'
                              : 'Ajoutez des documents à vos favoris',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFavoris.length,
                    itemBuilder: (context, index) {
                      final document = _filteredFavoris[index];
                      final authState = context.watch<AuthStateService>();
                      final token = authState.token;
                      final userId = authState.userId;
                      final entrepriseId = authState.entrepriseId;

                      return ListTile(
                        leading: Icon(
                          document.type.contains('pdf') ? Icons.picture_as_pdf : Icons.insert_drive_file,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(document.nomOriginal ?? document.nom.replaceAll('.enc', '')),
                        subtitle: Text(
                          document.description ?? 'Pas de description',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
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
                              case 'favori':
                                _toggleFavori(document);
                                break;
                              case 'ouvrir_nouvel_onglet':
                                _openDocument(document);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'telecharger',
                              child: Row(
                                children: [Icon(Icons.download), SizedBox(width: 8), Text('Télécharger')],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'modifier',
                              child: Row(
                                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Renommer')],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'supprimer',
                              child: Row(
                                children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'assigner_tag',
                              child: Row(
                                children: [Icon(Icons.label, color: Colors.blue), SizedBox(width: 8), Text('Assigner un tag')],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'favori',
                              child: Row(
                                children: [Icon(Icons.star_border), SizedBox(width: 8), Text('Ajouter/Retirer des favoris')],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'ouvrir_nouvel_onglet',
                              child: Row(
                                children: [Icon(Icons.open_in_new), SizedBox(width: 8), Text('Ouvrir dans un nouvel onglet')],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _openDocument(document),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 