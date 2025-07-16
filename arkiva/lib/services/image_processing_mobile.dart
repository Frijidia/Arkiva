import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageProcessingService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Traite un scan de document avec détection automatique des coins
  Future<File?> processDocumentScan(File imageFile, {List<Offset>? manualCorners}) async {
    try {
      debugPrint('Début du traitement du document: ${imageFile.path}');
      
      // Lire l'image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('Impossible de décoder l\'image');
        return null;
      }

      // Détection automatique des coins (simplifiée)
      List<Offset> corners = manualCorners ?? _detectCorners(image);
      
      // Appliquer la correction de perspective
      img.Image? correctedImage = _applyPerspectiveCorrection(image, corners);
      
      if (correctedImage == null) {
        debugPrint('Échec de la correction de perspective');
        return imageFile; // Retourner l'original si la correction échoue
      }

      // Améliorer la qualité
      correctedImage = _enhanceImage(correctedImage);

      // Sauvegarder l'image traitée
      final tempDir = await getTemporaryDirectory();
      final processedPath = '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedFile = File(processedPath);
      
      await processedFile.writeAsBytes(img.encodeJpg(correctedImage, quality: 95));
      
      debugPrint('Image traitée sauvegardée: $processedPath');
      return processedFile;
      
    } catch (e) {
      debugPrint('Erreur lors du traitement du document: $e');
      return null;
    }
  }

  /// Convertit une image en PDF
  Future<File?> convertImageToPdf(File imageFile) async {
    try {
      debugPrint('Conversion de l\'image en PDF: ${imageFile.path}');
      
      // Lire l'image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('Impossible de décoder l\'image pour la conversion PDF');
        return null;
      }

      // Créer un PDF simple avec l'image
      final pdfBytes = await _createPdfFromImage(image);
      
      if (pdfBytes == null) {
        debugPrint('Échec de la création du PDF');
        return null;
      }

      // Sauvegarder le PDF
      final tempDir = await getTemporaryDirectory();
      final pdfPath = '${tempDir.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File(pdfPath);
      
      await pdfFile.writeAsBytes(pdfBytes);
      
      debugPrint('PDF créé: $pdfPath');
      return pdfFile;
      
    } catch (e) {
      debugPrint('Erreur lors de la conversion en PDF: $e');
      return null;
    }
  }

  /// Méthode pour compatibilité avec le scan simple
  Future<File?> processImage(File imageFile) async {
    return await processDocumentScan(imageFile);
  }

  /// Détection automatique des coins (simplifiée)
  List<Offset> _detectCorners(img.Image image) {
    // Pour l'instant, retourner les coins de l'image complète
    // Dans une implémentation complète, on utiliserait OpenCV ou une bibliothèque similaire
    return [
      const Offset(0, 0),
      Offset(image.width.toDouble(), 0),
      Offset(image.width.toDouble(), image.height.toDouble()),
      Offset(0, image.height.toDouble()),
    ];
  }

  /// Applique la correction de perspective
  img.Image? _applyPerspectiveCorrection(img.Image image, List<Offset> corners) {
    try {
      // Calculer la transformation de perspective
      final srcPoints = [
        corners[0], corners[1], corners[2], corners[3]
      ];
      
      // Déterminer la taille de sortie (format A4)
      final targetWidth = 595; // A4 width en points
      final targetHeight = 842; // A4 height en points
      
      final dstPoints = [
        const Offset(0, 0),
        Offset(targetWidth.toDouble(), 0),
        Offset(targetWidth.toDouble(), targetHeight.toDouble()),
        Offset(0, targetHeight.toDouble()),
      ];

      // Appliquer la transformation
      return img.transform(
        image,
        srcPoints: srcPoints,
        dstPoints: dstPoints,
        width: targetWidth,
        height: targetHeight,
      );
    } catch (e) {
      debugPrint('Erreur lors de la correction de perspective: $e');
      return null;
    }
  }

  /// Améliore la qualité de l'image
  img.Image _enhanceImage(img.Image image) {
    // Convertir en niveaux de gris
    img.Image enhanced = img.grayscale(image);
    
    // Augmenter le contraste
    enhanced = img.adjustColor(enhanced, contrast: 1.5, brightness: 0.1);
    
    // Appliquer un léger flou pour réduire le bruit
    enhanced = img.gaussianBlur(enhanced, radius: 0.5);
    
    // Renforcer les contours
    enhanced = img.convolution(enhanced, filter: [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0,
    ]);
    
    return enhanced;
  }

  /// Crée un PDF simple à partir d'une image
  Future<Uint8List?> _createPdfFromImage(img.Image image) async {
    try {
      // Encoder l'image en base64
      final jpegBytes = img.encodeJpg(image, quality: 90);
      final base64Image = base64Encode(jpegBytes);
      
      // Créer un PDF simple avec l'image
      final pdfContent = '''
%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj

2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj

3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 595 842]
/Contents 4 0 R
/Resources <<
/XObject <<
/Im1 5 0 R
>>
>>
>>
endobj

4 0 obj
<<
/Length 44
>>
stream
q
595 0 0 842 0 0 cm
/Im1 Do
Q
endstream
endobj

5 0 obj
<<
/Type /XObject
/Subtype /Image
/Width ${image.width}
/Height ${image.height}
/ColorSpace /DeviceGray
/BitsPerComponent 8
/Length ${jpegBytes.length}
>>
stream
${String.fromCharCodes(jpegBytes)}
endstream
endobj

xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000256 00000 n 
0000000320 00000 n 
trailer
<<
/Size 6
/Root 1 0 R
>>
startxref
${jpegBytes.length + 400}
%%EOF
''';

      return Uint8List.fromList(pdfContent.codeUnits);
    } catch (e) {
      debugPrint('Erreur lors de la création du PDF: $e');
      return null;
    }
  }

  /// Extrait le texte d'une image avec OCR
  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            extractedText += element.text + ' ';
          }
          extractedText += '\n';
        }
      }
      
      return extractedText.trim();
    } catch (e) {
      debugPrint('Erreur lors de l\'extraction de texte: $e');
      return '';
    }
  }

  /// Méthode dispose pour compatibilité
  void dispose() {
    _textRecognizer.close();
  }
} 