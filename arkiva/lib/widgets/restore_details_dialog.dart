import 'package:flutter/material.dart';
import 'package:arkiva/models/restore_details.dart';

class RestoreDetailsDialog extends StatelessWidget {
  final RestoreDetails details;

  const RestoreDetailsDialog({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralInfo(),
                    const SizedBox(height: 16),
                    _buildSourceInfo(),
                    const SizedBox(height: 16),
                    _buildRestoredInfo(),
                    const SizedBox(height: 16),
                    _buildMetadataInfo(),
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.restore,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '📋 Détails de la restauration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfo() {
    return _buildSection(
      title: '🔄 Informations générales',
      icon: Icons.info_outline,
      color: Colors.blue,
      children: [
        _buildInfoRow('ID', details.restore.id),
        _buildInfoRow('Type', details.restore.typeDisplay),
        _buildInfoRow('Date de restauration', details.restore.formattedDate),
        _buildInfoRow('Utilisateur', 'ID: ${details.userId}'),
      ],
    );
  }

  Widget _buildSourceInfo() {
    return _buildSection(
      title: '📦 Source (${details.sourceType})',
      icon: details.restore.isFromBackup ? Icons.backup : Icons.history,
      color: details.restore.isFromBackup ? Colors.green : Colors.orange,
      children: [
        _buildInfoRow('ID', details.restore.sourceId),
        _buildInfoRow('Nom', details.sourceName),
        _buildInfoRow('Taille', details.sourceSize),
        _buildInfoRow('Date originale', details.sourceDateFormatted),
      ],
    );
  }

  Widget _buildRestoredInfo() {
    return _buildSection(
      title: '✅ Élément restauré',
      icon: Icons.check_circle_outline,
      color: Colors.green,
      children: [
        _buildInfoRow('ID', details.restoredElementId),
        _buildInfoRow('Nom', details.restoredElementName),
        _buildInfoRow('Type', details.restore.typeDisplay),
        _buildInfoRow('Date de création', details.restorationDateFormatted),
      ],
    );
  }

  Widget _buildMetadataInfo() {
    return _buildSection(
      title: '📊 Métadonnées',
      icon: Icons.data_usage,
      color: Colors.purple,
      children: [
        _buildInfoRow('Type de source', details.restore.sourceType),
        _buildInfoRow('ID de cible', details.restore.cibleId.toString()),
        if (details.restore.entrepriseId != null)
          _buildInfoRow('Entreprise', details.restore.entrepriseId.toString()),
        _buildInfoRow('Déclenché par', details.restore.declencheParId.toString()),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '• $label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implémenter la navigation vers l'élément restauré
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigation vers l\'élément à implémenter')),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Voir l\'élément'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }
} 