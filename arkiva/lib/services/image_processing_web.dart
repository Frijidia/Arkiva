import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<File?> processDocumentScan(File imageFile, {List<Offset>? manualCorners}) async {
    // Scan avancé non supporté sur le web
    return null;
  }

  // Les autres méthodes (processImage, etc.) restent inchangées et compatibles web.
} 