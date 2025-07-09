class Version {
  final String id;
  final int cibleId;
  final String type;
  final String versionNumber;
  final String? description;
  final DateTime dateCreation;
  final String? storagePath;
  final Map<String, dynamic>? metadata;
  final int? declencheParId;

  Version({
    required this.id,
    required this.cibleId,
    required this.type,
    required this.versionNumber,
    this.description,
    required this.dateCreation,
    this.storagePath,
    this.metadata,
    this.declencheParId,
  });

  factory Version.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
    // Correction : on va chercher description et version_number dans metadata si besoin
    final metadata = json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null;
    return Version(
      id: json['id']?.toString() ?? '',
      cibleId: parseInt(json['cible_id'])!,
      type: json['type']?.toString() ?? '',
      versionNumber: (json['version_number']?.toString() ?? metadata?['version_number']?.toString() ?? ''),
      description: json['description']?.toString() ?? metadata?['description']?.toString(),
      dateCreation: DateTime.parse(json['created_at'] ?? json['date_creation']),
      storagePath: json['storage_path']?.toString(),
      metadata: metadata,
      declencheParId: parseInt(json['created_by'] ?? json['declenche_par_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cible_id': cibleId,
      'type': type,
      'version_number': versionNumber,
      'description': description,
      'date_creation': dateCreation.toIso8601String(),
      'storage_path': storagePath,
      'metadata': metadata,
      'declenche_par_id': declencheParId,
    };
  }

  String get formattedDate {
    return '${dateCreation.day.toString().padLeft(2, '0')}/${dateCreation.month.toString().padLeft(2, '0')}/${dateCreation.year} ${dateCreation.hour.toString().padLeft(2, '0')}:${dateCreation.minute.toString().padLeft(2, '0')}';
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
      default:
        return type;
    }
  }

  String get s3Location {
    return metadata?['s3Location'] ?? storagePath ?? '';
  }

  String get formattedSize {
    final size = metadata?['s3Size'];
    if (size == null) return 'Taille inconnue';
    
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 