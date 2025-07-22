import 'package:arkiva/models/document.dart';
import 'package:arkiva/models/dossier.dart';

class Casier {
  final int casierId;
  final int armoireId;
  final String nom;
  final String description;
  final DateTime dateCreation;
  final DateTime dateModification;
  final bool isDeleted;
  final int userId;
  final int versionId;

  Casier({
    required this.casierId,
    required this.armoireId,
    required this.nom,
    required this.description,
    required this.dateCreation,
    required this.dateModification,
    required this.isDeleted,
    required this.userId,
    required this.versionId,
  });

  factory Casier.fromJson(Map<String, dynamic> json) {
    final int casierId = json['cassier_id'] as int? ?? 0;
    final int armoireId = json['armoire_id'] as int? ?? 0;
    final int userId = json['user_id'] as int? ?? 0;
    final int versionId = json['version_id'] as int? ?? 0;

    final DateTime createdAt = DateTime.parse(json['created_at']);
    final DateTime dateModification = DateTime.parse(json['date_modification'] ?? json['created_at']);

    return Casier(
      casierId: casierId,
      armoireId: armoireId,
      nom: json['nom'] as String? ?? '',
      description: json['sous_titre'] as String? ?? '',
      dateCreation: createdAt,
      dateModification: dateModification,
      isDeleted: json['is_deleted'] as bool? ?? false,
      userId: userId,
      versionId: versionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'casier_id': casierId,
      'armoire_id': armoireId,
      'nom': nom,
      'description': description,
      'date_creation': dateCreation.toIso8601String(),
      'date_modification': dateModification.toIso8601String(),
      'is_deleted': isDeleted,
      'user_id': userId,
      'version_id': versionId,
    };
  }
} 