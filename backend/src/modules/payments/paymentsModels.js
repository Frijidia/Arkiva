import pool from '../../config/database.js';

const createSubscriptionsTable = `
CREATE TABLE IF NOT EXISTS subscription (
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
`;

const createPaymentsTable = `
  CREATE TABLE IF NOT EXISTS payments (
    payment_id SERIAL PRIMARY KEY,
    entreprise_id INTEGER REFERENCES entreprises(entreprise_id) ON DELETE CASCADE,
    subscription_id INTEGER REFERENCES subscription(subscription_id) ON DELETE CASCADE,
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
`;

const createInvoicesTable = `
  CREATE TABLE IF NOT EXISTS invoices (
    invoice_id SERIAL PRIMARY KEY,
    payment_id INTEGER REFERENCES payments(payment_id) ON DELETE CASCADE,
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
    payment_id INTEGER REFERENCES payments(payment_id) ON DELETE CASCADE,
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

// Exécution des requêtes
const initializeTables = async () => {
  try {
    // Créer les tables
    await pool.query(createSubscriptionsTable);
    console.log('Table subscription created successfully');
    
    await pool.query(createPaymentsTable);
    console.log('Table payments created successfully');
    
    await pool.query(createInvoicesTable);
    console.log('Table invoices created successfully');
    
    await pool.query(createSubscriptionHistoryTable);
    console.log('Table subscription_history created successfully');
    
    // Insérer les abonnements par défaut
    await pool.query(insertDefaultSubscriptions);
    console.log('Default subscriptions inserted successfully');
    
    // Créer la fonction et le trigger
    await pool.query(updateEntrepriseExpiration);
    await pool.query(createExpirationTrigger);
    console.log('Expiration trigger created successfully');
    
  } catch (err) {
    console.error('Error setting up payment tables:', err);
  }
};

initializeTables();

export default pool;
