import 'package:flutter/material.dart';
import 'package:arkiva/models/document.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/services/file_service.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';

// Import conditionnel pour le web
// import 'dart:html' as html;

class ExtractPagesScreen extends StatefulWidget {
  final Dossier dossier;

  const ExtractPagesScreen({
    super.key,
    required this.dossier,
  });

  @override
  State<ExtractPagesScreen> createState() => _ExtractPagesScreenState();
}

class _ExtractPagesScreenState extends State<ExtractPagesScreen> {
  final FileService _fileService = FileService();
  final DocumentService _documentService = DocumentService();
  
  List<Document> _availableDocuments = [];
  Map<String, List<int>> _selectedPages = {};
  Map<String, int> _documentPageCounts = {}; // Stocke le nombre de pages par document
  bool _isLoading = false;
  bool _isLoadingDocuments = true;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  // Clé unique pour forcer le rebuild
  Key _rebuildKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocuments = true);
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;
      
      if (token != null && widget.dossier.dossierId != null) {
        final documents = await _documentService.getDocuments(token, widget.dossier.dossierId);
        final pdfDocuments = documents.where((doc) {
          final type = doc.type.toLowerCase();
          final nom = (doc.nomOriginal ?? doc.nom).toLowerCase();
          return type.contains('pdf') || nom.endsWith('.pdf');
        }).toList();
        
        setState(() {
          _availableDocuments = pdfDocuments;
          _isLoadingDocuments = false;
        });
        
        // Récupérer le nombre de pages pour chaque PDF
        await _loadPageCounts(token!, entrepriseId!);
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des documents: ${e.toString()}')),
      );
      setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _loadPageCounts(String token, int entrepriseId) async {
    for (final document in _availableDocuments) {
      try {
        final pageCount = await _fileService.getPdfPageCount(
          token: token,
          chemin: document.chemin,
          entrepriseId: entrepriseId,
        );
        setState(() {
          _documentPageCounts[document.chemin] = pageCount;
        });
      } catch (e) {
        print('Erreur récupération pages pour ${document.nom}: $e');
        // En cas d'erreur, utiliser 10 pages par défaut
        setState(() {
          _documentPageCounts[document.chemin] = 10;
        });
      }
    }
  }

  Future<void> _extractPages() async {
    final selectedFiles = _selectedPages.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => {
          'chemin': entry.key,
          'pages': entry.value,
        })
        .toList();

    if (selectedFiles.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une page à extraire'),
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

      final extractedPdfBytes = await _fileService.extractSelectedPages(
        token: token,
        fichiers: selectedFiles,
        entrepriseId: entrepriseId,
      );

      // Sauvegarder le fichier extrait
      await _saveExtractedFile(extractedPdfBytes);

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Pages extraites avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'extraction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveExtractedFile(Uint8List pdfBytes) async {
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
      final file = File('${tempDir.path}/pages_extractes_${DateTime.now().millisecondsSinceEpoch}.pdf');
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

  void _togglePageSelection(String documentPath, int pageNumber) {
    setState(() {
      if (!_selectedPages.containsKey(documentPath)) {
        _selectedPages[documentPath] = [];
      }
      
      final pages = _selectedPages[documentPath]!;
      if (pages.contains(pageNumber)) {
        pages.remove(pageNumber);
        if (pages.isEmpty) {
          _selectedPages.remove(documentPath);
        }
      } else {
        pages.add(pageNumber);
        pages.sort();
      }
    });
  }

  void _selectAllPages(String documentPath, int totalPages) {
    setState(() {
      _selectedPages[documentPath] = List.generate(totalPages, (index) => index + 1);
    });
  }

  void _clearSelection(String documentPath) {
    print('DEBUG: Effacement de la sélection pour $documentPath');
    print('DEBUG: Sélection avant: $_selectedPages');
    
    setState(() {
      // Créer une nouvelle map pour forcer le rebuild
      final newMap = Map<String, List<int>>.from(_selectedPages);
      newMap.remove(documentPath);
      _selectedPages = newMap;
      // Forcer un rebuild complet
      _rebuildKey = UniqueKey();
    });
    
    print('DEBUG: Sélection après: $_selectedPages');
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Extraction de pages'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          actions: [
            if (_selectedPages.isNotEmpty)
              TextButton.icon(
                onPressed: _isLoading ? null : _extractPages,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.content_cut, color: Colors.white),
                label: Text(
                  _isLoading ? 'Extraction...' : 'Extraire',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: _isLoadingDocuments
          ? const Center(child: CircularProgressIndicator())
          : _availableDocuments.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun document PDF disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                key: _rebuildKey,
                padding: const EdgeInsets.all(16),
                itemCount: _availableDocuments.length,
                itemBuilder: (context, index) {
                  final document = _availableDocuments[index];
                  final selectedPages = List<int>.from(_selectedPages[document.chemin] ?? []);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: Text(
                        document.nomOriginal ?? document.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${document.type.toUpperCase()} • ${_formatFileSize(document.taille)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedPages.isNotEmpty)
                            Text(
                              '${selectedPages.length} page(s)',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const Icon(Icons.expand_more),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sélectionner des pages (${_documentPageCounts[document.chemin] ?? 10} pages)',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () => _selectAllPages(document.chemin, _documentPageCounts[document.chemin] ?? 10),
                                        child: const Text('Tout sélectionner'),
                                      ),
                                      TextButton(
                                        onPressed: () => _clearSelection(document.chemin),
                                        child: const Text('Effacer'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  _documentPageCounts[document.chemin] ?? 10,
                                  (index) {
                                  final pageNumber = index + 1;
                                  final isSelected = selectedPages.contains(pageNumber);
                                  
                                  return InkWell(
                                    onTap: () => _togglePageSelection(document.chemin, pageNumber),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.blue : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$pageNumber',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatFileSize(int? size) {
    if (size == null) return 'Taille inconnue';
    
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
} 