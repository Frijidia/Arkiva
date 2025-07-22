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
          title: const Text('Choisir le type'),
          children: [
            SimpleDialogOption(child: Text('Fichier'), onPressed: () => Navigator.pop(context, 'fichier')),
            SimpleDialogOption(child: Text('Dossier'), onPressed: () => Navigator.pop(context, 'dossier')),
            SimpleDialogOption(child: Text('Casier'), onPressed: () => Navigator.pop(context, 'casier')),
            SimpleDialogOption(child: Text('Armoire'), onPressed: () => Navigator.pop(context, 'armoire')),
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
        title: const Text('Supprimer la restauration'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette restauration ? Cette action est irréversible.'),
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
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Statistiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    stats['total']?.toString() ?? '0',
                    Icons.restore,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sauvegardes',
                    stats['fromBackup']?.toString() ?? '0',
                    Icons.backup,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Versions',
                    stats['fromVersion']?.toString() ?? '0',
                    Icons.history,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRestoreList() {
    if (_filteredRestores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restore_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucune restauration trouvée',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Les restaurations apparaîtront ici',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRestores.length,
      itemBuilder: (context, index) {
        final restore = _filteredRestores[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RestoreCard(
            restore: restore,
            onViewDetails: () => _showRestoreDetails(restore),
            onDelete: () => _deleteRestore(restore),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur lors du chargement',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Une erreur inconnue s\'est produite',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRestores,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔄 Restaurations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRestores,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildStatisticsCard(),
                    _buildFilterChips(),
                    const SizedBox(height: 8),
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
            icon: const Icon(Icons.backup),
            label: const Text('Restaurer sauvegarde'),
            heroTag: 'restore_backup',
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: _showRestoreVersionDialog,
            icon: const Icon(Icons.history),
            label: const Text('Restaurer version'),
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
      title: const Text('Sélectionner une sauvegarde'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Recherche rapide',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Text('Aucune sauvegarde trouvée')
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final b = filtered[i];
                        return ListTile(
                          title: Text('${b.typeDisplay} - ${b.id}'),
                          subtitle: Text(b.formattedDate),
                          selected: _selected == b,
                          onTap: () => setState(() => _selected = b),
                          trailing: _selected == b ? const Icon(Icons.check, color: Colors.blue) : null,
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
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selected != null ? () => Navigator.pop(context, _selected) : null,
          child: const Text('Sélectionner'),
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
      title: const Text('Sélectionner une version'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Recherche rapide',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Text('Aucune version trouvée')
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final v = filtered[i];
                        return ListTile(
                          title: Text('${v.typeDisplay} v${v.versionNumber}'),
                          subtitle: Text(v.formattedDate + (v.description != null ? '\n${v.description}' : '')),
                          selected: _selected == v,
                          onTap: () => setState(() => _selected = v),
                          trailing: _selected == v ? const Icon(Icons.check, color: Colors.blue) : null,
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
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selected != null ? () => Navigator.pop(context, _selected) : null,
          child: const Text('Sélectionner'),
        ),
      ],
    );
  }
} 