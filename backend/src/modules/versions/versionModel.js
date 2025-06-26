import pool from '../../config/database.js';
import { v4 as uuidv4 } from 'uuid';

const createVersionsTableSQL = `
  DO $$
  BEGIN
    -- Crée le type ENUM type_version s'il n'existe pas
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'type_version') THEN
        CREATE TYPE type_version AS ENUM ('fichier', 'dossier', 'casier', 'armoire');
    END IF;

    -- Supprime la table si elle existe déjà
    DROP TABLE IF EXISTS versions;

    -- Crée la table des versions
    CREATE TABLE versions (
        id UUID PRIMARY KEY,
        cible_id INTEGER NOT NULL,
        type type_version NOT NULL,
        version_number NUMERIC(10,2) NOT NULL,
        storage_path TEXT NOT NULL,
        metadata JSONB,
        created_by INTEGER,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users(user_id)
    );

    -- Crée un index sur cible_id pour améliorer les performances
    CREATE INDEX IF NOT EXISTS idx_versions_cible_id ON versions(cible_id);
  END $$;
`;

class VersionModel {
    constructor() {
        this.init();
    }

    async init() {
        try {
            await pool.query(createVersionsTableSQL);
            console.log('Table versions créée/mise à jour avec succès');
        } catch (error) {
            console.error('Erreur lors de la création/mise à jour de la table versions:', error);
        }
    }

    async createVersion(versionData) {
        try {
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

            const result = await pool.query(query, values);
            return result.rows[0];

        } catch (error) {
            console.error('Erreur lors de la création de la version:', error);
            throw error;
        }
    }

    async getVersionsByCibleId(cibleId, type) {
        try {
            console.log('Recherche des versions pour cible_id:', cibleId, 'et type:', type);
            
            // Vérifier d'abord si la table existe
            const tableExists = await pool.query(`
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'versions'
                );
            `);
            
            if (!tableExists.rows[0].exists) {
                console.log('La table versions n\'existe pas');
                return [];
            }

            // Vérifier le contenu de la table
            const countQuery = 'SELECT COUNT(*) FROM versions';
            const countResult = await pool.query(countQuery);
            console.log('Nombre total de versions dans la table:', countResult.rows[0].count);

            const query = `
                SELECT *
                FROM versions
                WHERE cible_id = $1 AND type = $2
                ORDER BY created_at DESC
            `;

            const result = await pool.query(query, [cibleId, type]);
            console.log('Résultat de la requête:', result.rows);
            return result.rows;
        } catch (error) {
            console.error('Erreur lors de la récupération des versions:', error);
            throw error;
        }
    }

    async getVersionById(versionId) {
        try {
            const query = `
                SELECT *
                FROM versions
                WHERE id = $1
            `;

            const result = await pool.query(query, [versionId]);
            return result.rows[0];
        } catch (error) {
            console.error('Erreur lors de la récupération de la version:', error);
            throw error;
        }
    }

    async deleteVersion(versionId) {
        try {
            const query = `
                DELETE FROM versions
                WHERE id = $1
                RETURNING *
            `;

            const result = await pool.query(query, [versionId]);
            return result.rows[0];
        } catch (error) {
            console.error('Erreur lors de la suppression de la version:', error);
            throw error;
        }
    }
}

export default new VersionModel(); 