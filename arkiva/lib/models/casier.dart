import 'package:arkiva/models/document.dart';
import 'package:arkiva/models/dossier.dart';

class Casier {
  final String id;
  final String nom;
  final String description;
  final String armoireId;
  final DateTime dateCreation;
  final DateTime dateModification;
  final List<Dossier> dossiers;

  Casier({
    required this.id,
    required this.nom,
    this.description = '',
    required this.armoireId,
    required this.dateCreation,
    required this.dateModification,
    this.dossiers = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'armoireId': armoireId,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
      'dossiers': dossiers.map((d) => d.toJson()).toList(),
    };
  }

  factory Casier.fromJson(Map<String, dynamic> json) {
    return Casier(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      armoireId: json['armoireId'],
      dateCreation: DateTime.parse(json['dateCreation']),
      dateModification: DateTime.parse(json['dateModification']),
      dossiers: (json['dossiers'] as List?)
          ?.map((d) => Dossier.fromJson(d))
          .toList() ?? [],
    );
  }
} 