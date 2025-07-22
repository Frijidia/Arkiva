class Backup {
  final int id;
  final String type;
  final int? cibleId;
  final int? entrepriseId;
  final String? cheminSauvegarde;
  final Map<String, dynamic>? contenuJson;
  final int? declencheParId;
  final DateTime dateCreation;
  final String? storagePath;
  final String? s3Key;
  final int? s3Size;

  Backup({
    required this.id,
    required this.type,
    this.cibleId,
    this.entrepriseId,
    this.cheminSauvegarde,
    this.contenuJson,
    this.declencheParId,
    required this.dateCreation,
    this.storagePath,
    this.s3Key,
    this.s3Size,
  });

  factory Backup.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
    return Backup(
      id: parseInt(json['id'])!,
      type: json['type'],
      cibleId: parseInt(json['cible_id']),
      entrepriseId: parseInt(json['entreprise_id']),
      cheminSauvegarde: json['chemin_sauvegarde'],
      contenuJson: json['contenu_json'] != null 
          ? Map<String, dynamic>.from(json['contenu_json'])
          : null,
      declencheParId: parseInt(json['declenche_par_id']),
      dateCreation: DateTime.parse(json['date_creation']),
      storagePath: json['storage_path'],
      s3Key: json['s3_key'],
      s3Size: parseInt(json['s3_size']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'cible_id': cibleId,
      'entreprise_id': entrepriseId,
      'chemin_sauvegarde': cheminSauvegarde,
      'contenu_json': contenuJson,
      'declenche_par_id': declencheParId,
      'date_creation': dateCreation.toIso8601String(),
      'storage_path': storagePath,
      's3_key': s3Key,
      's3_size': s3Size,
    };
  }

  String get s3Location {
    return contenuJson?['s3Location'] ?? cheminSauvegarde ?? '';
  }

  String get formattedDate {
    return '${dateCreation.day.toString().padLeft(2, '0')}/${dateCreation.month.toString().padLeft(2, '0')}/${dateCreation.year} - ${dateCreation.hour.toString().padLeft(2, '0')}:${dateCreation.minute.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (s3Size == null) return 'Taille inconnue';
    
    final size = s3Size!;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get typeDisplay {
    switch (type) {
      case 'fichier':
        return 'Fichier';
      case 'dossier':
        return 'Dossier';
      case 'casier':
        return 'Casier';
      case 'armoire':
        return 'Armoire';
      case 'système':
        return 'Système';
      default:
        return type;
    }
  }
} 