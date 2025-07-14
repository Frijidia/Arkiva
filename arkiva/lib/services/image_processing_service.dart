import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:opencv_4/opencv_4.dart';
import 'package:opencv_4/factory/pathfrom.dart';
import 'package:opencv_4/factory/core/imgproc.dart';

class ImageProcessingService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Scan complet : essaie la détection automatique, sinon propose le manuel
  Future<File?> processDocumentScan(File imageFile, {List<Offset>? manualCorners}) async {
    try {
      debugPrint('Début du scan document avancé: ${imageFile.path}');
      String imagePath = imageFile.path;

      // 1. Détection des bords (Canny)
      final cannyBytes = await ImgProc.canny(
        pathFrom: CVPathFrom.GALLERY_CAMERA,
        pathString: imagePath,
        threshold1: 50,
        threshold2: 150,
      );

      // 2. Détection automatique simplifiée des coins (sur l'image Canny)
      List<Offset>? detectedCorners = await _detectDocumentCorners(cannyBytes);

      if (detectedCorners != null && detectedCorners.length == 4) {
        // 3. Correction de perspective automatique
        final corrected = await _warpPerspective(imagePath, detectedCorners);
        if (corrected != null) {
          return corrected;
        }
      }

      // 4. Si l'automatique échoue et des coins manuels sont fournis, utiliser le manuel
      if (manualCorners != null && manualCorners.length == 4) {
        final corrected = await _warpPerspective(imagePath, manualCorners);
        if (corrected != null) {
          return corrected;
        }
      }

      // 5. Fallback : retourne l'image Canny (bords)
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${tempDir.path}/scanned_canny_$timestamp.jpg');
      await outputFile.writeAsBytes(cannyBytes);
      return outputFile;
    } catch (e) {
      debugPrint('Erreur scan avancé: $e');
      return null;
    }
  }

  /// Détection automatique simplifiée des coins (sur image Canny)
  Future<List<Offset>?> _detectDocumentCorners(Uint8List cannyBytes) async {
    // Version simplifiée : détecte les coins extrêmes du masque binaire
    try {
      final image = img.decodeImage(cannyBytes);
      if (image == null) return null;
      int width = image.width;
      int height = image.height;
      List<Offset> points = [];
      // Cherche les points extrêmes (haut-gauche, haut-droit, bas-gauche, bas-droit)
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int pixel = image.getPixel(x, y);
          if (img.getLuminance(pixel) > 128) {
            points.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
      if (points.isEmpty) return null;
      // Trouve les coins extrêmes
      Offset topLeft = points.reduce((a, b) => (a.dx + a.dy < b.dx + b.dy) ? a : b);
      Offset topRight = points.reduce((a, b) => (a.dx - a.dy > b.dx - b.dy) ? a : b);
      Offset bottomLeft = points.reduce((a, b) => (a.dy - a.dx > b.dy - b.dx) ? a : b);
      Offset bottomRight = points.reduce((a, b) => (a.dx + a.dy > b.dx + b.dy) ? a : b);
      return [topLeft, topRight, bottomRight, bottomLeft];
    } catch (e) {
      debugPrint('Erreur détection coins: $e');
      return null;
    }
  }

  /// Correction de perspective avec OpenCV
  Future<File?> _warpPerspective(String imagePath, List<Offset> corners) async {
    try {
      // Convertit les coins en format OpenCV
      List<double> pts = corners.expand((o) => [o.dx, o.dy]).toList();
      // On suppose un format A4 (210x297mm) en pixels (ex: 800x1131)
      List<double> dst = [0,0, 800,0, 800,1131, 0,1131];
      final warpedBytes = await ImgProc.warpPerspective(
        pathFrom: CVPathFrom.GALLERY_CAMERA,
        pathString: imagePath,
        points: pts,
        outputPoints: dst,
        outputSize: [800, 1131],
      );
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${tempDir.path}/scanned_warp_$timestamp.jpg');
      await outputFile.writeAsBytes(warpedBytes);
      return outputFile;
    } catch (e) {
      debugPrint('Erreur warpPerspective: $e');
      return null;
    }
  }

  /// Nouvelle méthode utilisant OpenCV pour un effet CamScanner
  Future<File?> processImageWithOpenCV(File imageFile) async {
    try {
      debugPrint('Début du traitement OpenCV: ${imageFile.path}');
      String imagePath = imageFile.path;

      // 1. Détection des bords (Canny)
      final cannyBytes = await ImgProc.canny(
        pathFrom: CVPathFrom.GALLERY_CAMERA,
        pathString: imagePath,
        threshold1: 50,
        threshold2: 150,
      );

      // 2. (Optionnel) Correction de perspective à ajouter ici plus tard
      // TODO: Détecter les coins et appliquer ImgProc.warpPerspective

      // 3. Sauvegarde du résultat
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${tempDir.path}/scanned_opencv_$timestamp.jpg');
      await outputFile.writeAsBytes(cannyBytes);

      debugPrint('Image traitée (OpenCV) sauvegardée: ${outputFile.path}');
      return outputFile;
    } catch (e) {
      debugPrint('Erreur OpenCV: $e');
      return null;
    }
  }

  // Ancienne méthode fallback (amélioration simple)
  Future<File?> processImage(File imageFile) async {
    try {
      debugPrint('Début du traitement de l\'image: ${imageFile.path}');
      
      if (!await imageFile.exists()) {
        debugPrint('Le fichier image n\'existe pas');
        return null;
      }
      List<int> imageBytes;
      try {
        imageBytes = await imageFile.readAsBytes();
      } catch (e) {
        debugPrint('Erreur lors de la lecture du fichier: $e');
        return null;
      }
      img.Image? image;
      try {
        image = img.decodeImage(Uint8List.fromList(imageBytes));
      } catch (e) {
        debugPrint('Erreur lors du décodage de l\'image: $e');
        return null;
      }
      if (image == null) {
        debugPrint('Impossible de décoder l\'image');
        return null;
      }
      img.Image processedImage;
      try {
        processedImage = _enhanceImageQuality(image);
        debugPrint('Amélioration de qualité appliquée');
      } catch (e) {
        debugPrint('Erreur lors de l\'amélioration d\'image: $e');
        processedImage = image;
      }
      try {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final outputFile = File('${tempDir.path}/scanned_$timestamp.jpg');
        final jpegBytes = img.encodeJpg(processedImage, quality: 85);
        await outputFile.writeAsBytes(jpegBytes);
        debugPrint('Image traitée sauvegardée: ${outputFile.path}');
        return outputFile;
      } catch (e) {
        debugPrint('Erreur lors de la sauvegarde: $e');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur générale lors du traitement de l\'image: $e');
      return null;
    }
  }

  img.Image _enhanceImageQuality(img.Image image) {
    try {
      image = img.adjustColor(image, contrast: 1.1);
      image = img.adjustColor(image, brightness: 1.05);
      return image;
    } catch (e) {
      debugPrint('Erreur lors de l\'amélioration d\'image: $e');
      return image;
    }
  }

  Future<String> _extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      String extractedText = '';
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          extractedText += line.text + '\n';
        }
      }
      return extractedText.trim();
    } catch (e) {
      debugPrint('Erreur lors de l\'extraction de texte: $e');
      return '';
    }
  }

  void dispose() {
    try {
      _textRecognizer.close();
    } catch (e) {
      debugPrint('Erreur lors de la fermeture du recognizer: $e');
    }
  }
} 