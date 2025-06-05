import 'package:arkiva/models/casier.dart';

class Armoire {
  final int armoireId;
  final int userId;
  final String sousTitre;
  final String nom;
  final bool isDeleted;
  final DateTime createdAt;
  final int entrepriseId;
  final int versionId;

  Armoire({
    required this.armoireId,
    required this.userId,
    required this.sousTitre,
    required this.nom,
    required this.isDeleted,
    required this.createdAt,
    required this.entrepriseId,
    required this.versionId,
  });

  factory Armoire.fromJson(Map<String, dynamic> json) {
    return Armoire(
      armoireId: json['armoire_id'],
      userId: json['user_id'],
      sousTitre: json['sous_titre'] ?? '',
      nom: json['nom'],
      isDeleted: json['is_deleted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      entrepriseId: json['entreprise_id'],
      versionId: json['version_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'armoire_id': armoireId,
      'user_id': userId,
      'sous_titre': sousTitre,
      'nom': nom,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'entreprise_id': entrepriseId,
      'version_id': versionId,
    };
  }
} 