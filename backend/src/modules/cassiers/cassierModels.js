import db from '../../config/database.js';

const createTableCassiers = `
 CREATE TABLE IF NOT EXISTS casiers (
  cassier_id SERIAL PRIMARY KEY,
  armoire_id INTEGER REFERENCES armoires(armoire_id) ON DELETE CASCADE,
  nom VARCHAR(50) ,
  sous_titre VARCHAR(255),
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  version_id INTEGER DEFAULT 0
);
`;

// Migration pour corriger les incohérences de noms de colonnes
const fixColumnNames = `
  DO $$
  BEGIN
    -- Vérifier si la table dossiers existe et corriger le nom de la colonne
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'dossiers') THEN
      -- Si la colonne s'appelle 'casier_id' (sans double s), la renommer en 'cassier_id'
      IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dossiers' AND column_name = 'casier_id') THEN
        ALTER TABLE dossiers RENAME COLUMN casier_id TO cassier_id;
        RAISE NOTICE 'Colonne casier_id renommée en cassier_id dans la table dossiers';
      END IF;
    END IF;
  END $$;
`;

db.query(createTableCassiers)
    .then(() => {
        console.log('Table casier created successfully');
        return db.query(fixColumnNames);
    })
    .then(() => {
        console.log('Column names fixed successfully');
    })
    .catch((err) => console.error('Error creating table:', err));



