class Restore {
  final String id;
  final int? backupId;
  final String? versionId;
  final String type;
  final int cibleId;
  final int? entrepriseId;
  final int declencheParId;
  final Map<String, dynamic> metadataJson;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Restore({
    required this.id,
    this.backupId,
    this.versionId,
    required this.type,
    required this.cibleId,
    this.entrepriseId,
    required this.declencheParId,
    required this.metadataJson,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Restore.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    return Restore(
      id: json['id']?.toString() ?? '',
      backupId: parseInt(json['backup_id']),
      versionId: json['version_id']?.toString(),
      type: json['type']?.toString() ?? '',
      cibleId: parseInt(json['cible_id']) ?? 0,
      entrepriseId: parseInt(json['entreprise_id']),
      declencheParId: parseInt(json['declenche_par_id']) ?? 0,
      metadataJson: json['metadata_json'] != null 
          ? Map<String, dynamic>.from(json['metadata_json']) 
          : <String, dynamic>{},
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']),
      deletedAt: parseDateTime(json['deleted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backup_id': backupId,
      'version_id': versionId,
      'type': type,
      'cible_id': cibleId,
      'entreprise_id': entrepriseId,
      'declenche_par_id': declencheParId,
      'metadata_json': metadataJson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
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

  String get sourceType {
    if (backupId != null) return 'Sauvegarde';
    if (versionId != null) return 'Version';
    return 'Inconnu';
  }

  String get sourceId {
    if (backupId != null) return backupId.toString();
    if (versionId != null) return versionId!;
    return 'N/A';
  }

  String get restoredElementName {
    final restoredMetadata = metadataJson['restored_metadata'];
    if (restoredMetadata != null && restoredMetadata['name'] != null) {
      return restoredMetadata['name'];
    }
    return 'Élément restauré';
  }

  String get sourceElementName {
    final sourceMetadata = metadataJson['source_metadata'];
    if (sourceMetadata != null && sourceMetadata['name'] != null) {
      return sourceMetadata['name'];
    }
    return 'Source inconnue';
  }

  DateTime? get originalDate {
    final restorationDetails = metadataJson['restoration_details'];
    if (restorationDetails != null) {
      final originalBackupDate = restorationDetails['original_backup_date'];
      final originalVersionDate = restorationDetails['original_version_date'];
      if (originalBackupDate != null) {
        try {
          return DateTime.parse(originalBackupDate);
        } catch (e) {
          return null;
        }
      }
      if (originalVersionDate != null) {
        try {
          return DateTime.parse(originalVersionDate);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  String get originalDateFormatted {
    final date = originalDate;
    if (date == null) return 'Date inconnue';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool get isFromBackup => backupId != null;
  bool get isFromVersion => versionId != null;
} 