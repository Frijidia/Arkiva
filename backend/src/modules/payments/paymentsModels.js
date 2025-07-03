import pool from '../../config/database.js';

const createSubscriptionsTable = `
CREATE TABLE IF NOT EXISTS subscription (
  subscription_id SERIAL PRIMARY KEY,
  nom VARCHAR(255) NOT NULL UNIQUE, -- Mensuel, Annuel
  prix_base INT NOT NULL, -- 5000 ou 50000
  duree INT NOT NULL, -- en jours (30 ou 365)
  armoires_incluses INT DEFAULT 2,
  description TEXT,
  status VARCHAR(20) DEFAULT 'actif',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
`;

const createPaymentsTable = `
  CREATE TABLE IF NOT EXISTS payments (
    payment_id VARCHAR(100) PRIMARY KEY,
    entreprise_id INTEGER REFERENCES entreprises(entreprise_id) ON DELETE CASCADE,
    subscription_id INTEGER REFERENCES subscription(subscription_id) ON DELETE CASCADE,
    montant DECIMAL(10,2) NOT NULL,
    armoires_souscrites INTEGER NOT NULL DEFAULT 2,
    statut VARCHAR(20) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'succès', 'échec', 'annulé')),
    moyen_paiement VARCHAR(50),
    numero_telephone VARCHAR(20),
    feexpay_reference VARCHAR(100),
    feexpay_trans_key VARCHAR(15),
    reference_transaction VARCHAR(100),
    custom_id VARCHAR(100),
    date_expiration TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`;

const createInvoicesTable = `
  CREATE TABLE IF NOT EXISTS invoices (
    invoice_id SERIAL PRIMARY KEY,
    payment_id VARCHAR(100) REFERENCES payments(payment_id) ON DELETE CASCADE,
    entreprise_id INTEGER REFERENCES entreprises(entreprise_id) ON DELETE CASCADE,
    numero_facture VARCHAR(255) UNIQUE NOT NULL,
    montant_ht INT NOT NULL,
    montant_ttc INT NOT NULL,
    tva INT DEFAULT 0,
    statut VARCHAR(50) DEFAULT 'générée', -- générée, envoyée, payée
    date_emission TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_echeance TIMESTAMP,
    email_envoye BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`;

const createSubscriptionHistoryTable = `
  CREATE TABLE IF NOT EXISTS subscription_history (
    history_id SERIAL PRIMARY KEY,
    entreprise_id INTEGER REFERENCES entreprises(entreprise_id) ON DELETE CASCADE,
    payment_id VARCHAR(100) REFERENCES payments(payment_id) ON DELETE CASCADE,
    type_action VARCHAR(50) NOT NULL, -- souscription, renouvellement, expiration, annulation
    ancien_statut VARCHAR(50),
    nouveau_statut VARCHAR(50),
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`;

// Insertion des abonnements par défaut
const insertDefaultSubscriptions = `
  INSERT INTO subscription (nom, prix_base, duree, armoires_incluses, description) 
  VALUES 
    ('Mensuel', 5000, 30, 2, 'Abonnement mensuel - 2 armoires incluses'),
    ('Annuel', 50000, 365, 2, 'Abonnement annuel - 2 armoires incluses - Économisez 10.000 FCFA')
  ON CONFLICT DO NOTHING;
`;

// Fonction pour mettre à jour la date d'expiration de l'entreprise
const updateEntrepriseExpiration = `
  CREATE OR REPLACE FUNCTION update_entreprise_expiration()
  RETURNS TRIGGER AS $$
  BEGIN
    -- Mettre à jour la date d'expiration de l'entreprise
    UPDATE entreprises 
    SET date_expiration = NEW.date_expiration,
        armoire_limit = NEW.armoires_souscrites
    WHERE entreprise_id = NEW.entreprise_id;
    
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;
`;

// Trigger pour mettre à jour automatiquement l'expiration
const createExpirationTrigger = `
  DROP TRIGGER IF EXISTS trigger_update_expiration ON payments;
  CREATE TRIGGER trigger_update_expiration
    AFTER INSERT OR UPDATE ON payments
    FOR EACH ROW
    WHEN (NEW.statut = 'succès')
    EXECUTE FUNCTION update_entreprise_expiration();
`;

// Exécution des requêtes dans l'ordre
pool.query(createSubscriptionsTable)
  .then(() => {
    console.log('Table subscription created successfully');
    return pool.query(createPaymentsTable);
  })
  .then(() => {
    console.log('Table payments created successfully');
    return pool.query(createInvoicesTable);
  })
  .then(() => {
    console.log('Table invoices created successfully');
    return pool.query(createSubscriptionHistoryTable);
  })
  .then(() => {
    console.log('Table subscription_history created successfully');
    return pool.query(updateEntrepriseExpiration);
  })
  .then(() => {
    console.log('Function update_entreprise_expiration created successfully');
    return pool.query(createExpirationTrigger);
  })
  .then(() => {
    console.log('Trigger trigger_update_expiration created successfully');
    return pool.query(insertDefaultSubscriptions);
  })
  .then(() => {
    console.log('Default subscriptions inserted successfully');
  })
  .catch((err) => console.error('Error setting up payments tables:', err));

export default pool;
