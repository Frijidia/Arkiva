import pool from '../../config/database.js';

// Création de la table users
const createUsersTable = `
  CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    entreprise_id INTEGER REFERENCES entreprises(entreprise_id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    password TEXT NOT NULL,
    username VARCHAR(100),
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('admin', 'contributeur', 'lecteur', 'user')),
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret TEXT,
    two_factor_method VARCHAR(10) CHECK (two_factor_method IN ('email', 'otp', NULL)),
    two_factor_code VARCHAR(6),
    two_factor_code_expires TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(entreprise_id, email)
  );
`;

// Création d'un index sur entreprise_id pour optimiser les recherches
const createIndex = `
  CREATE INDEX IF NOT EXISTS idx_users_entreprise_id ON users(entreprise_id);
`;

// Exécution des requêtes dans l'ordre
pool.query(createUsersTable)
  .then(() => {
    console.log('Table users created successfully');
    return pool.query(createIndex);
  })
  .then(() => {
    console.log('Index created successfully');
  })
  .catch((err) => console.error('Error setting up users table:', err));
