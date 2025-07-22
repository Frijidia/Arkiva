import 'package:flutter/material.dart';
import 'package:arkiva/models/restore.dart';

class RestoreCard extends StatelessWidget {
  final Restore restore;
  final VoidCallback? onViewDetails;
  final VoidCallback? onDelete;

  const RestoreCard({
    super.key,
    required this.restore,
    this.onViewDetails,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restore.restoredElementName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${restore.typeDisplay} restauré depuis ${restore.sourceType}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'details':
                        onViewDetails?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16),
                          SizedBox(width: 8),
                          Text('Voir détails'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Source',
                    restore.sourceId,
                    Icons.source,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Date',
                    restore.formattedDate,
                    Icons.schedule,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Original',
                    restore.originalDateFormatted,
                    Icons.history,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (restore.type) {
      case 'fichier':
        icon = Icons.insert_drive_file;
        color = Colors.blue;
        break;
      case 'dossier':
        icon = Icons.folder;
        color = Colors.amber;
        break;
      case 'casier':
        icon = Icons.inbox;
        color = Colors.green;
        break;
      case 'armoire':
        icon = Icons.warehouse;
        color = Colors.purple;
        break;
      default:
        icon = Icons.restore;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
} 