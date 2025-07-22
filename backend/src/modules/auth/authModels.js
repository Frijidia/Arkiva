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

// Migration pour ajouter les colonnes manquantes
const addMissingColumns = `
  DO $$
  BEGIN
    -- Ajouter la colonne password si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'password') THEN
      ALTER TABLE users ADD COLUMN password TEXT;
    END IF;
    
    -- Ajouter la colonne two_factor_code si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'two_factor_code') THEN
      ALTER TABLE users ADD COLUMN two_factor_code VARCHAR(6);
    END IF;
    
    -- Ajouter la colonne two_factor_code_expires si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'two_factor_code_expires') THEN
      ALTER TABLE users ADD COLUMN two_factor_code_expires TIMESTAMP;
    END IF;
    
    -- Ajouter la colonne two_factor_method si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'two_factor_method') THEN
      ALTER TABLE users ADD COLUMN two_factor_method VARCHAR(10);
    END IF;
  END $$;
`;

// Migration pour migrer les mots de passe
const migratePasswords = `
  DO $$
  BEGIN
    -- Si la colonne password_hash existe et que password est vide, copier password_hash vers password
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'password_hash') THEN
      UPDATE users 
      SET password = password_hash 
      WHERE password IS NULL AND password_hash IS NOT NULL;
      
      RAISE NOTICE 'Mots de passe migrés de password_hash vers password';
    END IF;
  END $$;
`;

// Création d'un index sur entreprise_id pour optimiser les recherches
const createIndex = `
  CREATE INDEX IF NOT EXISTS idx_users_entreprise_id ON users(entreprise_id);
`;

// Exécution des requêtes dans l'ordre
pool.query(createUsersTable)
  .then(() => {
    console.log('Table users created successfully');
    return pool.query(addMissingColumns);
  })
  .then(() => {
    console.log('Missing columns added successfully');
    return pool.query(migratePasswords);
  })
  .then(() => {
    console.log('Passwords migrated successfully');
    return pool.query(createIndex);
  })
  .then(() => {
    console.log('Index created successfully');
  })
  .catch((err) => console.error('Error setting up users table:', err));
