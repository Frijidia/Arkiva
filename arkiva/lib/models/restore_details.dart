import 'restore.dart';

class RestoreDetails {
  final Restore restore;
  final Map<String, dynamic> sourceDetails;
  final Map<String, dynamic> metadata;

  RestoreDetails({
    required this.restore,
    required this.sourceDetails,
    required this.metadata,
  });

  factory RestoreDetails.fromJson(Map<String, dynamic> json) {
    return RestoreDetails(
      restore: Restore.fromJson(json['restore'] ?? {}),
      sourceDetails: json['source_details'] != null 
          ? Map<String, dynamic>.from(json['source_details']) 
          : <String, dynamic>{},
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restore': restore.toJson(),
      'source_details': sourceDetails,
      'metadata': metadata,
    };
  }

  String get sourceType {
    return sourceDetails['type'] ?? 'Inconnu';
  }

  Map<String, dynamic>? get sourceData {
    return sourceDetails['data'] != null 
        ? Map<String, dynamic>.from(sourceDetails['data']) 
        : null;
  }

  String get sourceName {
    final data = sourceData;
    if (data != null) {
      return data['nom'] ?? data['name'] ?? 'Source inconnue';
    }
    return 'Source inconnue';
  }

  String get sourceSize {
    final data = sourceData;
    if (data != null) {
      final size = data['taille'] ?? data['size'];
      if (size != null) {
        if (size < 1024) return '$size B';
        if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
        if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
        return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
      }
    }
    return 'Taille inconnue';
  }

  DateTime? get sourceDate {
    final data = sourceData;
    if (data != null) {
      final dateStr = data['created_at'] ?? data['date_creation'];
      if (dateStr != null) {
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  String get sourceDateFormatted {
    final date = sourceDate;
    if (date == null) return 'Date inconnue';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get restoredElementName {
    final restoredMetadata = metadata['restored_metadata'];
    if (restoredMetadata != null && restoredMetadata['name'] != null) {
      return restoredMetadata['name'];
    }
    return restore.restoredElementName;
  }

  String get restoredElementId {
    final restoredMetadata = metadata['restored_metadata'];
    if (restoredMetadata != null && restoredMetadata['id'] != null) {
      return restoredMetadata['id'].toString();
    }
    return restore.cibleId.toString();
  }

  DateTime? get restorationDate {
    final restorationDetails = metadata['restoration_details'];
    if (restorationDetails != null) {
      final dateStr = restorationDetails['restoration_date'];
      if (dateStr != null) {
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          return null;
        }
      }
    }
    return restore.createdAt;
  }

  String get restorationDateFormatted {
    final date = restorationDate;
    if (date == null) return 'Date inconnue';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get userId {
    final restorationDetails = metadata['restoration_details'];
    if (restorationDetails != null && restorationDetails['user_id'] != null) {
      return restorationDetails['user_id'].toString();
    }
    return restore.declencheParId.toString();
  }
} 