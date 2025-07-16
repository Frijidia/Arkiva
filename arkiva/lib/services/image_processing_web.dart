import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ImageProcessingService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<File?> processDocumentScan(File imageFile, {List<Offset>? manualCorners}) async {
    // Scan avancé non supporté sur le web
    return null;
  }

  // Méthode pour compatibilité avec le scan simple
  Future<File?> processImage(File imageFile) async {
    // Sur le web, retourne simplement l'image d'origine
    return imageFile;
  }

  // Nouvelle méthode pour convertir en PDF (compatibilité web)
  Future<File?> convertImageToPdf(File imageFile) async {
    try {
      debugPrint('Conversion de l\'image en PDF (web): ${imageFile.path}');
      
      // Sur le web, on retourne l'image d'origine car la conversion PDF
      // nécessite des bibliothèques natives qui ne sont pas disponibles
      debugPrint('Conversion PDF non supportée sur le web, retour de l\'image originale');
      return imageFile;
    } catch (e) {
      debugPrint('Erreur lors de la conversion en PDF (web): $e');
      return null;
    }
  }

  // Méthode dispose pour compatibilité
  void dispose() {
    _textRecognizer.close();
  }

  // Les autres méthodes (processImage, etc.) restent inchangées et compatibles web.
} 