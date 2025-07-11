import 'package:flutter/material.dart';
import 'package:arkiva/models/document.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/services/file_service.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:arkiva/screens/extract_pages_screen.dart';
import 'package:open_filex/open_filex.dart';

// Import conditionnel pour le web
// import 'dart:html' as html;

class MergeFilesScreen extends StatefulWidget {
  final Dossier dossier;

  const MergeFilesScreen({
    super.key,
    required this.dossier,
  });

  @override
  State<MergeFilesScreen> createState() => _MergeFilesScreenState();
}

class _MergeFilesScreenState extends State<MergeFilesScreen> {
  final FileService _fileService = FileService();
  final DocumentService _documentService = DocumentService();
  
  List<Document> _selectedDocuments = [];
  List<Document> _availableDocuments = [];
  bool _isLoading = false;
  bool _isLoadingDocuments = true;
  final TextEditingController _fileNameController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _fileNameController.text = 'Document_fusionne_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocuments = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      
      if (token != null && widget.dossier.dossierId != null) {
        final documents = await _documentService.getDocuments(token, widget.dossier.dossierId);
        setState(() {
          _availableDocuments = documents.where((doc) {
            final type = doc.type.toLowerCase();
            final nom = (doc.nomOriginal ?? doc.nom).toLowerCase();
            return type.contains('pdf') || type.contains('jpg') || type.contains('jpeg') || type.contains('png')
                || nom.endsWith('.pdf') || nom.endsWith('.jpg') || nom.endsWith('.jpeg') || nom.endsWith('.png');
          }).toList();
          _isLoadingDocuments = false;
        });
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des documents: ${e.toString()}')),
      );
      setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _mergeFiles() async {
    if (_selectedDocuments.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un document à fusionner'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_fileNameController.text.trim().isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un nom de fichier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token == null || entrepriseId == null) {
        throw Exception('Token ou ID entreprise manquant');
      }

      final filePaths = _selectedDocuments.map((doc) => doc.chemin).toList();
      
      final mergedPdfBytes = await _fileService.mergeFiles(
        token: token,
        fichiers: filePaths,
        entrepriseId: entrepriseId,
        dossierId: widget.dossier.dossierId!,
        fileName: _fileNameController.text.trim(),
      );

      // Sauvegarder le fichier fusionné
      await _saveMergedFile(mergedPdfBytes);

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Fichiers fusionnés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // Fermer l'écran de fusion et signaler le succès
        Navigator.pop(context, true);
        return;
      }

    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la fusion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMergedFile(Uint8List pdfBytes) async {
    if (kIsWeb) {
      // Pour le web, afficher un message d'information
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Fonctionnalité de téléchargement non disponible sur le web'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Pour mobile, sauvegarder dans le dossier temporaire
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${_fileNameController.text.trim()}.pdf');
      await file.writeAsBytes(pdfBytes);
      await OpenFilex.open(file.path);
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Fichier sauvegardé: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _toggleDocumentSelection(Document document) {
    setState(() {
      if (_selectedDocuments.contains(document)) {
        _selectedDocuments.remove(document);
      } else {
        _selectedDocuments.add(document);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fusion de fichiers'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.content_cut),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => ExtractPagesScreen(dossier: widget.dossier),
                ),
              ),
              tooltip: 'Extraire des pages',
            ),
            if (_selectedDocuments.isNotEmpty)
              TextButton.icon(
                onPressed: _isLoading ? null : _mergeFiles,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.merge, color: Colors.white),
                label: Text(
                  _isLoading ? 'Fusion...' : 'Fusionner (${_selectedDocuments.length})',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Section de configuration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration de la fusion',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _fileNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du fichier fusionné',
                      hintText: 'Entrez le nom du fichier',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Documents sélectionnés: ${_selectedDocuments.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Liste des documents
            Expanded(
              child: _isLoadingDocuments
                ? const Center(child: CircularProgressIndicator())
                : _availableDocuments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun document PDF ou image disponible',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _availableDocuments.length,
                      itemBuilder: (context, index) {
                        final document = _availableDocuments[index];
                        final isSelected = _selectedDocuments.contains(document);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: isSelected ? Colors.blue[50] : null,
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getFileIcon(document.type),
                                color: isSelected ? Colors.white : Colors.grey[600],
                              ),
                            ),
                            title: Text(
                              document.nomOriginal ?? document.nom,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${document.type.toUpperCase()} • ${_formatFileSize(document.taille)}',
                              style: TextStyle(
                                color: isSelected ? Colors.blue[700] : Colors.grey[600],
                              ),
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleDocumentSelection(document),
                              activeColor: Colors.blue,
                            ),
                            onTap: () => _toggleDocumentSelection(document),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int? size) {
    if (size == null) return 'Taille inconnue';
    
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
} 