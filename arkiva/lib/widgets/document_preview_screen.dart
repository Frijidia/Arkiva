import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

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
      await widget.imageFile.exists();
      setState(() {
        _isImageLoaded = true;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'image: $e');
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
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'Erreur de chargement de l\'image',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
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
      if (filter == 'original') {
        setState(() {
          _currentFile = widget.imageFile;
          _isProcessing = false;
        });
        return;
      }

      // Lire l'image
      final bytes = await widget.imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        setState(() { 
          _isProcessing = false; 
        });
        return;
      }

      img.Image filtered;
      
      if (filter == 'bw') {
        filtered = img.grayscale(image);
        // Augmente le contraste et applique un seuillage simple
        filtered = img.adjustColor(filtered, contrast: 2.0, brightness: 0.0);
        for (int y = 0; y < filtered.height; y++) {
          for (int x = 0; x < filtered.width; x++) {
            int luma = img.getLuminance(filtered.getPixel(x, y)).toInt();
            filtered.setPixel(x, y, luma > 128 ? img.ColorUint8.rgb(255, 255, 255) : img.ColorUint8.rgb(0, 0, 0));
          }
        }
      } else if (filter == 'magic') {
        filtered = img.grayscale(image);
        filtered = img.adjustColor(filtered, contrast: 2.2, brightness: 0.1);
        // Applique un léger flou puis un renforcement (convolution)
        filtered = img.gaussianBlur(filtered, radius: 1);
        filtered = img.convolution(filtered, filter: [
          0, -1, 0,
          -1, 5, -1,
          0, -1, 0,
        ]);
      } else {
        filtered = image;
      }

      // Sauvegarder temporairement
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(filtered, quality: 90));
      
      setState(() {
        _currentFile = tempFile;
        _isProcessing = false;
      });
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