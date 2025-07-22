# Guide Frontend - Module de Restauration

## 🎯 Vue d'ensemble

Le module de restauration permet aux utilisateurs de restaurer des sauvegardes et des versions via l'interface Flutter.

## 📋 Fonctionnalités à implémenter

### **1. Service de Restauration (`restore_service.dart`)**

```dart
class RestoreService {
  // Restaurer une sauvegarde
  Future<Map<String, dynamic>> restoreBackup(int backupId);
  
  // Restaurer une version
  Future<Map<String, dynamic>> restoreVersion(String versionId);
  
  // Obtenir toutes les restaurations
  Future<List<Map<String, dynamic>>> getAllRestores();
  
  // Obtenir les détails d'une restauration
  Future<Map<String, dynamic>> getRestoreDetails(String restoreId);
  
  // Obtenir les restaurations par type
  Future<List<Map<String, dynamic>>> getRestoresByType(String type);
  
  // Obtenir les restaurations par entreprise
  Future<List<Map<String, dynamic>>> getRestoresByEntreprise(int entrepriseId);
}
```

### **2. Modèles de données**

```dart
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
}

class RestoreDetails {
  final Restore restore;
  final Map<String, dynamic> sourceDetails;
  final Map<String, dynamic> metadata;
}
```

### **3. Écrans à créer**

#### **A. Écran principal de restauration**
- Liste des restaurations récentes
- Boutons pour restaurer sauvegarde/version
- Filtres par type

#### **B. Écran de détails de restauration**
- Informations complètes sur la restauration
- Métadonnées de la source (backup/version)
- Comparaison avant/après

#### **C. Écran de sélection de source**
- Liste des sauvegardes disponibles
- Liste des versions disponibles
- Prévisualisation du contenu

## 🔧 Intégration avec les modules existants

### **1. Intégration avec Sauvegardes**
```dart
// Dans backup_screen.dart
ElevatedButton(
  onPressed: () => _showRestoreBackupDialog(backup),
  child: Text('Restaurer cette sauvegarde'),
)
```

### **2. Intégration avec Versions**
```dart
// Dans version_history_screen.dart
ElevatedButton(
  onPressed: () => _showRestoreVersionDialog(version),
  child: Text('Restaurer cette version'),
)
```

### **3. Intégration avec Navigation**
```dart
// Dans main_navigation.dart
ListTile(
  leading: Icon(Icons.restore),
  title: Text('Restaurations'),
  onTap: () => Navigator.pushNamed(context, '/restorations'),
)
```

## 📱 Interface utilisateur

### **1. Écran principal des restaurations**
```
┌─────────────────────────────────┐
│ 🔄 Restaurations               │
├─────────────────────────────────┤
│ 📊 Statistiques                │
│ • 12 restaurations total       │
│ • 8 sauvegardes restaurées     │
│ • 4 versions restaurées        │
├─────────────────────────────────┤
│ 📋 Restaurations récentes      │
│ ┌─────────────────────────────┐ │
│ │ Dossier "Documents"         │ │
│ │ Restauré depuis sauvegarde  │ │
│ │ 2025-07-07 14:46           │ │
│ │ [Voir détails] [Supprimer]  │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Fichier "rapport.pdf"       │ │
│ │ Restauré depuis version     │ │
│ │ 2025-07-07 14:42           │ │
│ │ [Voir détails] [Supprimer]  │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ [Restaurer sauvegarde]         │
│ [Restaurer version]            │
└─────────────────────────────────┘
```

### **2. Dialogue de restauration**
```
┌─────────────────────────────────┐
│ ⚠️ Confirmer la restauration   │
├─────────────────────────────────┤
│ Type: Dossier                  │
│ Nom: "Documents"               │
│ Source: Sauvegarde #2          │
│ Date: 2025-07-04 14:17        │
│                                │
│ ⚠️ Attention: Cette action     │
│    va créer un nouvel élément  │
│    et ne remplacera pas        │
│    l'existant.                 │
├─────────────────────────────────┤
│ [Annuler] [Confirmer]          │
└─────────────────────────────────┘
```

### **3. Écran de détails**
```
┌─────────────────────────────────┐
│ 📋 Détails de la restauration  │
├─────────────────────────────────┤
│ 🔄 Informations générales      │
│ • ID: 00d77a1d-5296-44f8...   │
│ • Type: Dossier                │
│ • Date: 2025-07-07 14:46      │
│ • Utilisateur: Admin           │
├─────────────────────────────────┤
│ 📦 Source (Sauvegarde)         │
│ • ID: 2                        │
│ • Nom: dossier_1               │
│ • Taille: 203 bytes            │
│ • Date: 2025-07-04 14:17      │
├─────────────────────────────────┤
│ ✅ Élément restauré            │
│ • ID: 9                        │
│ • Nom: dossier_1               │
│ • Type: Dossier                │
│ • Date: 2025-07-07 14:46      │
├─────────────────────────────────┤
│ [Voir l'élément] [Supprimer]   │
└─────────────────────────────────┘
```

## 🔌 API Endpoints utilisés

### **1. Restauration**
```dart
// Restaurer une sauvegarde
POST /api/restaurations/backup/{id}

// Restaurer une version
POST /api/restaurations/version/{id}
```

### **2. Consultation**
```dart
// Toutes les restaurations
GET /api/restaurations/

// Détails d'une restauration
GET /api/restaurations/{id}/details

// Par type
GET /api/restaurations/type/{type}

// Par entreprise
GET /api/restaurations/entreprise/{id}
```

### **3. Suppression**
```dart
// Supprimer une restauration
DELETE /api/restaurations/{id}
```

## 🎨 Composants UI à créer

### **1. Widgets réutilisables**
```dart
// RestoreCard - Carte de restauration
class RestoreCard extends StatelessWidget {
  final Restore restore;
  final VoidCallback? onViewDetails;
  final VoidCallback? onDelete;
}

// RestoreDetailsDialog - Dialogue de détails
class RestoreDetailsDialog extends StatelessWidget {
  final RestoreDetails details;
}

// RestoreConfirmationDialog - Dialogue de confirmation
class RestoreConfirmationDialog extends StatelessWidget {
  final String type;
  final String name;
  final String sourceType;
  final String sourceId;
}
```

### **2. Écrans principaux**
```dart
// RestorationsScreen - Écran principal
class RestorationsScreen extends StatefulWidget

// RestoreDetailsScreen - Écran de détails
class RestoreDetailsScreen extends StatelessWidget

// RestoreSelectionScreen - Écran de sélection
class RestoreSelectionScreen extends StatefulWidget
```

## 🔐 Gestion des permissions

### **1. Vérification des rôles**
```dart
// Seuls les admins peuvent restaurer
if (!userService.isAdmin()) {
  showErrorDialog('Permissions insuffisantes');
  return;
}
```

### **2. Confirmation utilisateur**
```dart
// Toujours demander confirmation
bool confirmed = await showConfirmationDialog(
  'Confirmer la restauration',
  'Cette action va créer un nouvel élément. Continuer ?'
);
```

## 📊 Gestion des états

### **1. États de chargement**
```dart
enum RestoreState {
  idle,
  loading,
  success,
  error
}
```

### **2. Gestion des erreurs**
```dart
// Erreurs communes
- 'Sauvegarde non trouvée'
- 'Version non trouvée'
- 'Permissions insuffisantes'
- 'Erreur de réseau'
```

## 🚀 Étapes d'implémentation

### **Phase 1: Service et modèles**
1. Créer `restore_service.dart`
2. Créer les modèles `Restore` et `RestoreDetails`
3. Tester les appels API

### **Phase 2: Interface utilisateur**
1. Créer les widgets réutilisables
2. Créer l'écran principal des restaurations
3. Intégrer dans la navigation

### **Phase 3: Intégration**
1. Ajouter les boutons de restauration dans les écrans existants
2. Créer les dialogues de confirmation
3. Tester l'ensemble du flux

### **Phase 4: Améliorations**
1. Ajouter les filtres et la recherche
2. Améliorer l'interface utilisateur
3. Ajouter les notifications

## 🎯 Points d'attention

### **1. Performance**
- Pagination pour les listes longues
- Cache des données de restauration
- Chargement asynchrone des détails

### **2. UX**
- Feedback visuel pendant la restauration
- Messages d'erreur clairs
- Confirmation avant suppression

### **3. Sécurité**
- Vérification des permissions
- Validation des données
- Logs d'audit

## 📝 Notes importantes

- Les restaurations créent de nouveaux éléments, ne remplacent pas
- Toujours demander confirmation avant restauration
- Afficher clairement la source (backup vs version)
- Permettre de voir les détails complets de chaque restauration
- Intégrer avec le système de notifications existant 