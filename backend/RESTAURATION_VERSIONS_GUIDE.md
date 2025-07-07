# Guide de Restauration - Sauvegardes et Versions

## 🎯 Vue d'ensemble

Le système de restauration d'Arkiva permet maintenant de restaurer à la fois des **sauvegardes** et des **versions**.

## 📋 API Endpoints

### 🔄 Restauration de Sauvegardes
```http
POST /api/restaurations/backup/:id
```
- **Description** : Restaure une sauvegarde complète
- **Paramètres** : `id` - ID de la sauvegarde
- **Permissions** : Admin requis
- **Retour** : Détails de la restauration

### 📝 Restauration de Versions
```http
POST /api/restaurations/version/:id
```
- **Description** : Restaure une version spécifique
- **Paramètres** : `id` - ID de la version
- **Permissions** : Admin requis
- **Retour** : Détails de la restauration

### 📊 Consultation des Restaurations
```http
GET /api/restaurations/                    # Toutes les restaurations
GET /api/restaurations/:id                 # Restauration par ID
GET /api/restaurations/entreprise/:id      # Par entreprise
GET /api/restaurations/type/:type          # Par type
GET /api/restaurations/version/:id         # Par version
GET /api/restaurations/backup/:id          # Par sauvegarde
```

## 🔧 Fonctionnalités

### ✅ Restauration de Sauvegardes
- **Format** : Archive ZIP compressée
- **Contenu** : Données complètes + métadonnées
- **Types supportés** : fichier, dossier, casier, armoire, système
- **Stockage** : AWS S3

### ✅ Restauration de Versions
- **Format** : Contenu versionné
- **Contenu** : État spécifique d'un élément
- **Types supportés** : fichier, dossier, casier, armoire
- **Stockage** : AWS S3

## 🗄️ Structure de Base de Données

### Table `restores`
```sql
CREATE TABLE restores (
    id UUID PRIMARY KEY,
    backup_id UUID,           -- ID de la sauvegarde (si applicable)
    version_id UUID,          -- ID de la version (si applicable)
    type VARCHAR(50),         -- Type restauré
    cible_id INTEGER,         -- ID de l'élément restauré
    entreprise_id INTEGER,    -- Entreprise concernée
    declenche_par_id INTEGER, -- Utilisateur qui a restauré
    created_at TIMESTAMP,     -- Date de restauration
    updated_at TIMESTAMP,     -- Date de modification
    deleted_at TIMESTAMP      -- Date de suppression (soft delete)
);
```

## 🔐 Sécurité

- **Authentification** : Requise pour toutes les routes
- **Autorisation** : Rôle admin requis
- **Journalisation** : Toutes les actions sont loggées
- **Validation** : Vérification des types et permissions

## 📝 Exemples d'utilisation

### Restaurer une sauvegarde
```javascript
const response = await fetch('/api/restaurations/backup/123', {
    method: 'POST',
    headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json'
    }
});
```

### Restaurer une version
```javascript
const response = await fetch('/api/restaurations/version/456', {
    method: 'POST',
    headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json'
    }
});
```

## 🚀 Prochaines étapes

1. **Interface utilisateur** : Créer les écrans Flutter
2. **Notifications** : Alerter les utilisateurs des restaurations
3. **Validation** : Vérifier les conflits avant restauration
4. **Historique** : Interface pour consulter l'historique des restaurations

## 🔍 Dépannage

### Erreurs communes
- **Version non trouvée** : Vérifier l'ID de la version
- **Sauvegarde non trouvée** : Vérifier l'ID de la sauvegarde
- **Permissions insuffisantes** : Vérifier le rôle admin
- **Erreur S3** : Vérifier la configuration AWS

### Logs utiles
```bash
# Vérifier les restaurations récentes
SELECT * FROM restores ORDER BY created_at DESC LIMIT 10;

# Vérifier les restaurations par type
SELECT type, COUNT(*) FROM restores GROUP BY type;
``` 