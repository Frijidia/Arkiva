import pool from '../../config/database.js';

const createEncryptionKeysTable = `
  DO $$ 
  BEGIN
    -- Vérifie si la table entreprises existe
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'entreprises') THEN
      -- Crée la table encryption_keys si elle n'existe pas
      CREATE TABLE IF NOT EXISTS encryption_keys (
        id SERIAL PRIMARY KEY,
        entreprise_id INTEGER NOT NULL REFERENCES entreprises(entreprise_id) ON DELETE CASCADE,
        key_encrypted TEXT NOT NULL,
        iv VARCHAR(32) NOT NULL,
        auth_tag VARCHAR(32) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'encryption_keys' 
        AND column_name = 'auth_tag'
      ) THEN
        ALTER TABLE encryption_keys ADD COLUMN auth_tag VARCHAR(32);
      END IF;
    ELSE
      RAISE EXCEPTION 'La table entreprises doit exister avant de créer encryption_keys';
    END IF;
  END $$;
`;

// Création de la table
pool.query(createEncryptionKeysTable)
  .then(() => {
    console.log('Table encryption_keys créée/mise à jour avec succès');
  })
  .catch(error => {
    console.error('Erreur lors de la création/mise à jour de la table encryption_keys:', error);
  });

// Méthodes CRUD
const createKey = async (data) => {
    try {
        const { entreprise_id, key_encrypted, iv, auth_tag } = data;
        const result = await pool.query(
            'INSERT INTO encryption_keys (entreprise_id, key_encrypted, iv, auth_tag) VALUES ($1, $2, $3, $4) RETURNING *',
            [entreprise_id, key_encrypted, iv, auth_tag]
        );
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la création de la clé:', error);
        throw error;
    }
};

const findByEntrepriseId = async (entrepriseId) => {
    try {
        const result = await pool.query(
            'SELECT * FROM encryption_keys WHERE entreprise_id = $1 ORDER BY created_at DESC LIMIT 1',
            [entrepriseId]
        );
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la recherche de la clé:', error);
        throw error;
    }
};

const updateKey = async (entrepriseId, data) => {
    try {
        const { key_encrypted, iv, auth_tag } = data;
        const result = await pool.query(
            'UPDATE encryption_keys SET key_encrypted = $1, iv = $2, auth_tag = $3, updated_at = CURRENT_TIMESTAMP WHERE entreprise_id = $4 RETURNING *',
            [key_encrypted, iv, auth_tag, entrepriseId]
        );
        if (result.rows.length === 0) {
            throw new Error('Clé non trouvée pour cette entreprise');
        }
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la mise à jour de la clé:', error);
        throw error;
    }
};

const deleteKey = async (entrepriseId) => {
    try {
        const result = await pool.query(
            'DELETE FROM encryption_keys WHERE entreprise_id = $1 RETURNING *',
            [entrepriseId]
        );
        if (result.rows.length === 0) {
            throw new Error('Clé non trouvée pour cette entreprise');
        }
        return true;
    } catch (error) {
        console.error('Erreur lors de la suppression de la clé:', error);
        throw error;
    }
};

const cleanupOldKeys = async (entrepriseId) => {
    try {
        // Garde uniquement la clé la plus récente
        await pool.query(
            `DELETE FROM encryption_keys 
             WHERE entreprise_id = $1 
             AND id NOT IN (
                 SELECT id 
                 FROM encryption_keys 
                 WHERE entreprise_id = $1 
                 ORDER BY created_at DESC 
                 LIMIT 1
             )`,
            [entrepriseId]
        );
        console.log('Nettoyage des anciennes clés effectué pour l\'entreprise', entrepriseId);
    } catch (error) {
        console.error('Erreur lors du nettoyage des anciennes clés:', error);
        throw error;
    }
};

export default {
    createKey,
    findByEntrepriseId,
    updateKey,
    deleteKey,
    cleanupOldKeys
}; 