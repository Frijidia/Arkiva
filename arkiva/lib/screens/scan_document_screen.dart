import 'package:flutter/material.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/upload_service.dart';
import 'package:arkiva/services/image_processing_service.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:arkiva/widgets/manual_corner_selector.dart';
import 'package:arkiva/widgets/document_preview_screen.dart';

class ScanDocumentScreen extends StatefulWidget {
  final Dossier dossier;

  const ScanDocumentScreen({
    super.key,
    required this.dossier,
  });

  @override
  State<ScanDocumentScreen> createState() => _ScanDocumentScreenState();
}

class _ScanDocumentScreenState extends State<ScanDocumentScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final UploadService _uploadService = UploadService();
  final ImageProcessingService _imageProcessingService = ImageProcessingService();
  
  List<File> _scannedImages = [];
  List<File> _processedImages = [];
  bool _isUploading = false;
  bool _isProcessing = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _imageProcessingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si on est sur mobile
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scanner de documents'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'La fonctionnalité de scan n\'est disponible que sur mobile',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Scanner CamScanner'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_processedImages.isNotEmpty)
              TextButton.icon(
                onPressed: _isUploading ? null : _uploadScannedDocuments,
                icon: _isUploading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload, color: Colors.white),
                label: Text(
                  _isUploading ? 'Upload...' : 'Uploader',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Section des images scannées
            if (_processedImages.isNotEmpty)
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.document_scanner, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Documents scannés (${_processedImages.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _processedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
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
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _processedImages[index],
                                    width: 140,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                // Indicateur de traitement
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'Traité',
                                          style: TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            
            // Section principale avec les boutons d'action
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Titre et description
                      Column(
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 80,
                            color: Theme.of(context).primaryColor.withOpacity(0.7),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Scanner comme CamScanner',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Transformez votre téléphone en scanner professionnel\navec détection automatique des bords et amélioration d\'image',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Boutons d'action
                      if (_isProcessing)
                        Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Traitement en cours...',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.camera_alt,
                                label: 'Scanner',
                                color: Theme.of(context).primaryColor,
                                onPressed: _scanDocument,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.photo_library,
                                label: 'Galerie',
                                color: Colors.green,
                                onPressed: _pickFromGallery,
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 32),
                      
                      // Conseils d'utilisation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Conseils pour un meilleur scan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Placez le document sur une surface plane\n• Assurez-vous d\'un bon éclairage\n• Évitez les ombres et reflets\n• Gardez l\'appareil stable',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanDocument() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Erreur lors du scan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('Début du traitement avancé de l\'image: ${imageFile.path}');
      
      // 1. Scan automatique avec détection des coins
      File? processedImage = await _imageProcessingService.processDocumentScan(imageFile);

      if (processedImage != null && await processedImage.exists()) {
        // 2. Proposer la conversion en PDF
        await _showProcessingOptions(context, imageFile, processedImage);
      } else {
        // 3. Si l'automatique échoue, proposer la sélection manuelle des coins
        await _showManualCornerSelection(context, imageFile);
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement: $e');
      setState(() {
        _scannedImages.add(imageFile);
        _processedImages.add(imageFile);
      });
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Image ajoutée (erreur de traitement: ${e.toString()})'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Affiche les options de traitement (image ou PDF)
  Future<void> _showProcessingOptions(BuildContext context, File original, File processed) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.document_scanner, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Format de sortie'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisissez le format de sortie pour votre document scanné :',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildFormatOption(
                      context,
                      'Image',
                      Icons.image,
                      'Conserver en format image (JPG)',
                      () => _selectFormat(context, original, processed, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormatOption(
                      context,
                      'PDF',
                      Icons.picture_as_pdf,
                      'Convertir en PDF',
                      () => _selectFormat(context, original, processed, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormatOption(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFormat(BuildContext context, File original, File processed, bool convertToPdf) async {
    Navigator.of(context).pop();
    
    setState(() {
      _isProcessing = true;
    });

    try {
      File finalFile;
      
      if (convertToPdf) {
        // Convertir en PDF
        finalFile = await _imageProcessingService.convertImageToPdf(processed) ?? processed;
        
        // Vérifier si on est sur le web
        if (kIsWeb) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Conversion PDF non disponible sur le web. Image conservée.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Document converti en PDF !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Garder en image
        finalFile = processed;
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Document traité en image !'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Afficher la prévisualisation
      await _showDocumentPreview(context, original, finalFile);
      
    } catch (e) {
      debugPrint('Erreur lors de la conversion: $e');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la conversion: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showDocumentPreview(BuildContext context, File original, File corrected) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DocumentPreviewScreen(
          imageFile: corrected,
          onValidate: (filteredFile) {
            Navigator.of(ctx).pop();
            setState(() {
              _scannedImages.add(original);
              _processedImages.add(filteredFile);
            });
            _scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                content: Text('Document scanné et validé !'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Affiche un écran/modal pour la sélection manuelle des coins
  Future<void> _showManualCornerSelection(BuildContext context, File imageFile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ManualCornerSelector(
          imageFile: imageFile,
          onValidate: (corners) async {
            Navigator.of(ctx).pop();
            setState(() { _isProcessing = true; });
            // Appliquer la correction de perspective avec les coins manuels
            final processed = await _imageProcessingService.processDocumentScan(imageFile, manualCorners: corners);
            if (processed != null && await processed.exists()) {
              await _showDocumentPreview(context, imageFile, processed);
            } else {
              setState(() {
                _scannedImages.add(imageFile);
                _processedImages.add(imageFile);
              });
              _scaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text('Erreur lors de la correction manuelle. Image ajoutée brute.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            setState(() { _isProcessing = false; });
          },
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _scannedImages.removeAt(index);
      _processedImages.removeAt(index);
    });
  }

  Future<void> _cropImage(int index) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _processedImages[index].path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Recadrer',
        ),
      ],
    );
    if (croppedFile != null) {
      setState(() {
        _processedImages[index] = File(croppedFile.path);
      });
    }
  }

  Future<void> _uploadScannedDocuments() async {
    if (_processedImages.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Aucun document à uploader'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token == null || entrepriseId == null) {
        throw Exception('Token ou ID entreprise manquant');
      }

      await _uploadService.uploadScannedDocuments(
        token: token,
        files: _processedImages,
        dossierId: widget.dossier.dossierId!,
        entrepriseId: entrepriseId,
      );

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Documents scannés uploadés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Retourner à l'écran précédent
        Navigator.pop(context, true);
      }

    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }
} 