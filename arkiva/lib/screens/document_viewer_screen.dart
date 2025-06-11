import 'package:flutter/material.dart';
import 'package:arkiva/models/document.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/config/api_config.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class DocumentViewerScreen extends StatefulWidget {
  final Document document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  Future<void> _ouvrirDocument() async {
    final authStateService = context.read<AuthStateService>();
    final token = authStateService.token;
    final entrepriseId = authStateService.entrepriseId;
    if (token == null || entrepriseId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Token ou ID entreprise manquant'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final url = '${ApiConfig.baseUrl}/fichier/${widget.document.id}/$entrepriseId';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final blob = html.Blob([response.bodyBytes], 'application/pdf');
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(blobUrl, '_blank');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ouverture du document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _telechargerDocument() async {
    final authStateService = context.read<AuthStateService>();
    final token = authStateService.token;
    final entrepriseId = authStateService.entrepriseId;
    if (token == null || entrepriseId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Token ou ID entreprise manquant'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final url = '${ApiConfig.baseUrl}/fichier/${widget.document.id}/$entrepriseId';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final blob = html.Blob([response.bodyBytes], 'application/pdf');
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: blobUrl)
        ..setAttribute('download', widget.document.nom)
        ..click();
      html.Url.revokeObjectUrl(blobUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du téléchargement du document'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _ouvrirPDFWeb() async {
    final authStateService = context.read<AuthStateService>();
    final token = authStateService.token;
    final url = _fileUrl;
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    final blob = html.Blob([response.bodyBytes], 'application/pdf');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(blobUrl, '_blank');
  }

  // Construction de l'URL pour afficher le fichier déchiffré via la route backend
  // /api/fichier/:fichier_id/:entreprise_id
  String get _fileUrl {
    final authStateService = context.read<AuthStateService>();
    final entrepriseId = authStateService.entrepriseId;
    return '${ApiConfig.baseUrl}/fichier/${widget.document.id}/$entrepriseId';
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
              onPressed: _ouvrirPDFWeb,
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