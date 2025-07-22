import 'package:flutter/material.dart';
import 'package:arkiva/models/document.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_filex/open_filex.dart';

class DocumentViewerScreen extends StatefulWidget {
  final Document document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  File? _localFile;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAndShowFile();
    }
  }

  Future<void> _loadAndShowFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;
      if (token == null || entrepriseId == null) {
        throw Exception('Token ou ID entreprise manquant');
      }
      final url = '${ApiConfig.baseUrl}/fichier/${widget.document.id}/$entrepriseId';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final fileName = widget.document.nomOriginal ?? widget.document.nom;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localFile = file;
        });
      } else {
        throw Exception('Erreur lors du téléchargement du fichier');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
    
    if (kIsWeb) {
      // Pour le web, on utilise url_launcher
      final url = '${ApiConfig.baseUrl}/api/fichier/${widget.document.id}/$entrepriseId?token=$token';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Pour mobile, on télécharge et ouvre avec open_filex
      try {
        final url = '${ApiConfig.baseUrl}/api/fichier/${widget.document.id}/$entrepriseId?token=$token';
        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (response.statusCode == 200) {
          final fileName = widget.document.nomOriginal ?? widget.document.nom;
          
          // Sauvegarder temporairement et ouvrir
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          
          // Ouvrir avec open_filex
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur lors de l\'ouverture: ${result.message}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors du téléchargement: ${response.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    
    if (kIsWeb) {
      // Pour le web, on utilise url_launcher pour télécharger
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de télécharger le document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Pour mobile, on télécharge dans le dossier de téléchargements
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (response.statusCode == 200) {
          final fileName = widget.document.nomOriginal ?? widget.document.nom;
          
          // Sauvegarder dans le dossier de téléchargements
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            final file = File('${downloadsDir.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Document téléchargé: ${file.path}')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Impossible d\'accéder au dossier de téléchargements'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}')),
          );
        }
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
    
    if (kIsWeb) {
      // Pour le web, on utilise url_launcher
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Pour mobile, on télécharge et ouvre avec open_filex
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (response.statusCode == 200) {
          final fileName = widget.document.nomOriginal ?? widget.document.nom;
          
          // Sauvegarder temporairement et ouvrir
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          
          // Ouvrir avec open_filex
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur lors de l\'ouverture: ${result.message}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors du téléchargement: ${response.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Construction de l'URL pour afficher le fichier déchiffré via la route backend
  // /api/fichier/:fichier_id/:entreprise_id
  String get _fileUrl {
    final authStateService = context.read<AuthStateService>();
    final entrepriseId = authStateService.entrepriseId;
    return '${ApiConfig.baseUrl}/fichier/${widget.document.id}/$entrepriseId';
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt': return 'text/plain';
      case 'zip': return 'application/zip';
      case 'rar': return 'application/x-rar-compressed';
      default: return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
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
    } else {
      // Aperçu natif sur mobile
      if (_isLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (_error != null) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.document.nom)),
          body: Center(child: Text('Erreur: $_error', style: TextStyle(color: Colors.red))),
        );
      }
      if (_localFile == null) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.document.nom)),
          body: const Center(child: Text('Aucun fichier à afficher.')),
        );
      }
      final ext = (widget.document.nomOriginal ?? widget.document.nom).split('.').last.toLowerCase();
      if (['pdf'].contains(ext)) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.document.nom)),
          body: SfPdfViewer.file(_localFile!),
        );
      } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.document.nom)),
          body: Center(child: Image.file(_localFile!)),
        );
      } else {
        return Scaffold(
          appBar: AppBar(title: Text(widget.document.nom)),
          body: Center(child: Text('Aperçu non supporté pour ce type de fichier.')),
        );
      }
    }
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