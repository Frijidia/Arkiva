import db from '../../config/database.js';

const createBackupsTableSQL = `
  DO $$
  BEGIN
    -- Crée le type ENUM type_sauvegarde s'il n'existe pas
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'type_sauvegarde') THEN
        CREATE TYPE type_sauvegarde AS ENUM ('fichier', 'dossier', 'casier', 'armoire', 'système');
    END IF;

    -- Supprime et recrée les colonnes avec le bon type
    ALTER TABLE sauvegardes DROP COLUMN IF EXISTS cible_id;
    ALTER TABLE sauvegardes DROP COLUMN IF EXISTS entreprise_id;
    ALTER TABLE sauvegardes DROP COLUMN IF EXISTS declenche_par_id;

    ALTER TABLE sauvegardes 
      ADD COLUMN cible_id INTEGER,
      ADD COLUMN entreprise_id INTEGER,
      ADD COLUMN declenche_par_id INTEGER;

    -- Ajoute les colonnes manquantes si elles n'existent pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'type') THEN
        ALTER TABLE sauvegardes ADD COLUMN type type_sauvegarde;
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

  END $$;
`;

class BackupModel {
    constructor() {
        this.init();
    }

    async init() {
        try {
            await db.query(createBackupsTableSQL);
            console.log('Table sauvegardes mise à jour avec succès');
        } catch (error) {
            console.error('Erreur lors de l\'initialisation de la table sauvegardes:', error);
            throw error;
        }
    }

    async createBackup(data) {
        try {
            const { type, cible_id, entreprise_id, chemin_sauvegarde, contenu_json, declenche_par_id } = data;
            const query = `
                INSERT INTO sauvegardes 
                (type, cible_id, entreprise_id, chemin_sauvegarde, contenu_json, declenche_par_id) 
                VALUES ($1, $2, $3, $4, $5, $6) 
                RETURNING *
            `;
            const result = await db.query(query, [
                type, 
                cible_id, 
                entreprise_id, 
                chemin_sauvegarde, 
                contenu_json, 
                declenche_par_id
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
            const result = await db.query(query);
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
            const result = await db.query(query, [id]);
            return result.rows[0];
        } catch (error) {
            console.error('Erreur lors de la récupération de la sauvegarde par ID:', error);
            throw error;
        }
    }
}

export default new BackupModel(); 