import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<File?> processImage(File imageFile) async {
    try {
      debugPrint('Début du traitement de l\'image: ${imageFile.path}');
      
      // Lire l'image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('Impossible de décoder l\'image');
        return null;
      }

      // Étape 1: Amélioration de la qualité (simplifiée)
      final processedImage = _enhanceImageQuality(image);
      debugPrint('Amélioration de qualité appliquée');

      // Étape 2: OCR pour extraire le texte (optionnel)
      try {
        final ocrText = await _extractText(imageFile);
        debugPrint('OCR terminé, ${ocrText.length} caractères extraits');
      } catch (e) {
        debugPrint('OCR échoué: $e');
      }

      // Étape 3: Sauvegarder l'image traitée
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${tempDir.path}/scanned_$timestamp.jpg');
      
      final jpegBytes = img.encodeJpg(processedImage, quality: 90);
      await outputFile.writeAsBytes(jpegBytes);
      
      debugPrint('Image traitée sauvegardée: ${outputFile.path}');
      return outputFile;
    } catch (e) {
      debugPrint('Erreur lors du traitement de l\'image: $e');
      return null;
    }
  }

  img.Image _enhanceImageQuality(img.Image image) {
    try {
      // Amélioration du contraste
      image = img.adjustColor(image, contrast: 1.3);
      
      // Amélioration de la luminosité
      image = img.adjustColor(image, brightness: 1.1);
      
      // Réduction du bruit (légère)
      image = img.gaussianBlur(image, radius: 1);
      
      // Amélioration de la netteté
      image = img.emboss(image);
      
      return image;
    } catch (e) {
      debugPrint('Erreur lors de l\'amélioration d\'image: $e');
      return image; // Retourner l'image originale en cas d'erreur
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