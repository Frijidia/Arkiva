# Rapport de Stage Académique
## Projet Arkiva

### 1. Introduction
Ce rapport présente le travail réalisé dans le cadre du projet Arkiva, une application de gestion documentaire développée avec Flutter. Le projet vise à créer une solution moderne et efficace pour la gestion des documents numériques avec des fonctionnalités avancées de favoris et de recherche.

### 2. Contexte du Projet
Arkiva est une application multiplateforme développée en Flutter, permettant une gestion optimisée des documents numériques. Le projet s'inscrit dans une démarche d'innovation et de modernisation des processus de gestion documentaire, avec un focus particulier sur l'expérience utilisateur et l'organisation des documents.

### 3. Architecture Technique
#### 3.1 Technologies Utilisées
- **Frontend** : Flutter/Dart avec Material 3
- **Backend** : Node.js avec Express.js
- **Base de données** : PostgreSQL avec Sequelize
- **API** : RESTful avec authentification JWT
- **Environnement de développement** : VS Code

#### 3.2 Structure du Projet
Le projet est organisé selon une architecture modulaire :
- `/arkiva` : Application principale Flutter
- `/backend` : Services backend Node.js
- `/lib` : Bibliothèques et composants partagés
- Support multi-plateformes (Android, iOS, Web, Linux, Windows, macOS)

### 4. Objectifs et Réalisations
#### 4.1 Objectifs Principaux
- Développement d'une application de gestion documentaire moderne
- Création d'une interface utilisateur intuitive et responsive
- Implémentation d'une architecture robuste et évolutive
- Intégration de fonctionnalités avancées (favoris, recherche, tags)

#### 4.2 Réalisations
- Mise en place de l'architecture Flutter avec Material 3
- Développement des composants principaux (armoires, casiers, dossiers, documents)
- Intégration des fonctionnalités de gestion documentaire
- **Nouveau : Système de favoris complet**
  - Bouton favoris visible sur chaque document
  - Écran dédié aux favoris avec recherche et filtres
  - API backend pour la gestion des favoris
  - Widget personnalisé `FavoriButton`
- **Nouveau : Recherche avancée**
  - Recherche par OCR, nom, description, tags
  - Filtres par type de document, période, armoire/casier/dossier
  - Interface de recherche intuitive
- Support multi-plateformes
- Système d'authentification sécurisé
- Gestion des tags et métadonnées

### 5. Compétences Acquises
- Maîtrise du framework Flutter et Dart
- Développement d'applications multiplateformes
- Architecture client-serveur avec Node.js
- Gestion de base de données PostgreSQL
- **Nouveau :** Développement d'APIs RESTful
- **Nouveau :** Gestion d'état avec Provider
- **Nouveau :** Création de widgets personnalisés
- Gestion de projet et travail en équipe
- Architecture logicielle moderne

### 6. Fonctionnalités Implémentées

#### 6.1 Gestion Documentaire de Base
- Création et organisation hiérarchique (Entreprises → Armoires → Casiers → Dossiers → Documents)
- Upload et téléchargement de fichiers
- Numérisation de documents avec caméra
- Chiffrement AES des documents
- Système de tags et métadonnées

#### 6.2 **Nouveau : Système de Favoris**
- **Interface utilisateur :**
  - Bouton cœur visible sur chaque document
  - État dynamique (cœur plein/vide selon l'état favori)
  - Menu d'actions avec option favoris
  - Écran dédié "Documents favoris" accessible depuis l'accueil
- **Fonctionnalités :**
  - Ajout/retrait de documents aux favoris
  - Recherche dans les favoris
  - Filtres par type de document et période
  - Actions complètes (afficher, télécharger, modifier, supprimer)
- **Backend :**
  - API RESTful pour la gestion des favoris
  - Table de base de données avec clés étrangères
  - Sécurité et validation des permissions

#### 6.3 **Nouveau : Recherche Avancée**
- Recherche par OCR (contenu des documents)
- Recherche par nom, description, tags
- Filtres avancés par type, période, localisation
- Interface de recherche intuitive avec suggestions

#### 6.4 Sécurité et Authentification
- Authentification JWT
- Gestion des rôles (admin, utilisateur)
- Chiffrement des documents sensibles
- Journalisation des actions (audit)

### 7. Difficultés Rencontrées et Solutions
- **Adaptation aux différentes plateformes :** Utilisation de Flutter pour la compatibilité
- **Optimisation des performances :** Lazy loading et pagination
- **Gestion de la compatibilité :** Tests sur multiples plateformes
- **Nouveau : Synchronisation des favoris :** API RESTful avec gestion d'état
- **Nouveau : Interface utilisateur responsive :** Material 3 et widgets adaptatifs

### 8. Architecture Technique Détaillée

#### 8.1 Frontend (Flutter)
```
arkiva/lib/
├── models/          # Modèles de données
├── services/        # Services API (DocumentService, FavorisService, etc.)
├── screens/         # Écrans de l'application
├── widgets/         # Widgets personnalisés (FavoriButton, etc.)
└── config/          # Configuration (API, thèmes)
```

#### 8.2 Backend (Node.js)
```
backend/src/
├── modules/         # Modules fonctionnels
│   ├── favoris/     # Gestion des favoris
│   ├── fichiers/    # Gestion des fichiers
│   ├── auth/        # Authentification
│   └── ...
├── config/          # Configuration base de données
└── app.js          # Point d'entrée de l'application
```

### 9. Perspectives d'Évolution
- Amélioration des fonctionnalités existantes
- **Nouveau :** Synchronisation en temps réel des favoris
- **Nouveau :** Notifications pour nouveaux favoris
- **Nouveau :** Partage de favoris entre utilisateurs
- **Nouveau :** Export/import de listes de favoris
- **Nouveau :** Statistiques d'utilisation des favoris
- Optimisation des performances
- Extension de la portée du projet
- Intégration de l'IA pour la classification automatique

### 10. Conclusion
Le projet Arkiva représente une expérience enrichissante dans le domaine du développement d'applications modernes. Il a permis d'acquérir des compétences techniques solides et une meilleure compréhension des enjeux du développement multiplateforme.

**Les nouvelles fonctionnalités de favoris et de recherche avancée ont considérablement amélioré l'expérience utilisateur, transformant Arkiva en une solution complète et moderne de gestion documentaire.**

Le projet démontre la capacité à développer des applications complexes avec une architecture robuste, une interface utilisateur intuitive et des fonctionnalités avancées répondant aux besoins réels des utilisateurs.

### 11. Annexes
- Documentation technique complète
- Guide d'utilisation des favoris
- Captures d'écran de l'application
- Diagrammes d'architecture 
- Code source commenté 
