import 'package:arkiva/models/document.dart';

class Dossier {
  final int dossierId;
  final int casierId;
  final String nom;
  final String description;
  final DateTime dateCreation;
  final DateTime dateModification;

  Dossier({
    required this.dossierId,
    required this.casierId,
    required this.nom,
    required this.description,
    required this.dateCreation,
    required this.dateModification,
  });

  factory Dossier.fromJson(Map<String, dynamic> json) {
    return Dossier(
      dossierId: json['dossier_id'],
      casierId: json['casier_id'],
      nom: json['nom'],
      description: json['description'] ?? '',
      dateCreation: DateTime.parse(json['date_creation']),
      dateModification: DateTime.parse(json['date_modification']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dossier_id': dossierId,
      'casier_id': casierId,
      'nom': nom,
      'description': description,
      'date_creation': dateCreation.toIso8601String(),
      'date_modification': dateModification.toIso8601String(),
    };
  }
} 