import 'package:arkiva/models/document.dart';

class Dossier {
  final String id;
  final String nom;
  final String casierId;
  final String? description;
  final DateTime dateCreation;
  final DateTime dateModification;
  final List<Document> documents;

  Dossier({
    required this.id,
    required this.nom,
    required this.casierId,
    this.description,
    required this.dateCreation,
    required this.dateModification,
    List<Document>? documents,
  }) : documents = documents ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'casierId': casierId,
      'description': description,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
      'documents': documents.map((d) => d.toJson()).toList(),
    };
  }

  factory Dossier.fromJson(Map<String, dynamic> json) {
    return Dossier(
      id: json['id'],
      nom: json['nom'],
      casierId: json['casierId'],
      description: json['description'],
      dateCreation: DateTime.parse(json['dateCreation']),
      dateModification: DateTime.parse(json['dateModification']),
      documents: (json['documents'] as List?)
          ?.map((d) => Document.fromJson(d))
          .toList() ?? [],
    );
  }

  Dossier copyWith({
    String? id,
    String? nom,
    String? casierId,
    String? description,
    DateTime? dateCreation,
    DateTime? dateModification,
    List<Document>? documents,
  }) {
    return Dossier(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      casierId: casierId ?? this.casierId,
      description: description ?? this.description,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      documents: documents ?? this.documents,
    );
  }
} 