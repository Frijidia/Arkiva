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

  // Widgets helpers pour un design moderne
  Widget _buildModernCard({
    required Widget child,
    Color? color,
    EdgeInsets? padding,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: padding ?? EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: color != null ? LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }

  Widget _buildDocumentCard(Document document) {
    IconData iconData;
    Color iconColor;
    
    if (document.type.contains('pdf')) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (document.type.contains('image')) {
      iconData = Icons.image;
      iconColor = Colors.green;
    } else if (document.type.contains('document')) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (document.type.contains('spreadsheet')) {
      iconData = Icons.table_chart;
      iconColor = Colors.orange;
    } else if (document.type.contains('presentation')) {
      iconData = Icons.slideshow;
      iconColor = Colors.purple;
    } else if (document.type.contains('archive')) {
      iconData = Icons.archive;
      iconColor = Colors.brown;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return _buildModernCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.nomOriginal ?? document.nom.replaceAll('.enc', ''),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      document.description ?? 'Pas de description',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (document.dateCreation != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Créé le ${document.dateCreation!.toString().substring(0, 10)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
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
                  PopupMenuItem(
                    value: 'telecharger',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text('Télécharger'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'modifier',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.orange[600]),
                        SizedBox(width: 8),
                        Text('Renommer'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'assigner_tag',
                    child: Row(
                      children: [
                        Icon(Icons.label, color: Colors.green[600]),
                        SizedBox(width: 8),
                        Text('Assigner un tag'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'favori',
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600]),
                        SizedBox(width: 8),
                        Text('Retirer des favoris'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ouvrir_nouvel_onglet',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new, color: Colors.purple[600]),
                        SizedBox(width: 8),
                        Text('Ouvrir'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'supprimer',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red[600]),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDocument(document),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('Voir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _telechargerDocument(document),
                  icon: Icon(Icons.download, size: 16),
                  label: Text('Télécharger'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return _buildModernCard(
      color: Colors.blue[50],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher dans vos favoris...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_selectedType == null && _selectedDateRange == null) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedType != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.blue[700]),
                  SizedBox(width: 4),
                  Text(
                    'Type: $_selectedType',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _selectedType = null),
                    child: Icon(Icons.close, size: 16, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          if (_selectedDateRange != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.green[700]),
                  SizedBox(width: 4),
                  Text(
                    'Du ${_selectedDateRange!.start.toString().substring(0,10)} au ${_selectedDateRange!.end.toString().substring(0,10)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDateRange = null),
                    child: Icon(Icons.close, size: 16, color: Colors.green[700]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setStateSB) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.blue[600]),
                    SizedBox(width: 8),
                    Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildModernCard(
                  color: Colors.blue[50],
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type de document',
                      prefixIcon: Icon(Icons.description, color: Colors.blue[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                ),
                SizedBox(height: 16),
                _buildModernCard(
                  color: Colors.green[50],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.date_range, color: Colors.green[600]),
                            SizedBox(width: 8),
                            Text(
                              'Période d\'ajout',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          _selectedDateRange == null 
                            ? 'Non sélectionnée' 
                            : 'Du ${_selectedDateRange!.start.toString().substring(0,10)} au ${_selectedDateRange!.end.toString().substring(0,10)}',
                          style: TextStyle(
                            color: _selectedDateRange == null ? Colors.grey : Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 12),
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
                          icon: Icon(Icons.calendar_today, size: 16),
                          label: Text(_selectedDateRange == null ? 'Sélectionner une période' : 'Modifier la période'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedType = null;
                            _selectedDateRange = null;
                          });
                          setStateSB(() {});
                        },
                        icon: Icon(Icons.refresh, size: 16),
                        label: Text('Réinitialiser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.check, size: 16),
                        label: Text('Appliquer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
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
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.orange[600]),
            SizedBox(width: 8),
            Text('Modifier le document'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: InputDecoration(
                labelText: 'Nom du document',
                hintText: 'Entrez le nouveau nom',
                prefixIcon: Icon(Icons.description, color: Colors.blue[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (facultatif)',
                hintText: 'Entrez la nouvelle description',
                prefixIcon: Icon(Icons.info, color: Colors.green[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Enregistrer'),
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
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Supprimer le document'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer "${document.nomOriginal ?? document.nom.replaceAll('.enc', '')}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Supprimer'),
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
            title: Row(
              children: [
                Icon(Icons.label, color: Colors.green[600]),
                SizedBox(width: 8),
                Text('Assigner un tag'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : error != null
                      ? Text(error!, style: TextStyle(color: Colors.red))
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Rechercher un tag',
                                  prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) => setStateSB(() => search = value),
                              ),
                              SizedBox(height: 12),
                              if (suggestedTags.isNotEmpty) ...[
                                Text(
                                  'Tags suggérés',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[700]),
                                ),
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: suggestedTags.map<Widget>((tag) => ActionChip(
                                    avatar: Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                                    label: Text(tag['name']),
                                    backgroundColor: Colors.blue[50],
                                    onPressed: () => Navigator.pop(context, tag['name']),
                                    tooltip: 'Cliquez pour assigner ce tag suggéré',
                                  )).toList(),
                                ),
                                Divider(height: 24),
                              ],
                              if (popularTags.isNotEmpty) ...[
                                Text(
                                  'Tags populaires',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[700]),
                                ),
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: popularTags.map<Widget>((tag) => ActionChip(
                                    avatar: Icon(Icons.trending_up, size: 16, color: Colors.green),
                                    label: Text(tag),
                                    backgroundColor: Colors.green[50],
                                    onPressed: () => Navigator.pop(context, tag),
                                    tooltip: 'Cliquez pour assigner ce tag populaire',
                                  )).toList(),
                                ),
                                Divider(height: 24),
                              ],
                              Text(
                                'Tous les tags',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[700]),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                height: 180,
                                child: ListView(
                                  children: filteredTags.map<Widget>((tag) => ListTile(
                                    title: Text(tag['name']),
                                    onTap: () => setStateSB(() => selectedTag = tag['name']),
                                    selected: selectedTag == tag['name'],
                                    trailing: selectedTag == tag['name'] ? Icon(Icons.check, color: Colors.blue) : null,
                                  )).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: selectedTag == null ? null : () => Navigator.pop(context, selectedTag),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: Text('Assigner'),
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
      return Scaffold(
        body: Center(
          child: _buildModernCard(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement de vos favoris...'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber[900]!, Colors.amber[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Mes Favoris',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _openFilters,
            tooltip: 'Filtres',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFavoris,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: _buildModernSearchBar(),
          ),
          _buildFilterChips(),
          SizedBox(height: 8),
          Expanded(
            child: _filteredFavoris.isEmpty
                ? Center(
                    child: _buildModernCard(
                      color: Colors.grey[50],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.star_border,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Aucun résultat trouvé'
                                : 'Aucun document favori',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Essayez avec d\'autres termes de recherche'
                                : 'Ajoutez des documents à vos favoris',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(20),
                    itemCount: _filteredFavoris.length,
                    itemBuilder: (context, index) {
                      final document = _filteredFavoris[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _buildDocumentCard(document),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 