import pool from '../../config/database.js';
import { v4 as uuidv4 } from 'uuid';

// Création de la table restores
const createRestoresTable = `
  DO $$
  BEGIN
    -- Créer la table restores si elle n'existe pas
    CREATE TABLE IF NOT EXISTS restores (
        id UUID PRIMARY KEY,
        backup_id INTEGER,
        version_id UUID,
        type VARCHAR(50) NOT NULL CHECK (type IN ('fichier', 'dossier', 'casier', 'armoire')),
        cible_id INTEGER NOT NULL,
        entreprise_id INTEGER,
        declenche_par_id INTEGER,
        metadata_json JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP WITH TIME ZONE
    );

    -- Ajouter les colonnes manquantes si elles n'existent pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'restores' AND column_name = 'updated_at') THEN
        ALTER TABLE restores ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'restores' AND column_name = 'deleted_at') THEN
        ALTER TABLE restores ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'restores' AND column_name = 'version_id') THEN
        ALTER TABLE restores ADD COLUMN version_id UUID;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'restores' AND column_name = 'metadata_json') THEN
        ALTER TABLE restores ADD COLUMN metadata_json JSONB;
    END IF;

    -- Modifier le type de backup_id si nécessaire
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'restores' AND column_name = 'backup_id' AND data_type = 'uuid') THEN
        ALTER TABLE restores ALTER COLUMN backup_id TYPE INTEGER USING backup_id::integer;
    END IF;

    -- Créer les index
    CREATE INDEX IF NOT EXISTS idx_restores_backup_id ON restores(backup_id);
    CREATE INDEX IF NOT EXISTS idx_restores_version_id ON restores(version_id);
    CREATE INDEX IF NOT EXISTS idx_restores_type ON restores(type);
    CREATE INDEX IF NOT EXISTS idx_restores_cible_id ON restores(cible_id);
    CREATE INDEX IF NOT EXISTS idx_restores_entreprise_id ON restores(entreprise_id);
    CREATE INDEX IF NOT EXISTS idx_restores_declenche_par_id ON restores(declenche_par_id);
    CREATE INDEX IF NOT EXISTS idx_restores_created_at ON restores(created_at);

  END $$;
`;

// Initialiser la table
const initializeTable = async () => {
    try {
        await pool.query(createRestoresTable);
        console.log('Table restores créée/mise à jour avec succès');
    } catch (error) {
        console.error('Erreur lors de l\'initialisation de la table restores:', error);
    }
};

// Exécuter l'initialisation
initializeTable();

// Créer une nouvelle restauration
const createRestore = async (restoreData) => {
    const { backup_id, version_id, type, cible_id, entreprise_id, declenche_par_id, metadata_json } = restoreData;
    const id = uuidv4();
    
    const query = `
        INSERT INTO restores (
            id, backup_id, version_id, type, cible_id, entreprise_id, 
            declenche_par_id, metadata_json, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP)
        RETURNING *
    `;
    
    const values = [id, backup_id, version_id, type, cible_id, entreprise_id, declenche_par_id, metadata_json];
    const result = await pool.query(query, values);
    return result.rows[0];
};

// Obtenir toutes les restaurations
const getAllRestores = async () => {
    const query = 'SELECT * FROM restores ORDER BY created_at DESC';
    const result = await pool.query(query);
    return result.rows;
};

// Obtenir une restauration par ID
const getRestoreById = async (id) => {
    const query = 'SELECT * FROM restores WHERE id = $1';
    const result = await pool.query(query, [id]);
    return result.rows[0];
};

// Obtenir les restaurations par entreprise
const getRestoresByEntreprise = async (entrepriseId) => {
    const query = 'SELECT * FROM restores WHERE entreprise_id = $1 ORDER BY created_at DESC';
    const result = await pool.query(query, [entrepriseId]);
    return result.rows;
};

// Obtenir les restaurations par type
const getRestoresByType = async (type) => {
    const query = 'SELECT * FROM restores WHERE type = $1 ORDER BY created_at DESC';
    const result = await pool.query(query, [type]);
    return result.rows;
};

// Obtenir les restaurations par version
const getRestoresByVersion = async (versionId) => {
    const query = 'SELECT * FROM restores WHERE version_id = $1 ORDER BY created_at DESC';
    const result = await pool.query(query, [versionId]);
    return result.rows;
};

// Obtenir les restaurations par sauvegarde
const getRestoresByBackup = async (backupId) => {
    const query = 'SELECT * FROM restores WHERE backup_id = $1 ORDER BY created_at DESC';
    const result = await pool.query(query, [backupId]);
    return result.rows;
};

// Supprimer une restauration
const deleteRestore = async (id) => {
    const query = 'DELETE FROM restores WHERE id = $1 RETURNING *';
    const result = await pool.query(query, [id]);
    return result.rows[0];
};

export default {
    createRestore,
    getAllRestores,
    getRestoreById,
    getRestoresByEntreprise,
    getRestoresByType,
    getRestoresByVersion,
    getRestoresByBackup,
    deleteRestore
}; 