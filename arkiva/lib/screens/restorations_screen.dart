import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/restore_service.dart';
import 'package:arkiva/services/backup_service.dart';
import 'package:arkiva/services/version_service.dart';
import 'package:arkiva/models/restore.dart';
import 'package:arkiva/models/restore_details.dart';
import 'package:arkiva/models/backup.dart';
import 'package:arkiva/models/version.dart';
import 'package:arkiva/widgets/restore_card.dart';
import 'package:arkiva/widgets/restore_confirmation_dialog.dart';
import 'package:arkiva/widgets/restore_details_dialog.dart';
import 'package:arkiva/widgets/select_target_dialog.dart';

class RestorationsScreen extends StatefulWidget {
  const RestorationsScreen({super.key});

  @override
  State<RestorationsScreen> createState() => _RestorationsScreenState();
}

class _RestorationsScreenState extends State<RestorationsScreen> {
  List<Restore> _restores = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'Tous';

  final List<String> _filterOptions = [
    'Tous',
    'Fichier',
    'Dossier',
    'Casier',
    'Armoire',
    'Sauvegarde',
    'Version',
  ];

  @override
  void initState() {
    super.initState();
    _loadRestores();
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

  Widget _buildRestoreCard(Restore restore) {
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
                  color: _getRestoreColor(restore.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getRestoreIcon(restore.type),
                  color: _getRestoreColor(restore.type),
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
                            color: restore.isFromBackup ? Colors.green[100] : Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: restore.isFromBackup ? Colors.green[300]! : Colors.orange[300]!,
                            ),
                          ),
                          child: Text(
                            restore.isFromBackup ? 'Sauvegarde' : 'Version',
                            style: TextStyle(
                              color: restore.isFromBackup ? Colors.green[700] : Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          restore.formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${restore.typeDisplay} - ${restore.sourceId}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                                         Container(
                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                         color: _getRestoreColor(restore.type).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: _getRestoreColor(restore.type).withOpacity(0.3)),
                       ),
                       child: Text(
                         restore.sourceType,
                         style: TextStyle(
                           color: _getRestoreColor(restore.type),
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
                    case 'details':
                      _showRestoreDetails(restore);
                      break;
                    case 'delete':
                      _deleteRestore(restore);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text('Détails'),
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
                  onPressed: () => _showRestoreDetails(restore),
                  icon: Icon(Icons.info, size: 16),
                  label: Text('Détails'),
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
                  onPressed: () => _deleteRestore(restore),
                  icon: Icon(Icons.delete, size: 16),
                  label: Text('Supprimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
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

  Color _getRestoreColor(String type) {
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

  IconData _getRestoreIcon(String type) {
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
        return Icons.restore;
    }
  }

  Future<void> _loadRestores() async {
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

      final restoresData = await RestoreService.getAllRestores(token: token);
      final restores = restoresData.map((json) => Restore.fromJson(json)).toList();

      setState(() {
        _restores = restores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Restore> get _filteredRestores {
    if (_selectedFilter == 'Tous') {
      return _restores;
    }

    return _restores.where((restore) {
      switch (_selectedFilter) {
        case 'Fichier':
          return restore.type == 'fichier';
        case 'Dossier':
          return restore.type == 'dossier';
        case 'Casier':
          return restore.type == 'casier';
        case 'Armoire':
          return restore.type == 'armoire';
        case 'Sauvegarde':
          return restore.isFromBackup;
        case 'Version':
          return restore.isFromVersion;
        default:
          return true;
      }
    }).toList();
  }

  Map<String, dynamic> get _statistics {
    final total = _restores.length;
    final fromBackup = _restores.where((r) => r.isFromBackup).length;
    final fromVersion = _restores.where((r) => r.isFromVersion).length;
    final byType = <String, int>{};
    
    for (final restore in _restores) {
      byType[restore.type] = (byType[restore.type] ?? 0) + 1;
    }

    return {
      'total': total,
      'fromBackup': fromBackup,
      'fromVersion': fromVersion,
      'byType': byType,
    };
  }

  Future<void> _showRestoreBackupDialog() async {
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      if (token == null) throw Exception('Token d\'authentification manquant');
      final backupsData = await BackupService.getAllBackups(token: token);
      final backups = backupsData.map((json) => Backup.fromJson(json)).toList();
      final selected = await showDialog<Backup>(
        context: context,
        builder: (context) => SelectBackupDialog(backups: backups),
      );
      if (selected != null) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => RestoreConfirmationDialog(
            type: selected.type,
            name: selected.id.toString(),
            sourceType: 'Sauvegarde',
            sourceId: selected.id.toString(),
            originalDate: selected.formattedDate,
          ),
        );
        if (confirm == true) {
          await RestoreService.restoreBackup(token: token, backupId: selected.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restauration lancée avec succès')),
            );
            _loadRestores();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _showRestoreVersionDialog() async {
    try {
      // 1. Demander le type
      final type = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Row(
            children: [
              Icon(Icons.history, color: Colors.orange[600]),
              SizedBox(width: 8),
              Text('Choisir le type'),
            ],
          ),
          children: [
            SimpleDialogOption(
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.blue[600]),
                  SizedBox(width: 8),
                  Text('Fichier'),
                ],
              ),
              onPressed: () => Navigator.pop(context, 'fichier'),
            ),
            SimpleDialogOption(
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.orange[600]),
                  SizedBox(width: 8),
                  Text('Dossier'),
                ],
              ),
              onPressed: () => Navigator.pop(context, 'dossier'),
            ),
            SimpleDialogOption(
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.green[600]),
                  SizedBox(width: 8),
                  Text('Casier'),
                ],
              ),
              onPressed: () => Navigator.pop(context, 'casier'),
            ),
            SimpleDialogOption(
              child: Row(
                children: [
                  Icon(Icons.warehouse, color: Colors.purple[600]),
                  SizedBox(width: 8),
                  Text('Armoire'),
                ],
              ),
              onPressed: () => Navigator.pop(context, 'armoire'),
            ),
          ],
        ),
      );
      if (type == null) return;
      // 2. Sélectionner la cible
      final cible = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SelectTargetDialog(selectedType: type),
      );
      if (cible == null || !cible.containsKey('cibleId')) return;
      final cibleId = cible['cibleId'] as int;
      // 3. Charger les versions pour ce type/cible
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      if (token == null) throw Exception('Token d\'authentification manquant');
      final versionsData = await VersionService.getVersionHistory(token: token, cibleId: cibleId, type: type);
      final versions = versionsData.map((json) => Version.fromJson(json)).toList();
      if (versions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune version trouvée pour cette cible.')),
          );
        }
        return;
      }
      // 4. Sélectionner la version à restaurer
      final selected = await showDialog<Version>(
        context: context,
        builder: (context) => SelectVersionDialog(versions: versions),
      );
      if (selected != null) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => RestoreConfirmationDialog(
            type: selected.type,
            name: selected.versionNumber,
            sourceType: 'Version',
            sourceId: selected.id,
            originalDate: selected.formattedDate,
          ),
        );
        if (confirm == true) {
          await RestoreService.restoreVersion(token: token, versionId: selected.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restauration de version lancée avec succès')),
            );
            _loadRestores();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _showRestoreDetails(Restore restore) async {
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final detailsData = await RestoreService.getRestoreDetails(
        token: token,
        restoreId: restore.id,
      );

      final details = RestoreDetails.fromJson(detailsData);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => RestoreDetailsDialog(details: details),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des détails: $e')),
        );
      }
    }
  }

  Future<void> _deleteRestore(Restore restore) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Supprimer la restauration'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer cette restauration ? Cette action est irréversible.'),
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

        await RestoreService.deleteRestore(
          token: token,
          restoreId: restore.id,
        );

        await _loadRestores();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restauration supprimée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }

  Widget _buildStatisticsCard() {
    final stats = _statistics;
    
    return _buildModernCard(
      color: Colors.cyan[50],
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.cyan[600]),
              SizedBox(width: 8),
              Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  stats['total']?.toString() ?? '0',
                  Icons.restore,
                  Colors.cyan[600]!,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Sauvegardes',
                  stats['fromBackup']?.toString() ?? '0',
                  Icons.backup,
                  Colors.green[600]!,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Versions',
                  stats['fromVersion']?.toString() ?? '0',
                  Icons.history,
                  Colors.orange[600]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                selectedColor: Colors.cyan[100],
                checkmarkColor: Colors.cyan[700],
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.grey[100],
                side: BorderSide(color: Colors.grey[300]!),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.cyan[700] : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRestoreList() {
    if (_filteredRestores.isEmpty) {
      return Center(
        child: _buildModernCard(
          color: Colors.grey[50],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restore_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'Aucune restauration trouvée',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Les restaurations apparaîtront ici',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: _filteredRestores.length,
      itemBuilder: (context, index) {
        final restore = _filteredRestores[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _buildRestoreCard(restore),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: _buildModernCard(
        color: Colors.red[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
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
              _error ?? 'Une erreur inconnue s\'est produite',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRestores,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyan[900]!, Colors.cyan[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.restore, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Restaurations',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRestores,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: _buildModernCard(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des restaurations...'),
                  ],
                ),
              ),
            )
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildStatisticsCard(),
                    _buildFilterChips(),
                    SizedBox(height: 8),
                    Expanded(
                      child: _buildRestoreList(),
                    ),
                  ],
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showRestoreBackupDialog,
            icon: Icon(Icons.backup, color: Colors.white),
            label: Text('Restaurer sauvegarde', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green[600],
            heroTag: 'restore_backup',
          ),
          SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: _showRestoreVersionDialog,
            icon: Icon(Icons.history, color: Colors.white),
            label: Text('Restaurer version', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange[600],
            heroTag: 'restore_version',
          ),
        ],
      ),
    );
  }
}

class SelectBackupDialog extends StatefulWidget {
  final List<Backup> backups;
  const SelectBackupDialog({super.key, required this.backups});

  @override
  State<SelectBackupDialog> createState() => _SelectBackupDialogState();
}

class _SelectBackupDialogState extends State<SelectBackupDialog> {
  String _search = '';
  Backup? _selected;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.backups.where((b) {
      final s = _search.toLowerCase();
      return b.typeDisplay.toLowerCase().contains(s) ||
             b.id.toString().contains(s) ||
             b.formattedDate.toLowerCase().contains(s);
    }).toList();
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.backup, color: Colors.green[600]),
          SizedBox(width: 8),
          Text('Sélectionner une sauvegarde'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Recherche rapide',
                prefixIcon: Icon(Icons.search, color: Colors.green[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Text('Aucune sauvegarde trouvée')
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final b = filtered[i];
                        return ListTile(
                          title: Text('${b.typeDisplay} - ${b.id}'),
                          subtitle: Text(b.formattedDate),
                          selected: _selected == b,
                          onTap: () => setState(() => _selected = b),
                          trailing: _selected == b ? Icon(Icons.check, color: Colors.green[600]) : null,
                        );
                      },
                    ),
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
          onPressed: _selected != null ? () => Navigator.pop(context, _selected) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
          child: Text('Sélectionner'),
        ),
      ],
    );
  }
}

class SelectVersionDialog extends StatefulWidget {
  final List<Version> versions;
  const SelectVersionDialog({super.key, required this.versions});

  @override
  State<SelectVersionDialog> createState() => _SelectVersionDialogState();
}

class _SelectVersionDialogState extends State<SelectVersionDialog> {
  String _search = '';
  Version? _selected;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.versions.where((v) {
      final s = _search.toLowerCase();
      return v.typeDisplay.toLowerCase().contains(s) ||
             v.id.toLowerCase().contains(s) ||
             v.versionNumber.toLowerCase().contains(s) ||
             (v.description?.toLowerCase() ?? '').contains(s) ||
             v.formattedDate.toLowerCase().contains(s);
    }).toList();
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.history, color: Colors.orange[600]),
          SizedBox(width: 8),
          Text('Sélectionner une version'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Recherche rapide',
                prefixIcon: Icon(Icons.search, color: Colors.orange[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Text('Aucune version trouvée')
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final v = filtered[i];
                        return ListTile(
                          title: Text('${v.typeDisplay} v${v.versionNumber}'),
                          subtitle: Text(v.formattedDate + (v.description != null ? '\n${v.description}' : '')),
                          selected: _selected == v,
                          onTap: () => setState(() => _selected = v),
                          trailing: _selected == v ? Icon(Icons.check, color: Colors.orange[600]) : null,
                        );
                      },
                    ),
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
          onPressed: _selected != null ? () => Navigator.pop(context, _selected) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
          ),
          child: Text('Sélectionner'),
        ),
      ],
    );
  }
} 