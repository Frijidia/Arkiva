import restoreService from './restoreService.js';
import restoreModel from './restoreModel.js';
import backupModel from '../backup/backupModel.js';
import versionModel from '../versions/versionModel.js';

// Restaurer une sauvegarde
export const restoreBackup = async (req, res) => {
    try {
        // Vérifier si l'utilisateur est authentifié
        if (!req.user || !req.user.user_id) {
            return res.status(401).json({ error: 'Utilisateur non authentifié' });
        }

        const result = await restoreService.restoreBackup(
          req.params.id,
          req.user.user_id,
          req.body.armoire_id,
          req.body.cassier_id,
          req.body.dossier_id
        );
        res.json(result);
    } catch (error) {
        console.error('Erreur lors de la restauration:', error);
        res.status(500).json({ error: error.message });
    }
};

// Restaurer une version
export const restoreVersion = async (req, res) => {
    try {
        // Vérifier si l'utilisateur est authentifié
        if (!req.user || !req.user.user_id) {
            return res.status(401).json({ error: 'Utilisateur non authentifié' });
        }

        const result = await restoreService.restoreVersion(req.params.id, req.user.user_id);
        res.json(result);
    } catch (error) {
        console.error('Erreur lors de la restauration de la version:', error);
        res.status(500).json({ error: error.message });
    }
};

// Obtenir toutes les restaurations
export const getAllRestores = async (req, res) => {
    try {
        const restores = await restoreModel.getAllRestores();
        res.json(restores);
    } catch (error) {
        console.error('Erreur lors de la récupération des restaurations:', error);
        res.status(500).json({ error: error.message });
    }
};

// Obtenir une restauration par ID
export const getRestoreById = async (req, res) => {
    try {
        const restore = await restoreModel.getRestoreById(req.params.id);
        if (!restore) {
            return res.status(404).json({ error: 'Restauration non trouvée' });
        }
        res.json(restore);
    } catch (error) {
        console.error('Erreur lors de la récupération de la restauration:', error);
        res.status(500).json({ error: error.message });
    }
};

// Obtenir les restaurations par entreprise
export const getRestoresByEntreprise = async (req, res) => {
    try {
        const restores = await restoreModel.getRestoresByEntreprise(req.params.entrepriseId);
        res.json(restores);
    } catch (error) {
        console.error('Erreur lors de la récupération des restaurations:', error);
        res.status(500).json({ error: error.message });
    }
};

// Obtenir les restaurations par type
export const getRestoresByType = async (req, res) => {
    try {
        const restores = await restoreModel.getRestoresByType(req.params.type);
        res.json(restores);
    } catch (error) {
        console.error('Erreur lors de la récupération des restaurations:', error);
        res.status(500).json({ error: error.message });
    }
};

// Obtenir les restaurations par version
export const getRestoresByVersion = async (req, res) => {
    try {
        const restores = await restoreModel.getRestoresByVersion(req.params.versionId);
        res.json(restores);
    } catch (error) {
        console.error('Erreur lors de la récupération des restaurations par version:', error);
        res.status(500).json({ error: error.message });
    }
};

// Obtenir les restaurations par sauvegarde
export const getRestoresByBackup = async (req, res) => {
    try {
        const restores = await restoreModel.getRestoresByBackup(req.params.backupId);
        res.json(restores);
    } catch (error) {
        console.error('Erreur lors de la récupération des restaurations par sauvegarde:', error);
        res.status(500).json({ error: error.message });
    }
};

// Obtenir les détails d'une restauration avec métadonnées
export const getRestoreDetails = async (req, res) => {
    try {
        const restore = await restoreModel.getRestoreById(req.params.id);
        if (!restore) {
            return res.status(404).json({ error: 'Restauration non trouvée' });
        }

        // Récupérer les détails de la source (backup ou version)
        let sourceDetails = null;
        if (restore.backup_id) {
            const backup = await backupModel.getBackupById(restore.backup_id);
            sourceDetails = {
                type: 'backup',
                data: backup
            };
        } else if (restore.version_id) {
            const version = await versionModel.getVersionById(restore.version_id);
            sourceDetails = {
                type: 'version',
                data: version
            };
        }

        res.json({
            restore,
            source_details: sourceDetails,
            metadata: restore.metadata_json
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des détails de restauration:', error);
        res.status(500).json({ error: error.message });
    }
};

// Supprimer une restauration
export const deleteRestore = async (req, res) => {
    try {
        const result = await restoreModel.deleteRestore(req.params.id);
        if (!result) {
            return res.status(404).json({ error: 'Restauration non trouvée' });
        }
        res.json(result);
    } catch (error) {
        console.error('Erreur lors de la suppression de la restauration:', error);
        res.status(500).json({ error: error.message });
    }
}; 