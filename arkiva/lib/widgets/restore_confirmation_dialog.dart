import 'package:flutter/material.dart';

class RestoreConfirmationDialog extends StatelessWidget {
  final String type;
  final String name;
  final String sourceType;
  final String sourceId;
  final String? originalDate;

  const RestoreConfirmationDialog({
    super.key,
    required this.type,
    required this.name,
    required this.sourceType,
    required this.sourceId,
    this.originalDate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('⚠️ Confirmer la restauration'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Type', _getTypeDisplay(type)),
          _buildInfoRow('Nom', name),
          _buildInfoRow('Source', '$sourceType #$sourceId'),
          if (originalDate != null)
            _buildInfoRow('Date originale', originalDate!),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ Attention: Cette action va créer un nouvel élément et ne remplacera pas l\'existant.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
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
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
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

  String _getTypeDisplay(String type) {
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
} 