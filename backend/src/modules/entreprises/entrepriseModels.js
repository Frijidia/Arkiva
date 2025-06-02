import pool from '../../config/database.js';

// Création de la table entreprises
const createEntreprisesTable = `
  CREATE TABLE IF NOT EXISTS entreprises (
    entreprise_id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telephone VARCHAR(20),
    adresse TEXT,
    logo_url TEXT,
    plan_abonnement VARCHAR(50) DEFAULT 'gratuit',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_expiration TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`;

// Exécution de la création de la table
pool.query(createEntreprisesTable)
  .then(() => {
    console.log('Table entreprises created successfully');
  })
  .catch((err) => console.error('Error setting up entreprises table:', err)); 