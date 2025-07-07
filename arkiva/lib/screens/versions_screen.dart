import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/version_service.dart';
import 'package:arkiva/services/restore_service.dart';
import 'package:arkiva/models/version.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/config/api_config.dart';
import 'package:arkiva/widgets/select_target_dialog.dart';

class VersionsScreen extends StatefulWidget {
  const VersionsScreen({super.key});

  @override
  State<VersionsScreen> createState() => _VersionsScreenState();
}

class _VersionsScreenState extends State<VersionsScreen> {
  List<Version> _versions = [];
  bool _isLoading = true;
  String? _error;
  String _selectedType = 'fichier';
  int? _selectedCibleId;

  final List<String> _availableTypes = ['fichier', 'dossier', 'casier', 'armoire'];

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    if (_selectedCibleId == null) {
      setState(() {
        _versions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final versionsData = await VersionService.getVersionHistory(
        token: token,
        cibleId: _selectedCibleId!,
        type: _selectedType,
      );
      final versions = versionsData.map((json) => Version.fromJson(json)).toList();

      setState(() {
        _versions = versions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createVersion() async {
    if (_selectedCibleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une cible')),
      );
      return;
    }

    final authStateService = context.read<AuthStateService>();
    final token = authStateService.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token d\'authentification manquant')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateVersionDialog(),
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);
        print('Appel à VersionService.createVersion avec: cibleId=$_selectedCibleId, type=$_selectedType, description= [0m${result['description']}');
        try {
          final backendResponse = await VersionService.createVersion(
            token: token,
            cibleId: _selectedCibleId!,
            type: _selectedType,
            description: result['description'],
          );
        } catch (e) {
          print('Erreur lors de la création de version: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: $e')),
            );
          }
          setState(() => _isLoading = false);
        }

        await _loadVersions();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Version créée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadVersion(Version version) async {
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final downloadUrl = await VersionService.getVersionDownloadUrl(
        token: token,
        versionId: version.id,
      );

      if (await canLaunchUrl(Uri.parse(downloadUrl))) {
        await launchUrl(Uri.parse(downloadUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Téléchargement démarré')),
        );
      } else {
        throw Exception('Impossible d\'ouvrir l\'URL de téléchargement');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement: $e')),
      );
    }
  }

  Future<void> _viewVersionContent(Version version) async {
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final content = await VersionService.getVersionContent(
        token: token,
        versionId: version.id,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Contenu de la version ${version.versionNumber}'),
            content: SingleChildScrollView(
              child: Text(
                content.toString(),
                style: const TextStyle(fontFamily: 'monospace'),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération du contenu: $e')),
      );
    }
  }

  Future<void> _deleteVersion(Version version) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la version'),
        content: Text('Êtes-vous sûr de vouloir supprimer la version ${version.versionNumber} ? Cette action est irréversible.'),
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

        if (token == null) {
          throw Exception('Token d\'authentification manquant');
        }

        await VersionService.deleteVersion(
          token: token,
          versionId: version.id,
        );

        await _loadVersions();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Version supprimée avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  Future<void> _restoreVersion(Version version) async {
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      // Afficher le dialogue de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la restauration'),
          content: Text(
            'Êtes-vous sûr de vouloir restaurer cette version ?\n\n'
            'Type: ${version.typeDisplay}\n'
            'Version: v${version.versionNumber}\n'
            'Date: ${version.formattedDate}\n'
            'Description: ${version.description ?? 'Aucune'}\n\n'
            '⚠️ Cette action va créer un nouvel élément et ne remplacera pas l\'existant.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restaurer'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() => _isLoading = true);

        final result = await RestoreService.restoreVersion(
          token: token,
          versionId: version.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Version restaurée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la restauration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Versions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createVersion,
            tooltip: 'Créer une version',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVersions,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _versions.isEmpty
                        ? _buildEmptyWidget()
                        : _buildVersionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createVersion,
        child: const Icon(Icons.add),
        tooltip: 'Créer une version',
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionner la cible',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: _availableTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(_getTypeDisplayName(type)),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  _selectedCibleId = null;
                  _versions = [];
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTargetSelectionDialog(),
                icon: const Icon(Icons.search),
                label: const Text('Sélectionner une cible'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTargetSelectionDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SelectTargetDialog(selectedType: _selectedType),
    );

    if (result != null) {
      setState(() {
        _selectedCibleId = result['cibleId'];
      });
      _loadVersions();
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'fichier':
        return 'Fichier';
      case 'dossier':
        return 'Dossier';
      case 'casier':
        return 'Casier';
      case 'armoire':
        return 'Armoire';
      default:
        return type;
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Erreur lors du chargement',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadVersions,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune version',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre première version',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createVersion,
            icon: const Icon(Icons.add),
            label: const Text('Créer une version'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionsList() {
    return RefreshIndicator(
      onRefresh: _loadVersions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _versions.length,
        itemBuilder: (context, index) {
          final version = _versions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: _getVersionIcon(version.type),
              title: Text('v${version.versionNumber} - ${version.formattedDate}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (version.description != null && version.description!.isNotEmpty)
                    Text(version.description!),
                  Text('Taille: ${version.formattedSize}'),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'restore':
                      _restoreVersion(version);
                      break;
                    case 'view':
                      _viewVersionContent(version);
                      break;
                    case 'download':
                      _downloadVersion(version);
                      break;
                    case 'delete':
                      _deleteVersion(version);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(Icons.restore, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Restaurer', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('Voir le contenu'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('Télécharger'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getVersionIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'fichier':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'dossier':
        iconData = Icons.folder;
        iconColor = Colors.orange;
        break;
      case 'casier':
        iconData = Icons.inventory_2;
        iconColor = Colors.green;
        break;
      case 'armoire':
        iconData = Icons.warehouse;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.history;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor, size: 32);
  }
}

class _CreateVersionDialog extends StatefulWidget {
  @override
  State<_CreateVersionDialog> createState() => _CreateVersionDialogState();
}

class _CreateVersionDialogState extends State<_CreateVersionDialog> {
  String _selectedType = 'fichier';
  String? _selectedArmoire;
  String? _selectedCasier;
  String? _selectedDossier;
  String? _selectedFichier;
  
  List<Map<String, dynamic>> _armoires = [];
  List<Map<String, dynamic>> _casiers = [];
  List<Map<String, dynamic>> _dossiers = [];
  List<Map<String, dynamic>> _fichiers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArmoires();
  }

  Future<void> _loadArmoires() async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      print('Chargement des armoires pour entrepriseId= [0m$entrepriseId avec token=$token');

      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/armoire/$entrepriseId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        print('Réponse backend armoires: status=${response.statusCode}, body=${response.body}');
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _armoires = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des armoires: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCasiers(String armoireId) async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token != null) {
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
            _casiers = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDossiers(String casierId) async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token != null) {
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
            _dossiers = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFichiers(String dossierId) async {
    setState(() => _isLoading = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/fichier/$dossierId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _fichiers = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int? get _selectedCibleId {
    switch (_selectedType) {
      case 'armoire':
        return _selectedArmoire != null ? int.tryParse(_selectedArmoire!) : null;
      case 'casier':
        return _selectedCasier != null ? int.tryParse(_selectedCasier!) : null;
      case 'dossier':
        return _selectedDossier != null ? int.tryParse(_selectedDossier!) : null;
      case 'fichier':
        return _selectedFichier != null ? int.tryParse(_selectedFichier!) : null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une version'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de version',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'fichier', child: Text('Fichier')),
                DropdownMenuItem(value: 'dossier', child: Text('Dossier')),
                DropdownMenuItem(value: 'casier', child: Text('Casier')),
                DropdownMenuItem(value: 'armoire', child: Text('Armoire')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  // Réinitialiser les sélections
                  _selectedArmoire = null;
                  _selectedCasier = null;
                  _selectedDossier = null;
                  _selectedFichier = null;
                  _casiers.clear();
                  _dossiers.clear();
                  _fichiers.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            
            if (_selectedType == 'armoire' || _selectedType == 'casier' || _selectedType == 'dossier' || _selectedType == 'fichier')
              DropdownButtonFormField<String>(
                value: _selectedArmoire,
                decoration: const InputDecoration(
                  labelText: 'Sélectionner une armoire',
                  prefixIcon: Icon(Icons.warehouse),
                ),
                items: _armoires.map((armoire) => DropdownMenuItem(
                  value: armoire['armoire_id'].toString(),
                  child: Text(armoire['nom']),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedArmoire = value;
                    _selectedCasier = null;
                    _selectedDossier = null;
                    _selectedFichier = null;
                    _casiers.clear();
                    _dossiers.clear();
                    _fichiers.clear();
                  });
                  if (value != null) {
                    _loadCasiers(value);
                  }
                },
              ),
            
            if (_selectedType == 'casier' || _selectedType == 'dossier' || _selectedType == 'fichier')
              if (_selectedArmoire != null) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCasier,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un casier',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  items: _casiers.map((casier) => DropdownMenuItem(
                    value: casier['cassier_id'].toString(),
                    child: Text('${casier['nom']}${casier['sous_titre'] != null && casier['sous_titre'].isNotEmpty ? ' - ${casier['sous_titre']}' : ''}'),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCasier = value;
                      _selectedDossier = null;
                      _selectedFichier = null;
                      _dossiers.clear();
                      _fichiers.clear();
                    });
                    if (value != null) {
                      _loadDossiers(value);
                    }
                  },
                ),
              ],
            
            if (_selectedType == 'dossier' || _selectedType == 'fichier')
              if (_selectedCasier != null) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDossier,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un dossier',
                    prefixIcon: Icon(Icons.folder),
                  ),
                  items: _dossiers.map((dossier) => DropdownMenuItem(
                    value: dossier['dossier_id'].toString(),
                    child: Text(dossier['nom']),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDossier = value;
                      _selectedFichier = null;
                      _fichiers.clear();
                    });
                    if (value != null && _selectedType == 'fichier') {
                      _loadFichiers(value);
                    }
                  },
                ),
              ],
            
            if (_selectedType == 'fichier')
              if (_selectedDossier != null) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedFichier,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un fichier',
                    prefixIcon: Icon(Icons.description),
                  ),
                  items: _fichiers.map((fichier) => DropdownMenuItem(
                    value: fichier['id'].toString(),
                    child: Text(fichier['nom'] ?? fichier['originalfilename'] ?? 'Fichier'),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFichier = value;
                    });
                  },
                ),
              ],
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedCibleId != null
              ? () {
                  Navigator.pop(context, {
                    'type': _selectedType,
                    'cibleId': _selectedCibleId,
                  });
                }
              : null,
          child: const Text('Créer'),
        ),
      ],
    );
  }
} 