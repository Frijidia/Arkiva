# Système de Paiement Arkiva

## Vue d'ensemble

Le système de paiement Arkiva gère les abonnements mensuels et annuels avec support de paiement mobile et carte bancaire via l'agrégateur FeexPay.

## Fonctionnalités

### 🏷️ Tarification
- **Abonnement Mensuel** : 5.000 FCFA (2 armoires incluses)
- **Abonnement Annuel** : 50.000 FCFA (2 armoires incluses) - Économie de 10.000 FCFA
- **Armoires supplémentaires** : 5.000 FCFA par tranche de 2 armoires

### 💳 Moyens de Paiement
- MTN Mobile Money
- Moov Money  
- Celtiis Cash
- Carte bancaire

### 📧 Facturation
- Génération automatique de factures
- Envoi par email
- Historique des paiements

### 🔒 Gestion des Accès
- Restriction des accès à l'expiration
- Fermeture automatique des casiers
- Blocage des uploads et scans

## Structure de la Base de Données

### Table `subscription`
```sql
CREATE TABLE subscription (
  subscription_id SERIAL PRIMARY KEY,
  nom VARCHAR(255) NOT NULL, -- Mensuel, Annuel
  prix_base INT NOT NULL, -- 5000 ou 50000
  duree INT NOT NULL, -- en jours (30 ou 365)
  armoires_incluses INT DEFAULT 2,
  description TEXT,
  status VARCHAR(20) DEFAULT 'actif',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Table `payments`
```sql
CREATE TABLE payments (
  payment_id SERIAL PRIMARY KEY,
  entreprise_id INTEGER REFERENCES entreprises(entreprise_id),
  subscription_id INTEGER REFERENCES subscription(subscription_id),
  montant INT NOT NULL,
  armoires_souscrites INT NOT NULL,
  statut VARCHAR(50) NOT NULL, -- succès, échec, en_attente, annulé
  reference_transaction VARCHAR(255) UNIQUE,
  moyen_paiement VARCHAR(50), -- MTN_MOBILE_MONEY, MOOV_MONEY, CELTIIS_CASH, CARTE_BANCAIRE
  feexpay_reference VARCHAR(255),
  date_paiement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_expiration TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Table `invoices`
```sql
CREATE TABLE invoices (
  invoice_id SERIAL PRIMARY KEY,
  payment_id INTEGER REFERENCES payments(payment_id),
  entreprise_id INTEGER REFERENCES entreprises(entreprise_id),
  numero_facture VARCHAR(255) UNIQUE NOT NULL,
  montant_ht INT NOT NULL,
  montant_ttc INT NOT NULL,
  tva INT DEFAULT 0,
  statut VARCHAR(50) DEFAULT 'générée',
  date_emission TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_echeance TIMESTAMP,
  email_envoye BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Table `subscription_history`
```sql
CREATE TABLE subscription_history (
  history_id SERIAL PRIMARY KEY,
  entreprise_id INTEGER REFERENCES entreprises(entreprise_id),
  payment_id INTEGER REFERENCES payments(payment_id),
  type_action VARCHAR(50) NOT NULL, -- souscription, renouvellement, expiration, annulation
  ancien_statut VARCHAR(50),
  nouveau_statut VARCHAR(50),
  details JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## API Endpoints

### GET `/api/payments/subscriptions`
Récupère les abonnements disponibles.

**Réponse :**
```json
{
  "subscriptions": [
    {
      "subscription_id": 1,
      "nom": "Mensuel",
      "prix_base": 5000,
      "duree": 30,
      "armoires_incluses": 2,
      "description": "Abonnement mensuel - 2 armoires incluses"
    }
  ]
}
```

### POST `/api/payments/choose-subscription`
Choisit un abonnement et calcule le coût.

**Body :**
```json
{
  "subscription_id": 1,
  "armoires_souscrites": 4
}
```

**Réponse :**
```json
{
  "message": "Abonnement choisi. Paiement en attente.",
  "montant": 10000,
  "armoires": 4,
  "abonnement": "Mensuel",
  "paiement": { ... },
  "date_expiration": "2024-02-20T10:30:00Z"
}
```

### POST `/api/payments/process-payment`
Effectue le paiement via FeexPay.

**Body :**
```json
{
  "payment_id": 123,
  "moyen_paiement": "MTN_MOBILE_MONEY",
  "numero_telephone": "22507012345"
}
```

### GET `/api/payments/current-subscription`
Vérifie le statut de l'abonnement actuel.

**Réponse :**
```json
{
  "entreprise": { ... },
  "isExpired": false,
  "canAccess": true,
  "daysUntilExpiration": 15
}
```

### GET `/api/payments/history`
Récupère l'historique des abonnements.

### POST `/api/payments/webhook`
Webhook FeexPay pour confirmer les paiements.

## Variables d'Environnement

```env
# FeexPay Configuration
FEEXPAY_API_KEY=your_api_key
FEEXPAY_SECRET_KEY=your_secret_key
FEEXPAY_BASE_URL=https://api.feexpay.com
FEEXPAY_WEBHOOK_SECRET=your_webhook_secret

# Email Configuration
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_email_password
EMAIL_FROM=noreply@arkiva.com

# Application URLs
BASE_URL=http://localhost:3000
FRONTEND_URL=http://localhost:3001
```

## Middleware de Vérification

Le système inclut des middlewares pour vérifier les permissions :

```javascript
import { subscriptionMiddleware } from './subscriptionService.js';

// Vérifier l'upload de documents
router.post('/upload', subscriptionMiddleware('upload'), uploadController);

// Vérifier la création d'armoires
router.post('/armoires', subscriptionMiddleware('armoires'), armoireController);

// Vérifier l'accès aux casiers
router.get('/casiers', subscriptionMiddleware('casiers'), casierController);
```

## Gestion des Expirations

### Restrictions à l'Expiration
- ✅ Accès au profil et section abonnement
- ❌ Création de nouvelles armoires
- ❌ Upload de documents
- ❌ Accès aux casiers
- ❌ Scan de documents

### Renouvellement Automatique
Le système calcule automatiquement le coût de renouvellement en fonction du nombre d'armoires actives.

## Intégration FeexPay

### Configuration
1. Créer un compte FeexPay
2. Obtenir les clés API
3. Configurer les webhooks
4. Tester en mode sandbox

### Webhook
Le webhook FeexPay doit pointer vers : `https://votre-domaine.com/api/payments/webhook`

## Tests

```bash
# Tester les calculs de coût
npm test payments/calculateCost

# Tester l'intégration FeexPay
npm test payments/feexpayIntegration

# Tester la génération de factures
npm test payments/invoiceGeneration
```

## Monitoring

### Logs Importants
- Paiements réussis/échoués
- Expirations d'abonnements
- Échecs d'envoi de factures
- Erreurs FeexPay

### Métriques
- Taux de conversion des paiements
- Durée moyenne des abonnements
- Revenus par période
- Moyens de paiement les plus utilisés

## Support

Pour toute question sur le système de paiement, contactez l'équipe technique. 