import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/backup_service.dart';
import 'package:arkiva/services/restore_service.dart';
import 'package:arkiva/models/backup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/config/api_config.dart';
import 'package:arkiva/services/armoire_service.dart';

class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  final BackupService _backupService = BackupService();
  List<Backup> _backups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
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

      final backupsData = await BackupService.getAllBackups(token: token);
      final backups = backupsData.map((json) => Backup.fromJson(json)).toList();

      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    final authStateService = context.read<AuthStateService>();
    final token = authStateService.token;
    final entrepriseId = authStateService.entrepriseId;

    if (token == null || entrepriseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Informations d\'authentification manquantes')),
      );
      return;
    }

    // Afficher le dialogue de sélection du type de sauvegarde
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateBackupDialog(),
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);

        final backendResponse = await BackupService.createBackup(
          token: token,
          type: result['type'],
          cibleId: result['cibleId'] ?? 0,
          entrepriseId: entrepriseId,
        );

        await _loadBackups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sauvegarde créée avec succès')),
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

  Future<void> _downloadBackup(Backup backup) async {
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final downloadUrl = await BackupService.getBackupDownloadUrl(
        token: token,
        backupId: backup.id,
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

  Future<void> _deleteBackup(Backup backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la sauvegarde'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette sauvegarde ? Cette action est irréversible.'),
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
      // TODO: Implémenter la suppression de sauvegarde
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fonctionnalité de suppression à implémenter')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadDossiersOfCasier(int casierId, String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/dosier/$casierId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  Future<void> _restoreBackup(Backup backup) async {
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token == null || entrepriseId == null) {
        throw Exception('Token ou entrepriseId manquant');
      }

      int? selectedArmoireId;
      int? selectedCasierId;
      int? selectedDossierId;

      if (backup.type == 'casier') {
        final armoireService = ArmoireService();
        final armoires = await armoireService.getAllArmoiresForDeplacement(entrepriseId);
        selectedArmoireId = await showDialog<int>(
          context: context,
          builder: (context) {
            int? tempSelectedId;
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Choisir une armoire de destination'),
                  content: DropdownButton<int>(
                    isExpanded: true,
                    value: tempSelectedId,
                    hint: Text('Sélectionner une armoire'),
                    items: armoires.map<DropdownMenuItem<int>>((armoire) {
                      return DropdownMenuItem<int>(
                        value: armoire['armoire_id'],
                        child: Text(armoire['nom']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        tempSelectedId = value;
                      });
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: tempSelectedId == null
                          ? null
                          : () => Navigator.pop(context, tempSelectedId),
                      child: Text('Restaurer'),
                    ),
                  ],
                );
              },
            );
          },
        );
        if (selectedArmoireId == null) return;
      } else if (backup.type == 'dossier') {
        final armoireService = ArmoireService();
        final casiers = await armoireService.getAllCasiers(entrepriseId);
        selectedCasierId = await showDialog<int>(
          context: context,
          builder: (context) {
            int? tempSelectedId;
            return AlertDialog(
              title: Text('Choisir un casier de destination'),
              content: DropdownButton<int>(
                isExpanded: true,
                value: tempSelectedId,
                hint: Text('Sélectionner un casier'),
                items: casiers.map<DropdownMenuItem<int>>((casier) {
                  return DropdownMenuItem<int>(
                    value: casier['cassier_id'],
                    child: Text(casier['nom']),
                  );
                }).toList(),
                onChanged: (value) {
                  tempSelectedId = value;
                  (context as Element).markNeedsBuild();
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: tempSelectedId == null
                      ? null
                      : () => Navigator.pop(context, tempSelectedId),
                  child: Text('Restaurer'),
                ),
              ],
            );
          },
        );
        if (selectedCasierId == null) return;
      } else if (backup.type == 'fichier') {
        final armoireService = ArmoireService();
        final casiers = await armoireService.getAllCasiers(entrepriseId);
        int? tempSelectedCasierId;
        int? tempSelectedDossierId;
        tempSelectedCasierId = await showDialog<int>(
          context: context,
          builder: (context) {
            int? tempId;
            return AlertDialog(
              title: Text('Choisir un casier'),
              content: DropdownButton<int>(
                isExpanded: true,
                value: tempId,
                hint: Text('Sélectionner un casier'),
                items: casiers.map<DropdownMenuItem<int>>((casier) {
                  return DropdownMenuItem<int>(
                    value: casier['cassier_id'],
                    child: Text(casier['nom']),
                  );
                }).toList(),
                onChanged: (value) {
                  tempId = value;
                  (context as Element).markNeedsBuild();
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: tempId == null
                      ? null
                      : () => Navigator.pop(context, tempId),
                  child: Text('Suivant'),
                ),
              ],
            );
          },
        );
        if (tempSelectedCasierId == null) return;
        final dossiers = await _loadDossiersOfCasier(tempSelectedCasierId, token);
        tempSelectedDossierId = await showDialog<int>(
          context: context,
          builder: (context) {
            int? tempId;
            return AlertDialog(
              title: Text('Choisir un dossier de destination'),
              content: DropdownButton<int>(
                isExpanded: true,
                value: tempId,
                hint: Text('Sélectionner un dossier'),
                items: dossiers.map<DropdownMenuItem<int>>((dossier) {
                  return DropdownMenuItem<int>(
                    value: dossier['dossier_id'],
                    child: Text(dossier['nom']),
                  );
                }).toList(),
                onChanged: (value) {
                  tempId = value;
                  (context as Element).markNeedsBuild();
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: tempId == null
                      ? null
                      : () => Navigator.pop(context, tempId),
                  child: Text('Restaurer'),
                ),
              ],
            );
          },
        );
        if (tempSelectedDossierId == null) return;
        selectedDossierId = tempSelectedDossierId;
      }

      setState(() => _isLoading = true);

      final result = await RestoreService.restoreBackup(
        token: token,
        backupId: backup.id,
        armoireId: selectedArmoireId,
        cassierId: selectedCasierId,
        dossierId: selectedDossierId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sauvegarde restaurée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
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
        title: const Text('🔒 Sauvegardes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createBackup,
            tooltip: 'Créer une sauvegarde',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _backups.isEmpty
                  ? _buildEmptyWidget()
                  : _buildBackupsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBackup,
        child: const Icon(Icons.add),
        tooltip: 'Créer une sauvegarde',
      ),
    );
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
            onPressed: _loadBackups,
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
          const Icon(Icons.backup, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune sauvegarde',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre première sauvegarde',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createBackup,
            icon: const Icon(Icons.add),
            label: const Text('Créer une sauvegarde'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsList() {
    return RefreshIndicator(
      onRefresh: _loadBackups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _backups.length,
        itemBuilder: (context, index) {
          final backup = _backups[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: _getBackupIcon(backup.type),
              title: Text('${backup.typeDisplay} - ${backup.id}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(backup.formattedDate),
                  Text('Taille: ${backup.formattedSize}'),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'restore':
                      _restoreBackup(backup);
                      break;
                    case 'download':
                      _downloadBackup(backup);
                      break;
                    case 'delete':
                      _deleteBackup(backup);
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

  Widget _getBackupIcon(String type) {
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
      case 'système':
        iconData = Icons.computer;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.backup;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor, size: 32);
  }
}

class _CreateBackupDialog extends StatefulWidget {
  @override
  State<_CreateBackupDialog> createState() => _CreateBackupDialogState();
}

class _CreateBackupDialogState extends State<_CreateBackupDialog> {
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
            _armoires = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
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
      title: const Text('Créer une sauvegarde'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de sauvegarde',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'fichier', child: Text('Fichier')),
                DropdownMenuItem(value: 'dossier', child: Text('Dossier')),
                DropdownMenuItem(value: 'casier', child: Text('Casier')),
                DropdownMenuItem(value: 'armoire', child: Text('Armoire')),
                DropdownMenuItem(value: 'système', child: Text('Système')),
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
            
            if (_selectedType != 'système') ...[
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
          onPressed: _selectedType == 'système' || _selectedCibleId != null
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