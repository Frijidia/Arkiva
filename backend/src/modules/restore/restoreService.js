import restoreModel from './restoreModel.js';
import backupModel from '../backup/backupModel.js';
import * as fileService from '../fichiers/fichierControllers.js';
import * as dossierService from '../dosiers/dosierControllers.js';
import * as casierService from '../cassiers/cassierContollers.js';
import * as armoireService from '../armoires/armoireControllers.js';
import awsStorageService from '../../services/awsStorageService.js';
import { logAction } from '../audit/auditService.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import extract from 'extract-zip';

// Obtenir le chemin du répertoire actuel pour les modules ES
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Chemin temporaire pour l'extraction
const TEMP_DIR = path.join(__dirname, '../../../temp');

// S'assurer que le répertoire temporaire existe
if (!fs.existsSync(TEMP_DIR)) {
    fs.mkdirSync(TEMP_DIR, { recursive: true });
}

// Restaurer une sauvegarde
const restoreBackup = async (backupId, userId) => {
    let tempExtractPath = null;
    try {
        // Récupérer les informations de la sauvegarde
        const backup = await backupModel.getBackupById(backupId);
        if (!backup) {
            throw new Error('Sauvegarde non trouvée');
        }

        // Extraire la clé S3 depuis l'URL
        const s3Key = backup.contenu_json?.s3Key || backup.chemin_sauvegarde.replace(`https://${process.env.AWS_S3_BUCKET_NAME}.s3.amazonaws.com/`, '');

        // Télécharger la sauvegarde depuis S3
        const backupBuffer = await awsStorageService.downloadBackup(s3Key);

        // Créer un répertoire temporaire pour l'extraction
        tempExtractPath = path.join(TEMP_DIR, `restore_${backupId}_${Date.now()}`);
        if (!fs.existsSync(tempExtractPath)) {
            fs.mkdirSync(tempExtractPath, { recursive: true });
        }

        // Écrire le buffer dans un fichier temporaire
        const tempBackupPath = path.join(tempExtractPath, 'backup.zip');
        fs.writeFileSync(tempBackupPath, backupBuffer);

        // Extraire l'archive
        await extract(tempBackupPath, { dir: tempExtractPath });

        // Lire les métadonnées
        const metadataFiles = fs.readdirSync(tempExtractPath).filter(file => file.includes('metadata'));
        if (metadataFiles.length === 0) {
            throw new Error('Aucun fichier de métadonnées trouvé dans la sauvegarde');
        }

        const metadataPath = path.join(tempExtractPath, metadataFiles[0]);
        const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));

        // Restaurer selon le type
        let restoredData;
        switch (backup.type) {
            case 'fichier':
                restoredData = await restoreFile(metadata, tempExtractPath, userId);
                break;
            case 'dossier':
                restoredData = await restoreDossier(metadata, tempExtractPath, userId);
                break;
            case 'casier':
                restoredData = await restoreCasier(metadata, tempExtractPath, userId);
                break;
            case 'armoire':
                restoredData = await restoreArmoire(metadata, tempExtractPath, userId);
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

        // Journaliser l'action
        if (userId) {
            await logAction(
                userId,
                'restore_backup',
                'backup',
                backupId,
                {
                    backup_id: backupId,
                    restored_id: restoredData.id,
                    type: backup.type,
                    date: new Date()
                }
            );
        }

        // Nettoyer le répertoire temporaire
        if (tempExtractPath && fs.existsSync(tempExtractPath)) {
            fs.rmSync(tempExtractPath, { recursive: true, force: true });
        }

        return restore;
    } catch (error) {
        console.error('Erreur lors de la restauration:', error);
        
        // Nettoyer le répertoire temporaire en cas d'erreur
        if (tempExtractPath && fs.existsSync(tempExtractPath)) {
            fs.rmSync(tempExtractPath, { recursive: true, force: true });
        }
        
        throw error;
    }
};

// Restaurer un fichier
const restoreFile = async (metadata, tempDir, userId) => {
    const fileData = {
        nom: metadata.originalFileName || metadata.name || `fichier_restaure_${Date.now()}`,
        type_mime: metadata.type_mime || 'application/octet-stream',
        taille: metadata.taille || metadata.size || 0,
        dossier_id: metadata.dossier_id || null,
        created_by: userId
    };

    return await fileService.createFichier(fileData);
};

// Restaurer un dossier
const restoreDossier = async (metadata, tempDir, userId) => {
    const dossierData = {
        nom: metadata.name || `dossier_restaure_${Date.now()}`,
        casier_id: metadata.casier_id || null,
        created_by: userId
    };

    return await dossierService.createDossier(dossierData);
};

// Restaurer un casier
const restoreCasier = async (metadata, tempDir, userId) => {
    const casierData = {
        nom: metadata.name || `casier_restaure_${Date.now()}`,
        armoire_id: metadata.armoire_id || null,
        created_by: userId
    };

    return await casierService.createCasier(casierData);
};

// Restaurer une armoire
const restoreArmoire = async (metadata, tempDir, userId) => {
    const armoireData = {
        nom: metadata.name || `armoire_restaure_${Date.now()}`,
        entreprise_id: metadata.entreprise_id || null,
        created_by: userId
    };

    return await armoireService.createArmoire(armoireData);
};

export default {
    restoreBackup
}; 