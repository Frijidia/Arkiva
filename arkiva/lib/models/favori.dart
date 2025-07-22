class Favori {
  final int userId;
  final int fichierId;
  final int entrepriseId;
  final DateTime dateAjout;

  Favori({
    required this.userId,
    required this.fichierId,
    required this.entrepriseId,
    required this.dateAjout,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'fichier_id': fichierId,
      'entreprise_id': entrepriseId,
      'date_ajout': dateAjout.toIso8601String(),
    };
  }

  factory Favori.fromJson(Map<String, dynamic> json) {
    return Favori(
      userId: json['user_id'] as int,
      fichierId: json['fichier_id'] as int,
      entrepriseId: json['entreprise_id'] as int,
      dateAjout: DateTime.parse(json['date_ajout'] as String),
    );
  }

  Favori copyWith({
    int? userId,
    int? fichierId,
    int? entrepriseId,
    DateTime? dateAjout,
  }) {
    return Favori(
      userId: userId ?? this.userId,
      fichierId: fichierId ?? this.fichierId,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Favori &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          fichierId == other.fichierId &&
          entrepriseId == other.entrepriseId;

  @override
  int get hashCode => userId.hashCode ^ fichierId.hashCode ^ entrepriseId.hashCode;
} 