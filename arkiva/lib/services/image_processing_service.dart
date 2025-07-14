import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<File?> processImage(File imageFile) async {
    try {
      debugPrint('Début du traitement de l\'image: ${imageFile.path}');
      
      // Vérifier que le fichier existe
      if (!await imageFile.exists()) {
        debugPrint('Le fichier image n\'existe pas');
        return null;
      }

      // Lire l'image avec gestion d'erreur
      List<int> imageBytes;
      try {
        imageBytes = await imageFile.readAsBytes();
      } catch (e) {
        debugPrint('Erreur lors de la lecture du fichier: $e');
        return null;
      }

      // Décoder l'image
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

      // Étape 1: Amélioration de la qualité (très simplifiée)
      img.Image processedImage;
      try {
        processedImage = _enhanceImageQuality(image);
        debugPrint('Amélioration de qualité appliquée');
      } catch (e) {
        debugPrint('Erreur lors de l\'amélioration d\'image: $e');
        processedImage = image; // Utiliser l'image originale
      }

      // Étape 2: OCR (optionnel et simplifié)
      try {
        // Désactiver temporairement l'OCR pour éviter les crashes
        // final ocrText = await _extractText(imageFile);
        // debugPrint('OCR terminé, ${ocrText.length} caractères extraits');
        debugPrint('OCR désactivé pour éviter les crashes');
      } catch (e) {
        debugPrint('OCR échoué: $e');
      }

      // Étape 3: Sauvegarder l'image traitée
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
      // Amélioration très légère pour éviter les crashes
      
      // Amélioration du contraste (légère)
      image = img.adjustColor(image, contrast: 1.1);
      
      // Amélioration de la luminosité (légère)
      image = img.adjustColor(image, brightness: 1.05);
      
      // Pas de gaussianBlur pour éviter les problèmes de performance
      // Pas d'emboss pour éviter les problèmes de performance
      
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