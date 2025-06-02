import 'package:arkiva/models/document.dart';

class Casier {
  final String id;
  final String nom;
  final String armoireId;
  final String? description;
  final DateTime dateCreation;
  final List<Document> documents;

  Casier({
    required this.id,
    required this.nom,
    required this.armoireId,
    this.description,
    required this.dateCreation,
    List<Document>? documents,
  }) : documents = documents ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'armoireId': armoireId,
      'description': description,
      'dateCreation': dateCreation.toIso8601String(),
      'documents': documents.map((d) => d.toJson()).toList(),
    };
  }

  factory Casier.fromJson(Map<String, dynamic> json) {
    return Casier(
      id: json['id'],
      nom: json['nom'],
      armoireId: json['armoireId'],
      description: json['description'],
      dateCreation: DateTime.parse(json['dateCreation']),
      documents: (json['documents'] as List?)
          ?.map((d) => Document.fromJson(d))
          .toList() ?? [],
    );
  }
} 