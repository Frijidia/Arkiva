import pool from '../../config/database.js';

const createTablefichier = `
 CREATE TABLE IF NOT EXISTS fichiers (
  fichier_id SERIAL PRIMARY KEY,
  dossier_id INTEGER REFERENCES dossiers(dossier_id) ON DELETE CASCADE,
  nom VARCHAR(255) NOT NULL,
  originalFileName VARCHAR(255) NOT NULL,
  type VARCHAR(100), -- exemple : pdf, docx, txt
  chemin TEXT NOT NULL, -- chemin dans le système de fichiers ou URL
  taille INTEGER, -- taille en octets
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  contenu_ocr TEXT,
  is_deleted BOOLEAN DEFAULT FALSE,
  version_id INTEGER DEFAULT 0,
  jsonString TEXT
);
`;

const addContenuOcrColumn = `
  DO $$ 
  BEGIN 
    IF NOT EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_name = 'fichiers' 
      AND column_name = 'contenu_ocr'
    ) THEN
      ALTER TABLE fichiers ADD COLUMN contenu_ocr TEXT;
    END IF;
  END $$;
`;

// Migration pour ajouter la colonne taille si elle n'existe pas
const addTailleColumn = `
  DO $$ 
  BEGIN 
    IF NOT EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_name = 'fichiers' 
      AND column_name = 'taille'
    ) THEN
      ALTER TABLE fichiers ADD COLUMN taille INTEGER;
      RAISE NOTICE 'Colonne taille ajoutée à la table fichiers';
    END IF;
  END $$;
`;

const initializeTable = async () => {
  try {
    // Créer la table si elle n'existe pas
    await pool.query(createTablefichier);
    console.log('Table fichiers créée ou déjà existante');

    // Ajouter la colonne contenu_ocr si elle n'existe pas
    await pool.query(addContenuOcrColumn);
    console.log('Colonne contenu_ocr vérifiée/ajoutée');

    // Ajouter la colonne taille si elle n'existe pas
    await pool.query(addTailleColumn);
    console.log('Colonne taille vérifiée/ajoutée');

  } catch (err) {
    console.error('Erreur lors de l\'initialisation de la table fichiers:', err);
    throw err;
  }
};

// Exécuter l'initialisation
initializeTable();

export default pool;



