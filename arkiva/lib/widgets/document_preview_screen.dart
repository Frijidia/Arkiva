import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Image.file(
                  _currentFile,
                  width: MediaQuery.of(context).size.width * 0.9,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              _isProcessing
                  ? const CircularProgressIndicator()
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        _buildFilterButton('original', 'Original'),
                        _buildFilterButton('bw', 'Noir & Blanc'),
                        _buildFilterButton('magic', 'Magique'),
                      ],
                    ),
              const SizedBox(height: 16),
              Text(
                'Aperçu du résultat. Choisissez un filtre puis validez.',
                style: TextStyle(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String key, String label) {
    return ElevatedButton(
      onPressed: _isProcessing || _selectedFilter == key ? null : () => _applyFilter(key),
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedFilter == key ? Colors.blue : Colors.grey[300],
        foregroundColor: _selectedFilter == key ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _isProcessing = true;
      _selectedFilter = filter;
    });
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
      setState(() { _isProcessing = false; });
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
  }
} 