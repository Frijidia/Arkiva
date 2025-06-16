import restoreModel from './restoreModel.js';
import backupModel from '../backup/backupModel.js';
import * as fileService from '../fichiers/fichierControllers.js';
import * as dossierService from '../dosiers/dosierControllers.js';
import * as casierService from '../cassiers/cassierContollers.js';
import * as armoireService from '../armoires/armoireControllers.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import extract from 'extract-zip';

// Obtenir le chemin du répertoire actuel pour les modules ES
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Chemin où sont stockées les sauvegardes
const BACKUP_DIR = path.join(__dirname, '../../../uploads/backups');

// Restaurer une sauvegarde
const restoreBackup = async (backupId, userId) => {
    try {
        // Récupérer les informations de la sauvegarde
        const backup = await backupModel.getBackupById(backupId);
        if (!backup) {
            throw new Error('Sauvegarde non trouvée');
        }

        // Vérifier que le fichier de sauvegarde existe
        if (!fs.existsSync(backup.chemin_sauvegarde)) {
            throw new Error('Fichier de sauvegarde non trouvé');
        }

        // Créer un répertoire temporaire pour l'extraction
        const tempDir = path.join(BACKUP_DIR, 'temp', backupId);
        if (!fs.existsSync(tempDir)) {
            fs.mkdirSync(tempDir, { recursive: true });
        }

        // Extraire l'archive
        await extract(backup.chemin_sauvegarde, { dir: tempDir });

        // Lire les métadonnées
        const metadata = JSON.parse(fs.readFileSync(path.join(tempDir, 'metadata.json'), 'utf8'));

        // Restaurer selon le type
        let restoredData;
        switch (backup.type) {
            case 'fichier':
                restoredData = await restoreFile(metadata, tempDir, userId);
                break;
            case 'dossier':
                restoredData = await restoreDossier(metadata, tempDir, userId);
                break;
            case 'casier':
                restoredData = await restoreCasier(metadata, tempDir, userId);
                break;
            case 'armoire':
                restoredData = await restoreArmoire(metadata, tempDir, userId);
                break;
            default:
                throw new Error('Type de sauvegarde non supporté');
        }

        // Créer l'entrée de restauration
        const restoreData = {
            backup_id: backupId,
            type: backup.type,
            cible_id: restoredData.id,
            entreprise_id: backup.entreprise_id,
            declenche_par_id: userId
        };

        const restore = await restoreModel.createRestore(restoreData);

        // Nettoyer le répertoire temporaire
        fs.rmSync(tempDir, { recursive: true, force: true });

        return restore;
    } catch (error) {
        console.error('Erreur lors de la restauration:', error);
        throw error;
    }
};

// Restaurer un fichier
const restoreFile = async (metadata, tempDir, userId) => {
    const fileData = {
        nom: metadata.nom,
        type_mime: metadata.type_mime,
        taille: metadata.taille,
        dossier_id: metadata.dossier_id,
        created_by: userId
    };

    return await fileService.createFichier(fileData);
};

// Restaurer un dossier
const restoreDossier = async (metadata, tempDir, userId) => {
    const dossierData = {
        nom: metadata.nom,
        casier_id: metadata.casier_id,
        created_by: userId
    };

    return await dossierService.createDossier(dossierData);
};

// Restaurer un casier
const restoreCasier = async (metadata, tempDir, userId) => {
    const casierData = {
        nom: metadata.nom,
        armoire_id: metadata.armoire_id,
        created_by: userId
    };

    return await casierService.createCasier(casierData);
};

// Restaurer une armoire
const restoreArmoire = async (metadata, tempDir, userId) => {
    const armoireData = {
        nom: metadata.nom,
        entreprise_id: metadata.entreprise_id,
        created_by: userId
    };

    return await armoireService.createArmoire(armoireData);
};

export default {
    restoreBackup
}; 