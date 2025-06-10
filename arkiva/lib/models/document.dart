class Document {
  final String id;
  final String nom;
  final String? description;
  final String type;
  final String chemin;
  final int? taille;
  final DateTime dateCreation;
  final DateTime dateModification;
  final List<String> tags;
  final bool estChiffre;
  final DateTime dateAjout;

  Document({
    required this.id,
    required this.nom,
    this.description,
    required this.type,
    required this.chemin,
    this.taille,
    required this.dateCreation,
    required this.dateModification,
    required this.dateAjout,
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
      'taille': taille,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
      'dateAjout': dateAjout.toIso8601String(),
      'tags': tags,
      'estChiffre': estChiffre,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      chemin: json['chemin'] as String,
      taille: json['taille'] as int? ?? 0,
      dateCreation: DateTime.parse(json['dateCreation'] as String),
      dateModification: DateTime.parse(json['dateModification'] as String),
      dateAjout: DateTime.parse(json['dateAjout'] as String),
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      estChiffre: json['estChiffre'] as bool? ?? false,
    );
  }

  Document copyWith({
    String? id,
    String? nom,
    String? description,
    String? type,
    String? chemin,
    int? taille,
    DateTime? dateCreation,
    DateTime? dateModification,
    List<String>? tags,
    bool? estChiffre,
    DateTime? dateAjout,
  }) {
    return Document(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      type: type ?? this.type,
      chemin: chemin ?? this.chemin,
      taille: taille ?? this.taille,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      dateAjout: dateAjout ?? this.dateAjout,
      tags: tags ?? this.tags,
      estChiffre: estChiffre ?? this.estChiffre,
    );
  }
} 