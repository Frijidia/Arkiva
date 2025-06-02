import 'package:arkiva/models/casier.dart';

class Armoire {
  final String id;
  final String nom;
  final String description;
  final DateTime dateCreation;
  final DateTime dateModification;
  final List<Casier> casiers;

  Armoire({
    required this.id,
    required this.nom,
    this.description = '',
    required this.dateCreation,
    required this.dateModification,
    List<Casier>? casiers,
  }) : casiers = casiers ?? [];

  int get nombreCasiers => casiers.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
      'casiers': casiers.map((c) => c.toJson()).toList(),
      'nombreCasiers': nombreCasiers,
    };
  }

  factory Armoire.fromJson(Map<String, dynamic> json) {
    return Armoire(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      dateCreation: DateTime.parse(json['dateCreation']),
      dateModification: DateTime.parse(json['dateModification']),
      casiers: (json['casiers'] as List)
          .map((c) => Casier.fromJson(c))
          .toList(),
    );
  }
} 