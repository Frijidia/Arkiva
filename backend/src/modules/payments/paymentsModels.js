import pool from '../../config/database.js';

const createSubscriptionsTable = `
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

`;

const createPaymentsTable = `
  CREATE TABLE IF NOT EXISTS payments (
    payment_id SERIAL PRIMARY KEY,
    entreprise_id INTEGER REFERENCES entreprises(entreprise_id) ON DELETE CASCADE,
    subscription_id INTEGER REFERENCES subscription(subscription_id) ON DELETE CASCADE,
    montant INT NOT NULL,
    armoires_souscrites INT NOT NULL,
    statut VARCHAR(50) NOT NULL, -- succès, échec, en_attente
    reference_transaction VARCHAR(255) UNIQUE,
    date_paiement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
`;

// Exécution de la requête
pool.query(createSubscriptionsTable)
  .then(() => {
    console.log('Table subscription created successfully');
  })
  .catch((err) => {
    console.error('Error setting up subscription table:', err);
  }); 

pool.query(createPaymentsTable)
  .then(() => {
    console.log('Table payments created successfully');
  })
  .catch((err) => {
    console.error('Error setting up payments table:', err);
  });

export default pool;
