import pool from '../../config/database.js';

const createBackupsTableSQL = `
  DO $$
  BEGIN
    -- Crée le type ENUM type_sauvegarde s'il n'existe pas
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'type_sauvegarde') THEN
        CREATE TYPE type_sauvegarde AS ENUM ('fichier', 'dossier', 'casier', 'armoire', 'système');
    END IF;

    -- Créer la table sauvegardes si elle n'existe pas
    CREATE TABLE IF NOT EXISTS sauvegardes (
        id SERIAL PRIMARY KEY,
        type type_sauvegarde,
        cible_id INTEGER,
        entreprise_id INTEGER,
        chemin_sauvegarde TEXT,
        contenu_json JSONB,
        declenche_par_id INTEGER,
        date_creation TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    -- Ajouter les colonnes manquantes si elles n'existent pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'type') THEN
        ALTER TABLE sauvegardes ADD COLUMN type type_sauvegarde;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'cible_id') THEN
        ALTER TABLE sauvegardes ADD COLUMN cible_id INTEGER;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'entreprise_id') THEN
        ALTER TABLE sauvegardes ADD COLUMN entreprise_id INTEGER;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'declenche_par_id') THEN
        ALTER TABLE sauvegardes ADD COLUMN declenche_par_id INTEGER;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'chemin_sauvegarde') THEN
        ALTER TABLE sauvegardes ADD COLUMN chemin_sauvegarde TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'contenu_json') THEN
        ALTER TABLE sauvegardes ADD COLUMN contenu_json JSONB;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'date_creation') THEN
        ALTER TABLE sauvegardes ADD COLUMN date_creation TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;

    -- Ajouter les colonnes S3 pour être cohérent avec les versions
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'storage_path') THEN
        ALTER TABLE sauvegardes ADD COLUMN storage_path TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 's3_key') THEN
        ALTER TABLE sauvegardes ADD COLUMN s3_key TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 's3_size') THEN
        ALTER TABLE sauvegardes ADD COLUMN s3_size BIGINT;
    END IF;

  END $$;
`;

class BackupModel {
    constructor() {
        this.init();
    }

    async init() {
        try {
            await pool.query(createBackupsTableSQL);
            console.log('Table sauvegardes mise à jour avec succès');
        } catch (error) {
            console.error('Erreur lors de l\'initialisation de la table sauvegardes:', error);
        }
    }

    async createBackup(data) {
        try {
            const { 
                type, 
                cible_id, 
                entreprise_id, 
                chemin_sauvegarde, 
                contenu_json, 
                declenche_par_id,
                storage_path,
                s3_key,
                s3_size
            } = data;
            
            const query = `
                INSERT INTO sauvegardes 
                (type, cible_id, entreprise_id, chemin_sauvegarde, contenu_json, declenche_par_id, storage_path, s3_key, s3_size) 
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
                RETURNING *
            `;
            
            const result = await pool.query(query, [
                type, 
                cible_id, 
                entreprise_id, 
                chemin_sauvegarde, 
                contenu_json, 
                declenche_par_id,
                storage_path,
                s3_key,
                s3_size
            ]);
            
            return result.rows[0];
        } catch (error) {
            console.error('Erreur lors de la création de la sauvegarde:', error);
            throw error;
        }
    }

    async getAllBackups() {
        try {
            const query = `
                SELECT * FROM sauvegardes 
                ORDER BY date_creation DESC
            `;
            const result = await pool.query(query);
            return result.rows;
        } catch (error) {
            console.error('Erreur lors de la récupération des sauvegardes:', error);
            throw error;
        }
    }

    async getBackupById(id) {
        try {
            const query = `
                SELECT * FROM sauvegardes 
                WHERE id = $1
            `;
            const result = await pool.query(query, [id]);
            return result.rows[0];
        } catch (error) {
            console.error('Erreur lors de la récupération de la sauvegarde par ID:', error);
            throw error;
        }
    }

    async getBackupsByType(type) {
        try {
            const query = `
                SELECT * FROM sauvegardes 
                WHERE type = $1
                ORDER BY date_creation DESC
            `;
            const result = await pool.query(query, [type]);
            return result.rows;
        } catch (error) {
            console.error('Erreur lors de la récupération des sauvegardes par type:', error);
            throw error;
        }
    }

    async getBackupsByEntreprise(entreprise_id) {
        try {
            const query = `
                SELECT * FROM sauvegardes 
                WHERE entreprise_id = $1
                ORDER BY date_creation DESC
            `;
            const result = await pool.query(query, [entreprise_id]);
            return result.rows;
        } catch (error) {
            console.error('Erreur lors de la récupération des sauvegardes par entreprise:', error);
            throw error;
        }
    }
}

export default new BackupModel(); 