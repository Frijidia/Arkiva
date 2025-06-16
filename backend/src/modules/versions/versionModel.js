import pool from '../../config/database.js';

const createVersionsTableSQL = `
  DO $$
  BEGIN
    -- Crée le type ENUM type_version s'il n'existe pas
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'type_version') THEN
        CREATE TYPE type_version AS ENUM ('fichier', 'dossier', 'casier', 'armoire');
    END IF;

    -- Crée la table des versions si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'versions') THEN
        CREATE TABLE versions (
            id UUID PRIMARY KEY,
            cible_id INTEGER NOT NULL,
            type type_version NOT NULL,
            version_number INTEGER NOT NULL,
            storage_path TEXT NOT NULL,
            metadata JSONB,
            created_by INTEGER,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (created_by) REFERENCES utilisateurs(user_id)
        );
    END IF;
  END $$;
`;

class VersionModel {
    constructor() {
        this.init();
    }

    async init() {
        try {
            await pool.query(createVersionsTableSQL);
            console.log('Table versions mise à jour avec succès');
        } catch (error) {
            console.error('Erreur lors de l\'initialisation de la table versions:', error);
            throw error;
        }
    }

    async createVersion(versionData) {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const query = `
                INSERT INTO versions (
                    id,
                    cible_id,
                    type,
                    version_number,
                    storage_path,
                    metadata,
                    created_by,
                    created_at
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                RETURNING *
            `;

            const values = [
                versionData.id,
                versionData.cible_id,
                versionData.type,
                versionData.version_number,
                versionData.storage_path,
                versionData.metadata,
                versionData.created_by,
                new Date()
            ];

            const result = await client.query(query, values);
            await client.query('COMMIT');
            return result.rows[0];

        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    async getVersionsByCibleId(cibleId) {
        const query = `
            SELECT *
            FROM versions
            WHERE cible_id = $1
            ORDER BY created_at DESC
        `;

        const result = await pool.query(query, [cibleId]);
        return result.rows;
    }

    async getVersionById(versionId) {
        const query = `
            SELECT *
            FROM versions
            WHERE id = $1
        `;

        const result = await pool.query(query, [versionId]);
        return result.rows[0];
    }

    async deleteVersion(versionId) {
        const query = `
            DELETE FROM versions
            WHERE id = $1
            RETURNING *
        `;

        const result = await pool.query(query, [versionId]);
        return result.rows[0];
    }
}

export default new VersionModel(); 