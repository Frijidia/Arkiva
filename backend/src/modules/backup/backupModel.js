import db from '../../config/database.js';
import restoreService from './restoreService.js';

const createBackupsTableSQL = `
  DO $$
  BEGIN
    -- Crée le type ENUM type_sauvegarde s'il n'existe pas
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'type_sauvegarde') THEN
        CREATE TYPE type_sauvegarde AS ENUM ('fichier', 'dossier', 'système');
    END IF;

    -- Crée la table sauvegardes si elle n'existe pas
    CREATE TABLE IF NOT EXISTS sauvegardes (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      type type_sauvegarde NOT NULL, -- Utilise le type ENUM
      cible_id UUID, -- ID du fichier ou dossier sauvegardé (nullable si système)
      chemin_sauvegarde TEXT, -- Chemin vers l'archive (ZIP, JSON, dossier)
      contenu_json JSONB, -- Résumé des données sauvegardées
      declenche_par_id UUID, -- utilisateur (FK) ayant lancé la sauvegarde
      date_creation TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      -- CONSTRAINT fk_utilisateur
      --   FOREIGN KEY(declenche_par_id)
      --     REFERENCES utilisateurs(id) -- Assurez-vous que la table utilisateurs existe et a une colonne id de type UUID
    );

    -- Altère la colonne type pour utiliser le type ENUM si elle est encore VARCHAR
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sauvegardes' AND column_name = 'type' AND data_type = 'character varying') THEN
      ALTER TABLE sauvegardes
      ALTER COLUMN type TYPE type_sauvegarde
      USING type::type_sauvegarde;
    END IF;

  END $$;
`;

db.query(createBackupsTableSQL)
  .then(() => {
    console.log('Table sauvegardes et type ENUM créés/mis à jour avec succès');
  })
  .catch(error => {
    console.error('Erreur lors de la création/mise à jour de la table sauvegardes et du type ENUM:', error);
  });

// Méthodes CRUD

const createBackup = async (data) => {
    try {
        const { type, cible_id, chemin_sauvegarde, contenu_json, declenche_par_id } = data;
        const result = await db.query(
            'INSERT INTO sauvegardes (type, cible_id, chemin_sauvegarde, contenu_json, declenche_par_id) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [type, cible_id, chemin_sauvegarde, contenu_json, declenche_par_id]
        );
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la création de la sauvegarde:', error);
        throw error;
    }
};

const getAllBackups = async () => {
    try {
        const result = await db.query('SELECT * FROM sauvegardes ORDER BY date_creation DESC');
        return result.rows;
    } catch (error) {
        console.error('Erreur lors de la récupération des sauvegardes:', error);
        throw error;
    }
};

const getBackupById = async (id) => {
    try {
        const result = await db.query('SELECT * FROM sauvegardes WHERE id = $1', [id]);
        return result.rows[0];
    } catch (error) {
        console.error('Erreur lors de la récupération de la sauvegarde par ID:', error);
        throw error;
    }
};

// Délègue la restauration au service dédié
const restoreBackup = async (backupId, utilisateur_id) => {
    try {
        const backup = await getBackupById(backupId);
        if (!backup) {
            throw new Error('Sauvegarde non trouvée.');
        }
        return await restoreService.restoreBackup(backupId, utilisateur_id);
    } catch (error) {
        console.error(`Erreur dans backupModel.restoreBackup pour sauvegarde ID ${backupId}:`, error);
        throw error;
    }
};

export default {
    createBackup,
    getAllBackups,
    getBackupById,
    restoreBackup
}; 