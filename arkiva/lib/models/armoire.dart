import 'package:arkiva/models/casier.dart';

class Armoire {
  final String id;
  final String nom;
  final String description;
  final DateTime dateCreation;
  final List<Casier> casiers;
  final int nombreCasiers;

  Armoire({
    required this.id,
    required this.nom,
    this.description = '',
    required this.dateCreation,
    List<Casier>? casiers,
    this.nombreCasiers = 10,
  }) : casiers = casiers ?? List.generate(
          nombreCasiers,
          (index) => Casier(
            id: 'C${index + 1}',
            nom: 'Casier ${index + 1}',
            armoireId: id,
            dateCreation: DateTime.now(),
          ),
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'dateCreation': dateCreation.toIso8601String(),
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
      casiers: (json['casiers'] as List)
          .map((c) => Casier.fromJson(c))
          .toList(),
      nombreCasiers: json['nombreCasiers'],
    );
  }
} 