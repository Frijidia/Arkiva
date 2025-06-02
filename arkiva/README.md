# ARKIVA - Application de Gestion Documentaire

ARKIVA est une application Flutter moderne pour la gestion et l'archivage de documents, offrant des fonctionnalités de numérisation, de stockage sécurisé et de recherche avancée.

## Architecture de l'Application

### Modèles (`lib/models/`)

- **`armoire.dart`** : Modèle représentant une armoire de stockage
  - Propriétés : id, nom, description, dateCréation, dateModification, casiers
  - Méthodes : toJson, fromJson, copyWith

- **`casier.dart`** : Modèle représentant un casier dans une armoire
  - Propriétés : id, nom, description, dateCréation, dateModification, documents
  - Méthodes : toJson, fromJson, copyWith

- **`document.dart`** : Modèle représentant un document
  - Propriétés : id, nom, chemin, type, taille, dates, tags, métadonnées
  - Méthodes : toJson, fromJson, copyWith

### Services (`lib/services/`)

- **`animation_service.dart`** : Gestion des animations
  - Transitions de page (fade, slide)
  - Animations de boutons (scale)
  - Animations de notifications (bounce)
  - Animations de chargement
  - Animations de listes et cartes

- **`theme_service.dart`** : Gestion du thème de l'application
  - Support thème clair/sombre
  - Persistance des préférences
  - Configuration Material 3
  - Styles cohérents (cartes, boutons, champs)

- **`encryption_service.dart`** : Sécurité des documents
  - Chiffrement AES des fichiers
  - Gestion des clés sécurisée
  - Hachage SHA-256
  - Vérification d'intégrité

- **`logging_service.dart`** : Journalisation des actions
  - Niveaux de log (info, warning, error, security)
  - Stockage JSON
  - Rotation automatique
  - Filtrage par date/niveau/utilisateur

- **`backup_service.dart`** : Gestion des sauvegardes
  - Sauvegardes chiffrées automatiques
  - Limitation du nombre de sauvegardes
  - Restauration
  - Nettoyage automatique

- **`image_processing_service.dart`** : Traitement des images
  - Détection de bords
  - Correction de perspective
  - Amélioration de qualité
  - Reconnaissance de texte

### Écrans (`lib/screens/`)

- **`splash_screen.dart`** : Écran de démarrage animé
  - Animation de l'icône (fade + scale)
  - Animation du titre (slide + fade)
  - Animation du sous-titre (fade)
  - Transition fluide vers l'écran d'accueil
  - Durée totale : 3 secondes

- **`home_screen.dart`** : Écran d'accueil
  - Navigation vers scan/upload
  - Animations d'interface
  - Design moderne

- **`scan_screen.dart`** : Numérisation de documents
  - Prévisualisation caméra
  - Détection automatique
  - Traitement d'image
  - Sauvegarde sécurisée

- **`upload_screen.dart`** : Téléversement de fichiers
  - Sélection de fichiers
  - Prévisualisation
  - Métadonnées
  - Chiffrement

- **`armoires_screen.dart`** : Gestion des armoires
  - Liste des armoires
  - Création/Modification
  - Navigation vers casiers

- **`casiers_screen.dart`** : Gestion des casiers
  - Liste des casiers
  - Création/Modification
  - Navigation vers documents

- **`documents_screen.dart`** : Gestion des documents
  - Liste des documents
  - Recherche avancée
  - Filtres par tags
  - Actions (renommer, supprimer)

## Fonctionnalités Principales

1. **Numérisation Intelligente**
   - Détection automatique des bords
   - Correction de perspective
   - Amélioration de qualité
   - OCR intégré

2. **Sécurité Avancée**
   - Chiffrement AES des documents
   - Journalisation des actions
   - Sauvegardes automatiques
   - Vérification d'intégrité

3. **Interface Moderne**
   - Design Material 3
   - Animations fluides
   - Thème clair/sombre
   - Responsive design
   - Écran de démarrage animé

4. **Organisation Flexible**
   - Structure armoire/casier/document
   - Tags et métadonnées
   - Recherche avancée
   - Filtres multiples

## Dépendances Principales

- `flutter`: Framework UI
- `provider`: Gestion d'état
- `google_mlkit_text_recognition`: OCR
- `camera`: Accès caméra
- `encrypt`: Chiffrement
- `shared_preferences`: Stockage local
- `google_fonts`: Polices
- `image`: Traitement d'image

## Installation

1. Cloner le repository
2. Exécuter `flutter pub get`
3. Lancer l'application avec `flutter run`

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Signaler des bugs
- Proposer des améliorations
- Soumettre des pull requests
