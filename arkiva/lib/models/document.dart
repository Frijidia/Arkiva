class Document {
  final String id;
  final String nom;
  final String? description;
  final String type;
  final String chemin;
  final int? taille;
  final DateTime dateCreation;
  final DateTime dateModification;
  final List<Map<String, dynamic>> tags;
  final bool estChiffre;
  final DateTime dateAjout;
  final String? contenuOcr;
  final String? nomOriginal;

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
    List<Map<String, dynamic>>? tags,
    this.estChiffre = false,
    this.contenuOcr,
    this.nomOriginal,
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
      'contenu_ocr': contenuOcr,
      'nom_original': nomOriginal,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    final contenuOcr = json['contenu_ocr'] as String? ?? json['contenuOcr'] as String?;
    return Document(
      id: json['fichier_id'].toString(),
      nom: json['nom'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      chemin: json['chemin'] as String,
      taille: json['taille'] as int?,
      dateCreation: DateTime.parse(json['created_at'] as String),
      dateModification: DateTime.parse(json['created_at'] as String),
      dateAjout: DateTime.parse(json['created_at'] as String),
      tags: (json['tags'] as List?)?.map((t) => Map<String, dynamic>.from(t)).toList() ?? [],
      estChiffre: json['est_chiffre'] as bool? ?? false,
      contenuOcr: contenuOcr,
      nomOriginal: json['originalfilename'] as String?,
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
    List<Map<String, dynamic>>? tags,
    bool? estChiffre,
    DateTime? dateAjout,
    String? contenuOcr,
    String? nomOriginal,
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
      contenuOcr: contenuOcr ?? this.contenuOcr,
      nomOriginal: nomOriginal ?? this.nomOriginal,
    );
  }
} 