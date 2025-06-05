class Entreprise {
  final String nom;
  final String email;
  final String telephone;
  final String adresse;
  final String logoUrl;
  final String planAbonnement;

  Entreprise({
    required this.nom,
    required this.email,
    required this.telephone,
    required this.adresse,
    required this.logoUrl,
    this.planAbonnement = 'gratuit',
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'logo_url': logoUrl,
      'plan_abonnement': planAbonnement,
    };
  }

  factory Entreprise.fromJson(Map<String, dynamic> json) {
    return Entreprise(
      nom: json['nom'],
      email: json['email'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      logoUrl: json['logo_url'],
      planAbonnement: json['plan_abonnement'],
    );
  }
} 