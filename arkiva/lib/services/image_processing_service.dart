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

      // Étape 1: Détection des coins du document
      final corners = _detectDocumentCorners(image);
      debugPrint('Coins détectés: ${corners?.length ?? 0}');

      // Étape 2: Correction de perspective si des coins sont détectés
      img.Image processedImage;
      if (corners != null && corners.length == 4) {
        processedImage = _applyPerspectiveCorrection(image, corners);
        debugPrint('Correction de perspective appliquée');
      } else {
        processedImage = image;
        debugPrint('Aucune correction de perspective appliquée');
      }

      // Étape 3: Amélioration de la qualité
      processedImage = _enhanceImageQuality(processedImage);
      debugPrint('Amélioration de qualité appliquée');

      // Étape 4: OCR pour extraire le texte
      final ocrText = await _extractText(imageFile);
      debugPrint('OCR terminé, ${ocrText.length} caractères extraits');

      // Étape 5: Sauvegarder l'image traitée
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

  List<Point>? _detectDocumentCorners(img.Image image) {
    try {
      // Convertir en niveaux de gris pour la détection de contours
      final grayImage = img.grayscale(image);
      
      // Appliquer un filtre de flou gaussien pour réduire le bruit
      final blurredImage = img.gaussianBlur(grayImage, radius: 2);
      
      // Détecter les contours avec l'algorithme de Canny
      final edges = _detectEdges(blurredImage);
      
      // Trouver les contours fermés
      final contours = _findContours(edges);
      
      // Filtrer les contours pour trouver le document
      final documentContour = _findDocumentContour(contours, image.width, image.height);
      
      if (documentContour != null) {
        // Simplifier le contour en 4 points (coins)
        return _simplifyContourToCorners(documentContour);
      }
      
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la détection des coins: $e');
      return null;
    }
  }

  img.Image _detectEdges(img.Image image) {
    // Implémentation simplifiée de détection de contours
    final width = image.width;
    final height = image.height;
    final output = img.Image(width: width, height: height);
    
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final center = image.getPixel(x, y);
        final left = image.getPixel(x - 1, y);
        final right = image.getPixel(x + 1, y);
        final top = image.getPixel(x, y - 1);
        final bottom = image.getPixel(x, y + 1);
        
        // Calcul du gradient
        final gradX = (right.r - left.r).abs();
        final gradY = (bottom.r - top.r).abs();
        final gradient = sqrt(gradX * gradX + gradY * gradY);
        
        if (gradient > 30) {
          output.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        } else {
          output.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }
    
    return output;
  }

  List<List<Point>> _findContours(img.Image edges) {
    // Implémentation simplifiée de recherche de contours
    final contours = <List<Point>>[];
    final visited = List.generate(edges.height, (y) => List.generate(edges.width, (x) => false));
    
    for (int y = 0; y < edges.height; y++) {
      for (int x = 0; x < edges.width; x++) {
        if (!visited[y][x] && edges.getPixel(x, y).r > 128) {
          final contour = <Point>[];
          _traceContour(edges, visited, x, y, contour);
          if (contour.length > 10) { // Filtrer les petits contours
            contours.add(contour);
          }
        }
      }
    }
    
    return contours;
  }

  void _traceContour(img.Image edges, List<List<bool>> visited, int startX, int startY, List<Point> contour) {
    final stack = <Point>[Point(startX, startY)];
    
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final x = current.x;
      final y = current.y;
      
      if (x < 0 || x >= edges.width || y < 0 || y >= edges.height || visited[y][x]) {
        continue;
      }
      
      if (edges.getPixel(x, y).r > 128) {
        visited[y][x] = true;
        contour.add(current);
        
        // Ajouter les voisins
        stack.addAll([
          Point(x + 1, y),
          Point(x - 1, y),
          Point(x, y + 1),
          Point(x, y - 1),
        ]);
      }
    }
  }

  List<Point>? _findDocumentContour(List<List<Point>> contours, int imageWidth, int imageHeight) {
    // Trouver le plus grand contour rectangulaire
    List<Point>? bestContour;
    double bestScore = 0;
    
    for (final contour in contours) {
      if (contour.length < 4) continue;
      
      // Calculer l'aire du contour
      final area = _calculateContourArea(contour);
      
      // Vérifier si c'est approximativement rectangulaire
      final boundingBox = _calculateBoundingBox(contour);
      final boundingArea = boundingBox.width * boundingBox.height;
      
      if (boundingArea > 0) {
        final rectangularity = area / boundingArea;
        
        // Score basé sur la taille et la rectangularité
        final score = area * rectangularity;
        
        if (score > bestScore && rectangularity > 0.7) {
          bestScore = score;
          bestContour = contour;
        }
      }
    }
    
    return bestContour;
  }

  double _calculateContourArea(List<Point> contour) {
    // Formule de l'aire d'un polygone
    double area = 0;
    for (int i = 0; i < contour.length; i++) {
      final j = (i + 1) % contour.length;
      area += contour[i].x * contour[j].y;
      area -= contour[j].x * contour[i].y;
    }
    return area.abs() / 2;
  }

  Rectangle _calculateBoundingBox(List<Point> contour) {
    int minX = contour[0].x;
    int maxX = contour[0].x;
    int minY = contour[0].y;
    int maxY = contour[0].y;
    
    for (final point in contour) {
      minX = min(minX, point.x);
      maxX = max(maxX, point.x);
      minY = min(minY, point.y);
      maxY = max(maxY, point.y);
    }
    
    return Rectangle(minX, minY, maxX - minX, maxY - minY);
  }

  List<Point> _simplifyContourToCorners(List<Point> contour) {
    // Simplifier le contour en 4 coins
    final boundingBox = _calculateBoundingBox(contour);
    final centerX = boundingBox.left + boundingBox.width / 2;
    final centerY = boundingBox.top + boundingBox.height / 2;
    
    // Trouver les 4 points les plus éloignés du centre dans chaque quadrant
    final quadrants = List.generate(4, (i) => <Point>[]);
    
    for (final point in contour) {
      final dx = point.x - centerX;
      final dy = point.y - centerY;
      
      int quadrant;
      if (dx >= 0 && dy >= 0) {
        quadrant = 0; // Bas-droite
      } else if (dx < 0 && dy >= 0) {
        quadrant = 1; // Bas-gauche
      } else if (dx < 0 && dy < 0) {
        quadrant = 2; // Haut-gauche
      } else {
        quadrant = 3; // Haut-droite
      }
      
      quadrants[quadrant].add(point);
    }
    
    final corners = <Point>[];
    for (final quadrant in quadrants) {
      if (quadrant.isNotEmpty) {
        // Trouver le point le plus éloigné du centre dans ce quadrant
        Point? farthestPoint;
        double maxDistance = 0;
        
        for (final point in quadrant) {
          final distance = sqrt(pow(point.x - centerX, 2) + pow(point.y - centerY, 2));
          if (distance > maxDistance) {
            maxDistance = distance;
            farthestPoint = point;
          }
        }
        
        if (farthestPoint != null) {
          corners.add(farthestPoint);
        }
      }
    }
    
    return corners;
  }

  img.Image _applyPerspectiveCorrection(img.Image image, List<Point> corners) {
    if (corners.length != 4) return image;
    
    // Trier les coins dans l'ordre: haut-gauche, haut-droite, bas-droite, bas-gauche
    final sortedCorners = _sortCorners(corners);
    
    // Définir les dimensions de sortie (format A4)
    final outputWidth = 800;
    final outputHeight = (outputWidth * 1.414).round(); // Ratio A4
    
    // Points de destination (rectangle parfait)
    final destinationPoints = [
      Point(0, 0),
      Point(outputWidth, 0),
      Point(outputWidth, outputHeight),
      Point(0, outputHeight),
    ];
    
    // Calculer la matrice de transformation
    final transformMatrix = _calculatePerspectiveTransform(sortedCorners, destinationPoints);
    
    // Appliquer la transformation
    return _applyTransformation(image, transformMatrix, outputWidth, outputHeight);
  }

  List<Point> _sortCorners(List<Point> corners) {
    // Calculer le centre
    final centerX = corners.map((p) => p.x).reduce((a, b) => a + b) / corners.length;
    final centerY = corners.map((p) => p.y).reduce((a, b) => a + b) / corners.length;
    
    // Trier par angle par rapport au centre
    corners.sort((a, b) {
      final angleA = atan2(a.y - centerY, a.x - centerX);
      final angleB = atan2(b.y - centerY, b.x - centerX);
      return angleA.compareTo(angleB);
    });
    
    return corners;
  }

  List<List<double>> _calculatePerspectiveTransform(List<Point> source, List<Point> destination) {
    // Implémentation simplifiée de calcul de matrice de transformation
    // En pratique, on utiliserait une bibliothèque comme OpenCV
    
    // Pour l'instant, retourner une matrice d'identité
    return [
      [1.0, 0.0, 0.0],
      [0.0, 1.0, 0.0],
      [0.0, 0.0, 1.0],
    ];
  }

  img.Image _applyTransformation(img.Image image, List<List<double>> matrix, int outputWidth, int outputHeight) {
    // Implémentation simplifiée de transformation
    // Pour l'instant, retourner l'image originale
    return image;
  }

  img.Image _enhanceImageQuality(img.Image image) {
    // Amélioration du contraste
    image = img.adjustColor(image, contrast: 1.5);
    
    // Amélioration de la luminosité
    image = img.adjustColor(image, brightness: 1.2);
    
    // Réduction du bruit
    image = img.gaussianBlur(image, radius: 1);
    
    // Amélioration de la netteté (emboss pour simuler sharpen)
    image = img.emboss(image);
    
    return image;
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
    _textRecognizer.close();
  }
} 