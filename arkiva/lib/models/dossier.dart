import 'package:arkiva/models/document.dart';

class Dossier {
  final int? dossierId;
  final int? casierId;
  final String nom;
  final String description;
  final DateTime createdAt;
  final int versionId;

  Dossier({
    this.dossierId,
    this.casierId,
    required this.nom,
    required this.description,
    required this.createdAt,
    required this.versionId,
  });

  factory Dossier.fromJson(Map<String, dynamic> json) {
    final int? parsedDossierId = json['dossier_id'] as int?;
    final int? parsedCasierId = json['cassier_id'] as int?;

    if (parsedDossierId == null) {
      throw FormatException('Dossier ID is missing or null in JSON: $json');
    }
    if (parsedCasierId == null) {
      throw FormatException('Casier ID is missing or null in JSON: $json');
    }

    return Dossier(
      dossierId: parsedDossierId,
      casierId: parsedCasierId,
      nom: json['nom'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      versionId: json['version_id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dossier_id': dossierId,
      'cassier_id': casierId,
      'nom': nom,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'version_id': versionId,
    };
  }
} 