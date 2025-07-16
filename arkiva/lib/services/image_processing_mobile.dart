import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Traite un scan de document avec détection automatique des coins
  Future<File?> processDocumentScan(File imageFile, {List<Offset>? manualCorners}) async {
    try {
      debugPrint('Début du traitement du document: ${imageFile.path}');
      
      // Vérifier si le fichier existe
      if (!await imageFile.exists()) {
        debugPrint('Fichier introuvable: ${imageFile.path}');
        return null;
      }

      // Pour l'instant, retourner simplement l'image d'origine
      // Le traitement avancé sera implémenté plus tard
      debugPrint('Traitement simplifié - retour de l\'image originale');
      return imageFile;
      
    } catch (e) {
      debugPrint('Erreur lors du traitement du document: $e');
      return imageFile; // Retourner l'original en cas d'erreur
    }
  }

  /// Convertit une image en PDF
  Future<File?> convertImageToPdf(File imageFile) async {
    try {
      debugPrint('Conversion de l\'image en PDF: ${imageFile.path}');
      
      // Vérifier si le fichier existe
      if (!await imageFile.exists()) {
        debugPrint('Fichier introuvable pour la conversion PDF: ${imageFile.path}');
        return null;
      }

      // Pour l'instant, retourner l'image d'origine
      // La conversion PDF sera implémentée plus tard
      debugPrint('Conversion PDF simplifiée - retour de l\'image originale');
      return imageFile;
      
    } catch (e) {
      debugPrint('Erreur lors de la conversion en PDF: $e');
      return imageFile; // Retourner l'original en cas d'erreur
    }
  }

  /// Méthode pour compatibilité avec le scan simple
  Future<File?> processImage(File imageFile) async {
    return await processDocumentScan(imageFile);
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