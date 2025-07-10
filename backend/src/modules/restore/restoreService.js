import restoreModel from './restoreModel.js';
import backupModel from '../backup/backupModel.js';
import versionModel from '../versions/versionModel.js';
import versionService from '../versions/versionService.js';
import awsStorageService from '../../services/awsStorageService.js';
import { logAction } from '../audit/auditService.js';
import pool from '../../config/database.js';
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
const restoreBackup = async (backupId, userId, armoireId = null, cassierId = null, dossierId = null) => {
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
                restoredData = await restoreFile(metadata, tempExtractPath, userId, dossierId);
                break;
            case 'dossier':
                restoredData = await restoreDossier(metadata, tempExtractPath, userId, cassierId);
                break;
            case 'casier':
                console.log('[RESTORE] restoreBackup appelle restoreCasier avec armoireId =', armoireId);
                if (!armoireId && !metadata.armoire_id) {
                    throw new Error("Aucune armoire de destination n'a été spécifiée pour la restauration du casier.");
                }
                restoredData = await restoreCasier(metadata, tempExtractPath, userId, armoireId);
                break;
            case 'armoire':
                restoredData = await restoreArmoire(metadata, tempExtractPath, userId);
                break;
            default:
                throw new Error('Type de sauvegarde non supporté');
        }

        console.log('🔍 [DEBUG] restoredData:', restoredData);

        // Vérifier que restoredData a un ID et l'extraire selon le type
        let restoredId;
        if (!restoredData) {
            throw new Error('Échec de la restauration : aucun résultat retourné');
        }

        // Extraire l'ID selon le type
        switch (backup.type) {
            case 'fichier':
                restoredId = restoredData.fichier_id;
                break;
            case 'dossier':
                restoredId = restoredData.dossier_id;
                break;
            case 'casier':
                restoredId = restoredData.cassier_id;
                break;
            case 'armoire':
                restoredId = restoredData.armoire_id;
                break;
            default:
                throw new Error('Type de sauvegarde non supporté');
        }

        console.log('🔍 [DEBUG] restoredId:', restoredId);

        if (!restoredId) {
            throw new Error('Échec de la restauration : aucun ID retourné');
        }

        // Créer l'entrée de restauration
        const restoreData = {
            backup_id: backupId,
            type: backup.type,
            cible_id: restoredId,
            entreprise_id: backup.entreprise_id,
            declenche_par_id: userId,
            metadata_json: {
                source_type: 'backup',
                source_id: backupId,
                source_metadata: backup.contenu_json,
                restored_metadata: {
                    id: restoredId,
                    type: backup.type,
                    name: restoredData.nom || restoredData.name,
                    created_at: new Date().toISOString()
                },
                restoration_details: {
                    original_backup_date: backup.date_creation,
                    restoration_date: new Date().toISOString(),
                    user_id: userId
                }
            }
        };

        console.log('🔍 [DEBUG] restoreData:', restoreData);

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
                    restored_id: restoredId,
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

// Restaurer une version
const restoreVersion = async (versionId, userId) => {
    try {
        // Récupérer les informations de la version
        const version = await versionModel.getVersionById(versionId);
        if (!version) {
            throw new Error('Version non trouvée');
        }

        // Récupérer le contenu de la version
        const versionContent = await versionService.getVersionContent(versionId);
        if (!versionContent) {
            throw new Error('Contenu de la version non trouvé');
        }

        // Restaurer selon le type
        let restoredData;
        switch (version.type) {
            case 'fichier':
                restoredData = await restoreFileFromVersion(versionContent, userId);
                break;
            case 'dossier':
                restoredData = await restoreDossierFromVersion(versionContent, userId);
                break;
            case 'casier':
                restoredData = await restoreCasierFromVersion(versionContent, userId);
                break;
            case 'armoire':
                restoredData = await restoreArmoireFromVersion(versionContent, userId);
                break;
            default:
                throw new Error('Type de version non supporté');
        }

        console.log('🔍 [DEBUG] restoredData (version):', restoredData);

        // Vérifier que restoredData a un ID et l'extraire selon le type
        let restoredId;
        if (!restoredData) {
            throw new Error('Échec de la restauration : aucun résultat retourné');
        }

        // Extraire l'ID selon le type
        switch (version.type) {
            case 'fichier':
                restoredId = restoredData.fichier_id;
                break;
            case 'dossier':
                restoredId = restoredData.dossier_id;
                break;
            case 'casier':
                restoredId = restoredData.cassier_id;
                break;
            case 'armoire':
                restoredId = restoredData.armoire_id;
                break;
            default:
                throw new Error('Type de version non supporté');
        }

        console.log('🔍 [DEBUG] restoredId (version):', restoredId);

        if (!restoredId) {
            throw new Error('Échec de la restauration : aucun ID retourné');
        }

        // Créer l'entrée de restauration
        const restoreData = {
            version_id: versionId,
            type: version.type,
            cible_id: restoredId,
            entreprise_id: version.metadata?.entreprise_id || null,
            declenche_par_id: userId,
            metadata_json: {
                source_type: 'version',
                source_id: versionId,
                source_metadata: version.metadata,
                restored_metadata: {
                    id: restoredId,
                    type: version.type,
                    name: restoredData.nom || restoredData.name,
                    created_at: new Date().toISOString()
                },
                restoration_details: {
                    original_version_date: version.created_at,
                    restoration_date: new Date().toISOString(),
                    user_id: userId
                }
            }
        };

        const restore = await restoreModel.createRestore(restoreData);

        // Journaliser l'action
        if (userId) {
            await logAction(
                userId,
                'restore_version',
                'version',
                versionId,
                {
                    version_id: versionId,
                    restored_id: restoredId,
                    type: version.type,
                    date: new Date()
                }
            );
        }

        return restore;
    } catch (error) {
        console.error('Erreur lors de la restauration de la version:', error);
        throw error;
    }
};

// Restaurer un fichier
const restoreFile = async (metadata, tempDir, userId, dossierId = null) => {
    const fileData = {
        nom: metadata.originalFileName || metadata.name || `fichier_restaure_${Date.now()}`,
        type_mime: metadata.type_mime || 'application/octet-stream',
        taille: metadata.taille || metadata.size || 0,
        dossier_id: dossierId || metadata.dossier_id || null,
        user_id: userId
    };

    // Créer directement dans la base de données
    const query = `
        INSERT INTO fichiers (nom, type_mime, taille, dossier_id, user_id) 
        VALUES ($1, $2, $3, $4, $5) 
        RETURNING *
    `;
    
    const result = await pool.query(query, [
        fileData.nom,
        fileData.type_mime,
        fileData.taille,
        fileData.dossier_id,
        fileData.user_id
    ]);
    
    return result.rows[0];
};

// Restaurer un dossier
const restoreDossier = async (metadata, tempDir, userId, cassierId = null) => {
    console.log('🔍 [DEBUG] restoreDossier - metadata:', metadata);
    console.log('🔍 [DEBUG] restoreDossier - userId:', userId);
    
    const dossierData = {
        nom: metadata.name || `dossier_restaure_${Date.now()}`,
        cassier_id: cassierId || metadata.cassier_id || null,
        user_id: userId
    };

    console.log('🔍 [DEBUG] restoreDossier - dossierData:', dossierData);

    // Créer directement dans la base de données
    const query = `
        INSERT INTO dossiers (nom, cassier_id, description, user_id) 
        VALUES ($1, $2, $3, $4) 
        RETURNING *
    `;
    
    console.log('🔍 [DEBUG] restoreDossier - query:', query);
    console.log('🔍 [DEBUG] restoreDossier - values:', [dossierData.nom, dossierData.cassier_id, " ", dossierData.user_id]);
    
    const result = await pool.query(query, [
        dossierData.nom,
        dossierData.cassier_id,
        " ", // description vide
        dossierData.user_id
    ]);
    
    console.log('🔍 [DEBUG] restoreDossier - result:', result.rows[0]);
    
    return result.rows[0];
};

// Restaurer un casier
const restoreCasier = async (metadata, tempDir, userId, armoireId = null) => {
    const casierData = {
        nom: metadata.name || `casier_restaure_${Date.now()}`,
        armoire_id: (armoireId !== null && armoireId !== undefined) ? Number(armoireId) : (metadata.armoire_id || null),
        user_id: userId
    };

    console.log('[RESTORE] Insertion casier avec armoire_id =', casierData.armoire_id);

    if (!casierData.armoire_id) {
        throw new Error("Aucune armoire de destination n'a été spécifiée pour la restauration du casier.");
    }

    // Créer directement dans la base de données
    const query = `
        INSERT INTO casiers (nom, armoire_id, user_id) 
        VALUES ($1, $2, $3) 
        RETURNING *
    `;
    
    const result = await pool.query(query, [
        casierData.nom,
        casierData.armoire_id,
        casierData.user_id
    ]);
    
    return result.rows[0];
};

// Restaurer une armoire
const restoreArmoire = async (metadata, tempDir, userId) => {
    const armoireData = {
        nom: metadata.name || `armoire_restaure_${Date.now()}`,
        entreprise_id: metadata.entreprise_id || null,
        user_id: userId
    };

    // Créer directement dans la base de données
    const query = `
        INSERT INTO armoires (nom, entreprise_id, user_id) 
        VALUES ($1, $2, $3) 
        RETURNING *
    `;
    
    const result = await pool.query(query, [
        armoireData.nom,
        armoireData.entreprise_id,
        armoireData.user_id
    ]);
    
    return result.rows[0];
};

// Restaurer un fichier depuis une version
const restoreFileFromVersion = async (versionContent, userId) => {
    const metadata = versionContent.metadata;
    const content = versionContent.content;

    const fileData = {
        nom: metadata.original_name || `fichier_restaure_${Date.now()}`,
        type_mime: metadata.type_mime || 'application/octet-stream',
        taille: metadata.size || content.length || 0,
        dossier_id: metadata.dossier_id || null,
        user_id: userId
    };

    // Créer directement dans la base de données
    const query = `
        INSERT INTO fichiers (nom, type_mime, taille, dossier_id, user_id) 
        VALUES ($1, $2, $3, $4, $5) 
        RETURNING *
    `;
    
    const result = await pool.query(query, [
        fileData.nom,
        fileData.type_mime,
        fileData.taille,
        fileData.dossier_id,
        fileData.user_id
    ]);
    
    return result.rows[0];
};

// Restaurer un dossier depuis une version
const restoreDossierFromVersion = async (versionContent, userId) => {
    const metadata = versionContent.metadata;
    const content = versionContent.content;

    const dossierData = {
        nom: metadata.original_name || `dossier_restaure_${Date.now()}`,
        cassier_id: metadata.cassier_id || null,
        user_id: userId
    };

    // Créer directement dans la base de données
    const query = `
        INSERT INTO dossiers (nom, cassier_id, description, user_id) 
        VALUES ($1, $2, $3, $4) 
        RETURNING *
    `;
    
    const result = await pool.query(query, [
        dossierData.nom,
        dossierData.cassier_id,
        " ", // description vide
        dossierData.user_id
    ]);
    
    return result.rows[0];
};

// Restaurer un casier depuis une version
const restoreCasierFromVersion = async (versionContent, userId) => {
    const metadata = versionContent.metadata;
    const content = versionContent.content;

    const casierData = {
        nom: metadata.original_name || metadata.name || `casier_restaure_${Date.now()}`,
        armoire_id: (metadata.armoire_id !== null && metadata.armoire_id !== undefined) ? Number(metadata.armoire_id) : null,
        user_id: userId
    };

    console.log('[RESTORE] Insertion casier avec armoire_id =', casierData.armoire_id);

    if (!casierData.armoire_id) {
        throw new Error("Aucune armoire de destination n'a été spécifiée pour la restauration du casier.");
    }

    // Créer directement dans la base de données
    const query = `
        INSERT INTO casiers (nom, armoire_id, user_id) 
        VALUES ($1, $2, $3) 
        RETURNING *
    `;
    
    const result = await pool.query(query, [
        casierData.nom,
        casierData.armoire_id,
        casierData.user_id
    ]);
    
    return result.rows[0];
};

export default {
    restoreBackup,
    restoreVersion
}; 