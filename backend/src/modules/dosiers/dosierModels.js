import db from '../../config/database.js';

const createTabledosier = `
 CREATE TABLE IF NOT EXISTS dossiers (
  dossier_id SERIAL PRIMARY KEY,
  cassier_id INTEGER REFERENCES casiers(cassier_id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  nom VARCHAR(100),
  is_deleted BOOLEAN DEFAULT FALSE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  version_id INTEGER DEFAULT 0
);
`;

// Migration pour ajouter la colonne is_deleted si elle n'existe pas
const addIsDeletedColumn = `
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'dossiers' AND column_name = 'is_deleted'
  ) THEN
    ALTER TABLE dossiers ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
    RAISE NOTICE 'Colonne is_deleted ajoutée à la table dossiers';
  END IF;
END $$;
`;

db.query(createTabledosier)
  .then(() => {
    console.log('Table dosier created successfully');
    return db.query(addIsDeletedColumn);
  })
  .then(() => {
    console.log('Migration is_deleted column completed');
  })
  .catch((err) => console.error('Error setting up dosier table:', err)); 