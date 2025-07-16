import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final File imageFile;
  final void Function(File filteredFile) onValidate;

  const DocumentPreviewScreen({
    Key? key,
    required this.imageFile,
    required this.onValidate,
  }) : super(key: key);

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  late File _currentFile;
  String _selectedFilter = 'original';
  bool _isProcessing = false;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      // Vérifier si le fichier existe
      if (!await widget.imageFile.exists()) {
        debugPrint('Fichier image introuvable: ${widget.imageFile.path}');
        setState(() {
          _isImageLoaded = false;
        });
        return;
      }

      // Vérifier la taille du fichier
      final fileSize = await widget.imageFile.length();
      if (fileSize == 0) {
        debugPrint('Fichier image vide: ${widget.imageFile.path}');
        setState(() {
          _isImageLoaded = false;
        });
        return;
      }

      // Essayer de lire les premiers bytes pour vérifier le format
      final bytes = await widget.imageFile.openRead().first;
      if (bytes.isEmpty) {
        debugPrint('Impossible de lire le fichier image: ${widget.imageFile.path}');
        setState(() {
          _isImageLoaded = false;
        });
        return;
      }

      setState(() {
        _isImageLoaded = true;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'image: $e');
      setState(() {
        _isImageLoaded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu du document'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : () => widget.onValidate(_currentFile),
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: GestureDetector(
        // Désactiver la sélection de texte sur l'image
        onTap: () {
          // Empêcher la propagation des événements tactiles
          HapticFeedback.lightImpact();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!_isImageLoaded)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  Center(
                    child: InteractiveViewer(
                      // Permettre le zoom et le déplacement
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _currentFile,
                            width: MediaQuery.of(context).size.width * 0.9,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Erreur de chargement d\'image: $error');
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[400]!),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline, 
                                      size: 48, 
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Erreur de chargement de l\'image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Format non supporté ou fichier corrompu',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Recharger l'image
                                        _loadImage();
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Réessayer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (!_isProcessing)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Filtres disponibles',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildFilterButton('original', 'Original', Icons.image),
                            _buildFilterButton('bw', 'Noir & Blanc', Icons.filter_b_and_w),
                            _buildFilterButton('magic', 'Magique', Icons.auto_fix_high),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Application du filtre...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Utilisez les gestes pour zoomer et déplacer l\'image. Choisissez un filtre puis validez.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String key, String label, IconData icon) {
    final isSelected = _selectedFilter == key;
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : () => _applyFilter(key),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 4 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _isProcessing = true;
      _selectedFilter = filter;
    });

    try {
      // Pour l'instant, retourner simplement l'image originale
      // Les filtres seront implémentés plus tard quand le package image sera réintégré
      setState(() {
        _currentFile = widget.imageFile;
        _isProcessing = false;
      });
      
      // Afficher un message informatif
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filtre "$filter" non disponible pour le moment'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      debugPrint('Erreur lors de l\'application du filtre: $e');
      setState(() { 
        _isProcessing = false; 
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'application du filtre: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 