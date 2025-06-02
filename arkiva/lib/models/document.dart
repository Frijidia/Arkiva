class Document {
  final String id;
  final String nom;
  final String? description;
  final String type;
  final String chemin;
  final DateTime dateCreation;
  final DateTime dateModification;
  final List<String> tags;
  final bool estChiffre;

  Document({
    required this.id,
    required this.nom,
    this.description,
    required this.type,
    required this.chemin,
    required this.dateCreation,
    required this.dateModification,
    List<String>? tags,
    this.estChiffre = false,
  }) : tags = tags ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'type': type,
      'chemin': chemin,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
      'tags': tags,
      'estChiffre': estChiffre,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      type: json['type'],
      chemin: json['chemin'],
      dateCreation: DateTime.parse(json['dateCreation']),
      dateModification: DateTime.parse(json['dateModification']),
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      estChiffre: json['estChiffre'] ?? false,
    );
  }

  Document copyWith({
    String? id,
    String? nom,
    String? description,
    String? type,
    String? chemin,
    DateTime? dateCreation,
    DateTime? dateModification,
    List<String>? tags,
    bool? estChiffre,
  }) {
    return Document(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      type: type ?? this.type,
      chemin: chemin ?? this.chemin,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      tags: tags ?? this.tags,
      estChiffre: estChiffre ?? this.estChiffre,
    );
  }
} 