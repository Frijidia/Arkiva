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
import 'package:arkiva/screens/settings_screen.dart';
import 'package:arkiva/screens/login_screen.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/screens/tags_screen.dart';
import 'package:arkiva/services/search_service.dart';
import 'package:arkiva/services/tag_service.dart';
import 'package:arkiva/screens/fichier_view_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/config/api_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _quickSearchController = TextEditingController();
  final TextEditingController _armoireController = TextEditingController();
  final TextEditingController _casierController = TextEditingController();
  final TextEditingController _dossierController = TextEditingController();
  final SearchService _searchService = SearchService();
  final TagService _tagService = TagService();
  bool _isSearching = false;
  List<dynamic> _quickResults = [];
  List<dynamic> _allTags = [];
  DateTimeRange? _selectedDateRange;
  Map<String, dynamic>? _selectedTag;

  // Dropdown dépendants
  List<dynamic> _allArmoires = [];
  List<dynamic> _allCasiers = [];
  List<dynamic> _allDossiers = [];
  String? _selectedArmoire;
  String? _selectedCasier;
  String? _selectedDossier;

  // Ajout des listes pour la sélection multiple
  List<String> _selectedArmoiresMulti = [];
  List<String> _selectedCasiersMulti = [];
  List<String> _selectedDossiersMulti = [];

  // Ajout des variables d'état pour les filtres principaux
  bool _filterArmoires = true;
  bool _filterCasiers = true;
  bool _filterDossiers = true;
  bool _filterFichiers = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
    _loadArmoires();
    _loadAllCasiers();
  }

  @override
  void dispose() {
    _quickSearchController.dispose();
    _armoireController.dispose();
    _casierController.dispose();
    _dossierController.dispose();
    super.dispose();
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
          setState(() {
            _allArmoires = data;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement armoires: $e');
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
          setState(() {
            _allCasiers = data;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement casiers: $e');
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
          setState(() {
            _allDossiers = data;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement dossiers: $e');
    }
  }

  Future<void> _loadAllCasiers() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/casier/getcasiers'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _allCasiers = data;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement tous les casiers: $e');
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
      // Déterminer les filtres cochés dans l'ordre
      final List<String> filtres = [];
      if (_filterArmoires) filtres.add('armoire');
      if (_filterCasiers) filtres.add('casier');
      if (_filterDossiers) filtres.add('dossier');
      if (_filterFichiers) filtres.add('nom');
      final input = _quickSearchController.text.trim();
      final parts = input.split(RegExp(r'[ ,;]+'));
      if (parts.length < filtres.length) {
        setState(() { _isSearching = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci de saisir un nom pour chaque filtre sélectionné.')),
        );
        return;
      }
      // Gestion de la sélection multiple
      Set<dynamic> allResults = {};
      if (_selectedArmoiresMulti.isNotEmpty || _selectedCasiersMulti.isNotEmpty || _selectedDossiersMulti.isNotEmpty) {
        // Pour chaque combinaison sélectionnée, faire une requête
        for (var armoireNom in _selectedArmoiresMulti.isNotEmpty ? _selectedArmoiresMulti : [null]) {
          for (var casierNom in _selectedCasiersMulti.isNotEmpty ? _selectedCasiersMulti : [null]) {
            for (var dossierNom in _selectedDossiersMulti.isNotEmpty ? _selectedDossiersMulti : [null]) {
              final res = await _searchService.searchFlexible(
                token,
                entrepriseId,
                armoire: armoireNom,
                casier: casierNom,
                dossier: dossierNom,
                nom: filtres.contains('nom') ? parts[filtres.indexOf('nom')] : null,
              );
              allResults.addAll(res);
            }
          }
        }
        results = allResults.toList();
      } else {
        // Cas classique : un seul filtre par champ
        Map<String, String?> params = {};
        for (int i = 0; i < filtres.length; i++) {
          params[filtres[i]] = parts[i];
        }
        params['entreprise_id'] = entrepriseId.toString();
        results = await _searchService.searchFlexible(
          token,
          entrepriseId,
          armoire: params['armoire'],
          casier: params['casier'],
          dossier: params['dossier'],
          nom: params['nom'],
        );
      }
      setState(() {
        _quickResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() { _isSearching = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche : $e')),
      );
    }
  }

  Widget _buildQuickResultsList() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_quickResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Aucun document trouvé', style: TextStyle(fontSize: 16))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _quickResults.length,
      itemBuilder: (context, index) {
        final doc = _quickResults[index];
        final nomAffiche = doc['originalfilename'] ?? doc['nom'] ?? 'Document';
        final cheminAffiche = doc['chemin'] ??
          [doc['armoire_nom'] ?? doc['armoire'], doc['casier_nom'] ?? doc['casier'], doc['dossier_nom'] ?? doc['dossier']]
            .where((e) => e != null && e.toString().isNotEmpty).join(' > ');
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: const Icon(Icons.description),
            title: Text(nomAffiche),
            subtitle: Text(cheminAffiche),
            onTap: () {
    Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FichierViewScreen(doc: doc),
                ),
              );
            },
          ),
        );
      },
    );
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

  void _showMultiSelectFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) => Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 420,
                minWidth: 320,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtres multi-sélection',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blueGrey)),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Section Rechercher par
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rechercher par :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Checkbox(
                              value: _filterArmoires,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterArmoires = v!;
                                  _updateTousSB();
                                });
                              },
                            ),
                            const Text('Armoires'),
                            Checkbox(
                              value: _filterCasiers,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterCasiers = v!;
                                  _updateTousSB();
                                });
                              },
                            ),
                            const Text('Casiers'),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _filterDossiers,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterDossiers = v!;
                                  _updateTousSB();
                                });
                              },
                            ),
                            const Text('Dossiers'),
                            Checkbox(
                              value: _filterFichiers,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterFichiers = v!;
                                  _updateTousSB();
                                });
                              },
                            ),
                            const Text('Fichiers'),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _filterArmoires && _filterCasiers && _filterDossiers && _filterFichiers,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterArmoires = v!;
                                  _filterCasiers = v;
                                  _filterDossiers = v;
                                  _filterFichiers = v;
                                });
                              },
                            ),
                            const Text('Tous', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _quickSearchController,
                    decoration: InputDecoration(
                      labelText: 'Nom du fichier ou mot-clé',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_filterArmoires) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Armoires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _selectedArmoiresMulti.length == _allArmoires.length && _allArmoires.isNotEmpty,
                                      onChanged: (v) {
                                        setStateSB(() {
                                          if (v == true) {
                                            _selectedArmoiresMulti = _allArmoires.map<String>((a) => a['nom']).toList();
                                          } else {
                                            _selectedArmoiresMulti.clear();
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue[700],
                                    ),
                                    Text('Tous', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            ..._allArmoires.map<Widget>((armoire) => CheckboxListTile(
                              value: _selectedArmoiresMulti.contains(armoire['nom']),
                              onChanged: (v) {
                                setStateSB(() {
                                  if (v == true) {
                                    _selectedArmoiresMulti.add(armoire['nom']);
                                  } else {
                                    _selectedArmoiresMulti.remove(armoire['nom']);
                                  }
                                });
                              },
                              title: Text(armoire['nom']),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.blue[700],
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            )),
                            const SizedBox(height: 14),
                          ],
                          if (_filterCasiers) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Casiers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _selectedCasiersMulti.length == _allCasiers.length && _allCasiers.isNotEmpty,
                                      onChanged: (v) {
                                        setStateSB(() {
                                          if (v == true) {
                                            _selectedCasiersMulti = _allCasiers.map<String>((c) => c['cassier_id'].toString()).toList();
                                          } else {
                                            _selectedCasiersMulti.clear();
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue[700],
                                    ),
                                    Text('Tous', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            ..._allCasiers.map<Widget>((casier) => CheckboxListTile(
                              value: _selectedCasiersMulti.contains(casier['cassier_id'].toString()),
                              onChanged: (v) {
                                setStateSB(() {
                                  if (v == true) {
                                    _selectedCasiersMulti.add(casier['cassier_id'].toString());
                                  } else {
                                    _selectedCasiersMulti.remove(casier['cassier_id'].toString());
                                  }
                                });
                              },
                              title: Text(casier['nom']),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.blue[700],
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            )),
                            const SizedBox(height: 14),
                          ],
                          if (_filterDossiers) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Dossiers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _selectedDossiersMulti.length == _allDossiers.length && _allDossiers.isNotEmpty,
                                      onChanged: (v) {
                                        setStateSB(() {
                                          if (v == true) {
                                            _selectedDossiersMulti = _allDossiers.map<String>((d) => d['dossier_id'].toString()).toList();
                                          } else {
                                            _selectedDossiersMulti.clear();
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue[700],
                                    ),
                                    Text('Tous', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            ..._allDossiers.map<Widget>((dossier) => CheckboxListTile(
                              value: _selectedDossiersMulti.contains(dossier['dossier_id'].toString()),
                              onChanged: (v) {
                                setStateSB(() {
                                  if (v == true) {
                                    _selectedDossiersMulti.add(dossier['dossier_id'].toString());
                                  } else {
                                    _selectedDossiersMulti.remove(dossier['dossier_id'].toString());
                                  }
                                });
                              },
                              title: Text(dossier['nom']),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.blue[700],
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            )),
                            const SizedBox(height: 14),
                          ],
                          // Fichiers : rien à afficher, c'est juste le champ texte
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _performQuickSearch();
                            setState(() {});
                          },
                          icon: Icon(Icons.check),
                          label: Text('Valider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            minimumSize: Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          setStateSB(() {
                            _selectedArmoiresMulti.clear();
                            _selectedCasiersMulti.clear();
                            _selectedDossiersMulti.clear();
                            _quickSearchController.clear();
                            _filterArmoires = true;
                            _filterCasiers = true;
                            _filterDossiers = true;
                            _filterFichiers = true;
                          });
                        },
                        child: Text('Réinitialiser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.blueGrey,
                          minimumSize: Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Fonction utilitaire pour gérer la logique de la case Tous
  void _updateTousSB() {
    // Cette fonction est appelée à chaque changement d'une case individuelle
    // Elle met à jour la case "Tous" automatiquement si besoin
    // (rien à faire ici car la case "Tous" dépend directement des autres)
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              _navigateToScreen(context, const SettingsScreen());
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
                  TextField(
                    controller: _quickSearchController,
                    decoration: InputDecoration(
                      hintText: 'Nom du fichier ou mot-clé',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (text) => _performQuickSearch(),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showMultiSelectFilters,
                        icon: Icon(Icons.filter_list),
                        label: Text('Filtrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[900],
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _performQuickSearch,
                        icon: Icon(Icons.search),
                        label: Text('Rechercher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Affichage des résultats sous la barre de recherche
                  _buildQuickResultsList(),
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
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.backup, size: 28, color: Colors.orange[700]),
                          title: Text('Sauvegardes', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            Navigator.pushNamed(context, '/backups');
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
                          leading: Icon(Icons.history, size: 28, color: Colors.purple[700]),
                          title: Text('Versions', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            Navigator.pushNamed(context, '/versions');
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
                          leading: Icon(Icons.restore, size: 28, color: Colors.teal[700]),
                          title: Text('Restaurations', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            Navigator.pushNamed(context, '/restorations');
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