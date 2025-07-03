import pool from '../../config/database.js';

const createTableArmoires = `
  CREATE TABLE IF NOT EXISTS armoires (
  armoire_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  sous_titre VARCHAR(255),
  nom VARCHAR(50),
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  entreprise_id INTEGER REFERENCES entreprises(entreprise_id) ON DELETE CASCADE,
  version_id INTEGER DEFAULT 0,
  taille_max BIGINT DEFAULT 524288000 -- 500 Mo en octets

);
`;

// Vérifier si la colonne entreprise_id existe
const checkColumn = `
  SELECT column_name 
  FROM information_schema.columns 
  WHERE table_name = 'armoires' 
  AND column_name = 'entreprise_id';
`;

// Recréer la table si nécessaire
const recreateTable = `
  DROP TABLE IF EXISTS armoires CASCADE;
  ${createTableArmoires}
`;

const initializeTable = async () => {
  try {
    // Vérifier si la colonne existe
    const columnCheck = await pool.query(checkColumn);
    
    if (columnCheck.rows.length === 0) {
      console.log('Colonne entreprise_id non trouvée, recréation de la table...');
      await pool.query(recreateTable);
      console.log('Table armoires recréée avec succès');
    } else {
      console.log('Table armoires déjà correctement configurée');
    }
  } catch (err) {
    console.error('Erreur lors de l\'initialisation de la table armoires:', err);
    throw err;
  }
};

// Exécuter l'initialisation
initializeTable();

export default pool;
