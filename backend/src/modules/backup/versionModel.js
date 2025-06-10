import db from '../../config/database.js';

const createVersionsTableSQL = `
    DO $$ 
    BEGIN
        -- Créer la table versions si elle n'existe pas
        CREATE TABLE IF NOT EXISTS versions (
            id UUID PRIMARY KEY,
            file_id INTEGER NOT NULL,
            version_number INTEGER NOT NULL,
            storage_path TEXT NOT NULL,
            metadata JSONB,
            created_by INTEGER,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(file_id, version_number)
        );

        -- Ajouter les contraintes de clé étrangère si elles n'existent pas
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'versions_file_id_fkey'
        ) THEN
            ALTER TABLE versions
            ADD CONSTRAINT versions_file_id_fkey
            FOREIGN KEY (file_id) REFERENCES fichiers(fichier_id);
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'versions_created_by_fkey'
        ) THEN
            ALTER TABLE versions
            ADD CONSTRAINT versions_created_by_fkey
            FOREIGN KEY (created_by) REFERENCES users(user_id);
        END IF;

        -- Créer les index s'ils n'existent pas
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'idx_versions_file_id'
        ) THEN
            CREATE INDEX idx_versions_file_id ON versions(file_id);
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'idx_versions_version_number'
        ) THEN
            CREATE INDEX idx_versions_version_number ON versions(version_number);
        END IF;
    END $$;
`;

// Vérifier si les tables requises existent
const checkRequiredTablesSQL = `
    SELECT 
        EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_name = 'fichiers'
        ) as fichiers_exists,
        EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_name = 'users'
        ) as users_exists,
        EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'fichiers' AND column_name = 'fichier_id'
        ) as fichiers_has_fichier_id,
        EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'user_id'
        ) as users_has_user_id;
`;

// Méthodes CRUD
const createVersion = async (versionData) => {
    try {
        const { id, file_id, version_number, storage_path, metadata, created_by } = versionData;
        const result = await db.query(
            'INSERT INTO versions (id, file_id, version_number, storage_path, metadata, created_by) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
            [id, file_id, version_number, storage_path, metadata, created_by]
        );
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la création de la version:', error);
        throw error;
    }
};

const getVersionById = async (versionId) => {
    try {
        const result = await db.query('SELECT * FROM versions WHERE id = $1', [versionId]);
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la récupération de la version:', error);
        throw error;
    }
};

const getVersionsByFileId = async (fileId) => {
    try {
        const result = await db.query(
            'SELECT * FROM versions WHERE file_id = $1 ORDER BY version_number DESC',
            [fileId]
        );
        return result.rows;
    } catch (error) {
        console.error('Erreur lors de la récupération des versions du fichier:', error);
        throw error;
    }
};

const updateFileVersion = async (fileId, newVersionId, userId) => {
    try {
        const result = await db.query(
            'UPDATE fichiers SET current_version_id = $1, updated_by = $2, updated_at = NOW() WHERE fichier_id = $3 RETURNING *',
            [newVersionId, userId, fileId]
        );
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la mise à jour de la version du fichier:', error);
        throw error;
    }
};

const deleteVersion = async (versionId) => {
    try {
        const result = await db.query('DELETE FROM versions WHERE id = $1 RETURNING *', [versionId]);
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la suppression de la version:', error);
        throw error;
    }
};

// Initialisation de la base de données
const initializeDatabase = async () => {
    try {
        // Vérifier d'abord si les tables requises existent
        const checkResult = await db.query(checkRequiredTablesSQL);
        const {
            fichiers_exists,
            users_exists,
            fichiers_has_fichier_id,
            users_has_user_id
        } = checkResult.rows[0];

        if (!fichiers_exists || !users_exists) {
            console.log('Tables fichiers ou users n\'existent pas encore. Création de la table versions reportée.');
            return;
        }

        if (!fichiers_has_fichier_id || !users_has_user_id) {
            console.log('Tables fichiers ou users n\'ont pas les colonnes requises. Création de la table versions reportée.');
            return;
        }

        // Créer la table versions
        await db.query(createVersionsTableSQL);
        console.log('Table versions et index créés/mis à jour avec succès');
    } catch (error) {
        console.error('Erreur lors de la création/mise à jour de la table versions:', error);
        throw error;
    }
};

// Initialiser la base de données au démarrage
initializeDatabase();

export default {
    createVersion,
    getVersionById,
    getVersionsByFileId,
    updateFileVersion,
    deleteVersion
}; 