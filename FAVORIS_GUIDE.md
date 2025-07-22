# Guide d'utilisation des Favoris - Arkiva

## 🎯 Fonctionnalités implémentées

### 1. **Ajout/Retrait de favoris**
- **Bouton favoris visible** : Chaque document affiche maintenant un bouton cœur à côté du menu d'actions
- **Menu d'actions** : Option "Ajouter/Retirer des favoris" dans le menu à trois points
- **État dynamique** : Le bouton change d'apparence selon l'état favori (cœur plein/vide)

### 2. **Écran des favoris**
- **Accès** : Bouton "Documents favoris" sur la page d'accueil
- **Recherche** : Barre de recherche pour filtrer les favoris
- **Filtres avancés** : Par type de document et période d'ajout
- **Actions complètes** : Afficher, télécharger, modifier, supprimer, assigner des tags

### 3. **Backend**
- **Routes API** : `/api/favoris` pour gérer les favoris
- **Base de données** : Table `favoris` avec clés étrangères
- **Sécurité** : Vérification des permissions utilisateur

## 🚀 Comment utiliser

### Ajouter un document aux favoris
1. Naviguez vers un dossier contenant des documents
2. Cliquez sur le bouton cœur à côté d'un document
3. Ou utilisez le menu à trois points → "Ajouter aux favoris"

### Consulter vos favoris
1. Sur la page d'accueil, cliquez sur "Documents favoris"
2. Utilisez la barre de recherche pour filtrer
3. Utilisez les filtres avancés pour affiner les résultats

### Retirer un document des favoris
1. Dans l'écran des favoris, cliquez sur le bouton cœur
2. Ou dans l'écran des documents, utilisez le menu → "Retirer des favoris"

## 🔧 Structure technique

### Frontend (Flutter)
- **Service** : `FavorisService` pour les appels API
- **Widget** : `FavoriButton` pour l'interface utilisateur
- **Écrans** : `FavorisScreen` pour l'affichage des favoris
- **Intégration** : Bouton dans `HomeScreen` et `FichiersScreen`

### Backend (Node.js)
- **Routes** : `favorisRoutes.js` avec les endpoints CRUD
- **Contrôleurs** : `favorisControllers.js` pour la logique métier
- **Modèle** : `favorisModels.js` pour la structure de base de données

### Base de données
```sql
CREATE TABLE favoris (
  user_id INTEGER NOT NULL,
  fichier_id INTEGER NOT NULL,
  entreprise_id INTEGER NOT NULL,
  PRIMARY KEY (user_id, fichier_id, entreprise_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (fichier_id) REFERENCES fichiers(fichier_id),
  FOREIGN KEY (entreprise_id) REFERENCES entreprises(entreprise_id)
);
```

## 📱 Interface utilisateur

### Bouton favoris
- **Cœur vide** : Document non favori
- **Cœur plein rouge** : Document en favori
- **Indicateur de chargement** : Pendant les opérations

### Écran favoris
- **Liste des documents** : Affichage avec icônes et descriptions
- **Recherche** : Filtrage en temps réel
- **Filtres** : Type de document et période
- **Actions** : Menu contextuel pour chaque document

## 🔒 Sécurité
- Vérification du token d'authentification
- Validation des permissions utilisateur
- Protection contre les doublons (clé primaire composite)
- Gestion des erreurs avec messages utilisateur

## 🎨 Design
- **Cohérence** : Utilise le design system Material 3
- **Accessibilité** : Tooltips et labels appropriés
- **Responsive** : Adapté aux différentes tailles d'écran
- **Animations** : Transitions fluides et feedback visuel

## 🚀 Prochaines améliorations possibles
- Synchronisation en temps réel
- Notifications pour nouveaux favoris
- Partage de favoris entre utilisateurs
- Export/import de listes de favoris
- Statistiques d'utilisation des favoris 