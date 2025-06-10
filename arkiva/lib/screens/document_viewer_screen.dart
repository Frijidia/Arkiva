import 'package:flutter/material.dart';
import 'package:arkiva/models/document.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewerScreen extends StatefulWidget {
  final Document document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  Future<void> _ouvrirDocument() async {
    // TODO: Remplacer par l'URL réelle du document
    final Uri url = Uri.parse('https://example.com/documents/${widget.document.id}');
    
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _telechargerDocument() async {
    // TODO: Implémenter le téléchargement
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléchargement en cours...'),
        ),
      );
    }
  }

  Future<void> _partagerDocument() async {
    // TODO: Implémenter le partage
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partage en cours...'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _telechargerDocument,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _partagerDocument,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              widget.document.nom,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${widget.document.type}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Taille: ${_formatTaille(widget.document.taille)}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajouté le ${widget.document.dateAjout.toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            if (widget.document.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.document.description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _ouvrirDocument,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ouvrir le document'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTaille(int? octets) {
    if (octets == null) {
      return 'N/A';
    }
    if (octets < 1024) {
      return '$octets octets';
    } else if (octets < 1024 * 1024) {
      return '${(octets / 1024).toStringAsFixed(1)} Ko';
    } else if (octets < 1024 * 1024 * 1024) {
      return '${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo';
    } else {
      return '${(octets / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
    }
  }
} 