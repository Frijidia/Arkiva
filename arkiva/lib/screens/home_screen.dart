import 'package:flutter/material.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/screens/armoires_screen.dart';
import 'package:arkiva/screens/casiers_screen.dart';
import 'package:arkiva/screens/favoris_screen.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/services/animation_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/screens/entreprise_detail_screen.dart';
import 'package:arkiva/screens/create_user_screen.dart';
import 'package:arkiva/screens/admin_dashboard_screen.dart';
import 'package:arkiva/screens/login_screen.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/screens/tags_screen.dart';
import 'package:arkiva/services/search_service.dart';
import 'package:arkiva/services/tag_service.dart';
import 'dart:html' as html;
import 'package:arkiva/screens/fichier_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _quickSearchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final TagService _tagService = TagService();
  bool _isSearching = false;
  List<dynamic> _quickResults = [];
  List<dynamic> _allTags = [];
  DateTimeRange? _selectedDateRange;
  Map<String, dynamic>? _selectedTag;
  Map<String, dynamic>? _selectedArmoire;
  Map<String, dynamic>? _selectedCasier;
  Map<String, dynamic>? _selectedDossier;

  @override
  void initState() {
    super.initState();
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
      print('Erreur lors du chargement des tags: $e');
    }
  }

  Future<void> _performQuickSearch() async {
    setState(() { _isSearching = true; });
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    if (token == null || entrepriseId == null) return;
    try {
      List<dynamic> results = [];
      
      // 1. Recherche par tag (priorité 1)
      if (_selectedTag != null && _selectedTag!['tag_id'] != null) {
        print('DEBUG: Recherche rapide par tag sélectionné: $_selectedTag');
        print('DEBUG: tag_id = ${_selectedTag!['tag_id']}');
        results = await _searchService.getFilesByTag(token, _selectedTag!['tag_id'], entrepriseId);
        print('DEBUG: Résultats de la recherche rapide par tag reçus: ${results.length} éléments');
      }
      // 2. Recherche par date (priorité 2)
      else if (_selectedDateRange != null) {
        final debut = _selectedDateRange!.start.toIso8601String().substring(0, 10);
        final fin = _selectedDateRange!.end.toIso8601String().substring(0, 10);
        results = await _searchService.searchByDate(token, debut, fin, entrepriseId);
      }
      // 3. Recherche par texte (OCR ou nom) - priorité 3
      else if (_quickSearchController.text.isNotEmpty) {
        print('DEBUG: Recherche rapide par texte: "${_quickSearchController.text}"');
        // D'abord essayer la recherche OCR
        try {
          results = await _searchService.searchByOcr(token, _quickSearchController.text, entrepriseId);
          print('DEBUG: Résultats de la recherche OCR: ${results.length} éléments');
        } catch (e) {
          print('DEBUG: Erreur recherche OCR, essai recherche flexible: $e');
          // Si OCR échoue, essayer la recherche flexible
          results = await _searchService.searchFlexible(
            token,
            entrepriseId,
            armoire: _selectedArmoire?['nom'],
            casier: _selectedCasier?['nom'],
            dossier: _selectedDossier?['nom'],
            nom: _quickSearchController.text,
          );
          print('DEBUG: Résultats de la recherche flexible: ${results.length} éléments');
        }
      }
      
      print('DEBUG: Avant setState - results.length = ${results.length}');
      print('DEBUG: Premier résultat (si existe): ${results.isNotEmpty ? results.first : "Aucun"}');
      
      setState(() {
        _quickResults = results;
        _isSearching = false;
      });
      
      print('DEBUG: Après setState - _quickResults.length = ${_quickResults.length}');
      
      _showQuickResultsDialog();
    } catch (e) {
      print('DEBUG: Erreur lors de la recherche rapide: $e');
      setState(() { _isSearching = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche : $e')),
      );
    }
  }

  void _showQuickResultsDialog() {
    final entrepriseId = context.read<AuthStateService>().entrepriseId;
    final token = context.read<AuthStateService>().token;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Résultats pour "${_quickSearchController.text}"'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: _quickResults.isEmpty
              ? const Text('Aucun document trouvé')
              : ListView.builder(
                  itemCount: _quickResults.length,
                  itemBuilder: (context, index) {
                    final doc = _quickResults[index];
                    final nomAffiche = doc['originalfilename'] ?? doc['nom'] ?? 'Document';
                    final armoire = doc['armoire'] ?? '';
                    final casier = doc['casier'] ?? '';
                    final dossier = doc['dossier'] ?? '';
                    final cheminAffiche = [armoire, casier, dossier].where((e) => e != null && e.toString().isNotEmpty).join(' > ');
                    return ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(nomAffiche),
                      subtitle: Text(cheminAffiche),
                      onTap: () {
                        Navigator.pop(context); // Fermer le dialog
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FichierViewScreen(doc: doc),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showQuickSearchFilters() {
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
                const Text('Filtres de recherche rapide', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                ),
                const SizedBox(height: 20),
                
                // Sélection de tag
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
                            color: _parseTagColor(tag['color']),
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
                
                // Sélection de date
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
                        _performQuickSearch();
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

  Color _parseTagColor(String? colorString) {
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
    final authStateService = context.watch<AuthStateService>();
    final username = authStateService.username ?? 'Utilisateur';
    final userRole = authStateService.role;
    final token = authStateService.token;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('ARKIVA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Bonjour $username',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              _navigateToScreen(context, const ScanScreen());
            },
            tooltip: 'Scanner un document',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              _navigateToScreen(context, const UploadScreen());
            },
            tooltip: 'Téléverser un fichier',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              print('Notifications button pressed');
            },
            tooltip: 'Notifications',
          ),
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () {
                _navigateToScreen(context, const AdminDashboardScreen());
              },
              tooltip: 'Tableau de bord administrateur',
            ),
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                _navigateToScreen(context, const CreateUserScreen());
              },
              tooltip: 'Créer un utilisateur',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              print('Profile/Settings button pressed');
            },
            tooltip: 'Paramètres',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthStateService>().clearAuthState();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👋 Bonjour $username !',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 12),
                  FutureBuilder<int>(
                    future: token != null ? DocumentService().fetchDocumentsCount(token) : Future.value(0),
                    builder: (context, snapshot) {
                      final docCount = snapshot.data ?? 0;
                      return Text(
                        'Vous avez : 📂 ${authStateService.armoireCount ?? 0} armoires | 🗄️ ${authStateService.casierCount ?? 0} casiers',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  if (userRole == 'admin')
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _navigateToScreen(context, const EntrepriseDetailScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          elevation: 4,
                        ),
                        icon: Icon(Icons.business, color: Colors.white),
                        label: Text('Voir infos entreprise', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 30),

            InkWell(
              onTap: () {
                final authStateService = context.read<AuthStateService>();
                final entrepriseId = authStateService.entrepriseId;
                final userId = authStateService.userId;
                
                if (entrepriseId != null && userId != null) {
                  _navigateToScreen(
                    context,
                    ArmoiresScreen(
                      entrepriseId: entrepriseId,
                      userId: int.parse(userId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur: Informations d\'entreprise manquantes'),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vos Armoires',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                      ],
                    ),
                    SizedBox(height: 16),

                    // TODO: Afficher ici les armoires récentes ou un aperçu si nécessaire
                    // Pour l'instant, cette section est un raccourci vers ArmoiresScreen
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recherche Rapide',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quickSearchController,
                          decoration: InputDecoration(
                            hintText: '🔍 Rechercher un document, un dossier ou un mot-clé...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          ),
                          onSubmitted: (text) => _performQuickSearch(),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showQuickSearchFilters,
                        child: Icon(Icons.filter_alt),
                      ),
                    ],
                  ),
                  
                  // Affichage des filtres sélectionnés
                  if (_selectedTag != null || _selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filtres actifs:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_selectedTag != null)
                                Chip(
                                  avatar: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _parseTagColor(_selectedTag!['color']),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  label: Text('Tag: ${_selectedTag!['name']}'),
                                  onDeleted: () => setState(() => _selectedTag = null),
                                ),
                              if (_selectedDateRange != null)
                                Chip(
                                  avatar: Icon(Icons.date_range, size: 16),
                                  label: Text('Du ${_selectedDateRange!.start.toString().substring(0,10)} au ${_selectedDateRange!.end.toString().substring(0,10)}'),
                                  onDeleted: () => setState(() => _selectedDateRange = null),
                                ),
                            ],
                          ),
                          SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _performQuickSearch,
                            icon: Icon(Icons.search),
                            label: Text('Lancer la recherche'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accès Rapide',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),

                  Column(
                    children: [
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.star, size: 28, color: Colors.amber[700]),
                          title: Text('Documents favoris', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            _navigateToScreen(context, const FavorisScreen());
                          },
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.history, size: 28, color: Colors.blue[700]),
                          title: Text('Documents récemment consultés', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            print('Tapped on Documents récemment consultés');
                          },
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.recent_actors, size: 28, color: Colors.green[700]),
                          title: Text('Derniers documents', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            print('Tapped on Derniers documents');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _showCreateArmoireDialog(BuildContext context) async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une nouvelle armoire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'armoire',
                hintText: 'Ex: Armoire personnelle',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (facultatif)',
                hintText: 'Ex: Documents importants',
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
      print('Nouvelle armoire à créer: Nom - ${result['nom']}, Description - ${result['description']}');
    }
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 