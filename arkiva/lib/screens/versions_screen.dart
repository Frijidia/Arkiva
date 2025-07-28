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

  Widget _buildVersionCard(Version version) {
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
                  color: _getVersionColor(version.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getVersionIcon(version.type),
                  color: _getVersionColor(version.type),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[300]!),
                          ),
                          child: Text(
                            'v${version.versionNumber}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          version.formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    if (version.description != null && version.description!.isNotEmpty)
                      Text(
                        version.description!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getVersionColor(version.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getVersionColor(version.type).withOpacity(0.3)),
                      ),
                      child: Text(
                        version.formattedSize,
                        style: TextStyle(
                          color: _getVersionColor(version.type),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
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
                  PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(Icons.restore, color: Colors.green[600]),
                        SizedBox(width: 8),
                        Text('Restaurer'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text('Voir le contenu'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Colors.orange[600]),
                        SizedBox(width: 8),
                        Text('Télécharger'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
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
                  onPressed: () => _restoreVersion(version),
                  icon: Icon(Icons.restore, size: 16),
                  label: Text('Restaurer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
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
                  onPressed: () => _viewVersionContent(version),
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
                  onPressed: () => _downloadVersion(version),
                  icon: Icon(Icons.download, size: 16),
                  label: Text('Télécharger'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
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

  Color _getVersionColor(String type) {
    switch (type) {
      case 'fichier':
        return Colors.blue;
      case 'dossier':
        return Colors.orange;
      case 'casier':
        return Colors.green;
      case 'armoire':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getVersionIcon(String type) {
    switch (type) {
      case 'fichier':
        return Icons.description;
      case 'dossier':
        return Icons.folder;
      case 'casier':
        return Icons.inventory_2;
      case 'armoire':
        return Icons.warehouse;
      default:
        return Icons.history;
    }
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
            title: Row(
              children: [
                Icon(Icons.visibility, color: Colors.blue[600]),
                SizedBox(width: 8),
                Text('Contenu de la version ${version.versionNumber}'),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
              child: Text(
                content.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
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
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Supprimer la version'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer la version ${version.versionNumber} ? Cette action est irréversible.'),
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
          title: Row(
            children: [
              Icon(Icons.restore, color: Colors.green[600]),
              SizedBox(width: 8),
              Text('Confirmer la restauration'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Êtes-vous sûr de vouloir restaurer cette version ?\n\n',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              _buildInfoRow('Type', version.typeDisplay),
              _buildInfoRow('Version', 'v${version.versionNumber}'),
              _buildInfoRow('Date', version.formattedDate),
              _buildInfoRow('Description', version.description ?? 'Aucune'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
            '⚠️ Cette action va créer un nouvel élément et ne remplacera pas l\'existant.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Restaurer'),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[900]!, Colors.teal[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.history, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Versions',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _createVersion,
            tooltip: 'Créer une version',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
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
                ? Center(
                    child: _buildModernCard(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Chargement des versions...'),
                        ],
                      ),
                    ),
                  )
                : _error != null
                    ? _buildErrorWidget()
                    : _versions.isEmpty
                        ? _buildEmptyWidget()
                        : _buildVersionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createVersion,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Créer', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[600],
        tooltip: 'Créer une version',
      ),
    );
  }

  Widget _buildFilterSection() {
    return _buildModernCard(
      color: Colors.teal[50],
      padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.teal[600]),
              SizedBox(width: 8),
              Text(
              'Sélectionner la cible',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.teal[700],
                ),
            ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
              value: _selectedType,
                  decoration: InputDecoration(
                labelText: 'Type',
                    prefixIcon: Icon(Icons.category, color: Colors.teal[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              ),
              SizedBox(width: 16),
              Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showTargetSelectionDialog(),
                  icon: Icon(Icons.search, size: 16),
                  label: Text('Sélectionner une cible'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
      child: _buildModernCard(
        color: Colors.red[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
          Text(
            'Erreur lors du chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
          ),
            ),
            SizedBox(height: 8),
          Text(
            _error!,
              style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
            SizedBox(height: 16),
            ElevatedButton.icon(
            onPressed: _loadVersions,
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: _buildModernCard(
        color: Colors.teal[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(Icons.history, size: 64, color: Colors.teal[400]),
            SizedBox(height: 16),
            Text(
            'Aucune version',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
          ),
            ),
            SizedBox(height: 8),
            Text(
            'Créez votre première version',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
          ),
            SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createVersion,
              icon: Icon(Icons.add, size: 16),
              label: Text('Créer une version'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
              ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildVersionsList() {
    return RefreshIndicator(
      onRefresh: _loadVersions,
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: _versions.length,
        itemBuilder: (context, index) {
          final version = _versions[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _buildVersionCard(version),
          );
        },
      ),
    );
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
      title: Row(
        children: [
          Icon(Icons.history, color: Colors.teal[600]),
          SizedBox(width: 8),
          Text('Créer une version'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type de version',
                prefixIcon: Icon(Icons.category, color: Colors.teal[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            SizedBox(height: 16),
            
            if (_selectedType == 'armoire' || _selectedType == 'casier' || _selectedType == 'dossier' || _selectedType == 'fichier')
              DropdownButtonFormField<String>(
                value: _selectedArmoire,
                decoration: InputDecoration(
                  labelText: 'Sélectionner une armoire',
                  prefixIcon: Icon(Icons.warehouse, color: Colors.purple[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCasier,
                  decoration: InputDecoration(
                    labelText: 'Sélectionner un casier',
                    prefixIcon: Icon(Icons.inventory_2, color: Colors.green[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDossier,
                  decoration: InputDecoration(
                    labelText: 'Sélectionner un dossier',
                    prefixIcon: Icon(Icons.folder, color: Colors.orange[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedFichier,
                  decoration: InputDecoration(
                    labelText: 'Sélectionner un fichier',
                    prefixIcon: Icon(Icons.description, color: Colors.blue[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
          ),
          child: Text('Créer'),
        ),
      ],
    );
  }
} 