import backupModel from './backupModel.js';
import { logAction } from '../audit/auditService.js';
import fs from 'fs';
import path from 'path';
import archiver from 'archiver';
import awsStorageService from '../../services/awsStorageService.js';
import { fileURLToPath } from 'url';

// Nécessaire pour utiliser __dirname avec les modules ES
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Chemin temporaire pour créer l'archive avant upload vers S3
const TEMP_DIR = path.join(__dirname, '../../temp');

// S'assurer que le répertoire temporaire existe
if (!fs.existsSync(TEMP_DIR)) {
    fs.mkdirSync(TEMP_DIR, { recursive: true });
}

const createBackup = async (backupData, utilisateur_id, res) => {
    let tempArchivePath = null;
    try {
        const { type, cible_id, mode } = backupData;

        // Valider le type de sauvegarde
        if (!['fichier', 'dossier', 'casier', 'armoire', 'système'].includes(type)) {
            if (res && !res.headersSent) res.status(400).json({ error: 'Type de sauvegarde invalide.' });
            throw new Error('Type de sauvegarde invalide.');
        }

        // ** Logique de sauvegarde **
        let dataToArchive = {};
        let backupFileName = `${type}_${cible_id || 'system'}_${Date.now()}.zip`;
        tempArchivePath = path.join(TEMP_DIR, backupFileName);
        let backupSummary = {};

        // Créer l'archive ZIP temporaire
        const output = fs.createWriteStream(tempArchivePath);
        const archive = archiver('zip', {
            zlib: { level: 9 } // Meilleure compression
        });

        // Gérer les événements de l'archive
        output.on('close', async () => {
            console.log(archive.pointer() + ' total bytes for ' + backupFileName);
            console.log('Archiver has been finalized and the output file descriptor has closed.');

            try {
                // Lire le fichier temporaire
                const fileBuffer = fs.readFileSync(tempArchivePath);
                
                // Upload vers S3
                const s3Result = await awsStorageService.uploadBackup(fileBuffer, backupFileName);
                
                // Sauvegarder les informations dans la base de données
                const dbBackupData = {
                    type,
                    cible_id: cible_id || null,
                    entreprise_id: backupData.entreprise_id || null,
                    chemin_sauvegarde: s3Result.location, // URL S3 (pour compatibilité)
                    contenu_json: {
                        ...backupSummary,
                        s3Key: s3Result.key,
                        s3Size: s3Result.size,
                        s3Location: s3Result.location
                    },
                    declenche_par_id: utilisateur_id,
                    storage_path: s3Result.key, // Clé S3
                    s3_key: s3Result.key, // Clé S3
                    s3_size: s3Result.size // Taille S3
                };

                const newBackup = await backupModel.createBackup(dbBackupData);

                // Journaliser l'action
                if (utilisateur_id) {
                    await logAction(
                        utilisateur_id,
                        'create_backup',
                        'backup',
                        newBackup.id,
                        {
                            backup_id: newBackup.id,
                            type: type,
                            s3_location: s3Result.location,
                            date: new Date()
                        }
                    );
                }

                // Nettoyer le fichier temporaire
                if (fs.existsSync(tempArchivePath)) {
                    fs.unlinkSync(tempArchivePath);
                }

                if (res && !res.headersSent) {
                    res.status(201).json({
                        message: `Sauvegarde de type ${type} créée avec succès.`,
                        backup: newBackup,
                        s3Location: s3Result.location
                    });
                }
            } catch (error) {
                console.error(`Erreur lors de l'upload vers S3 ou sauvegarde DB: ${error.message}`, error);
                
                // Nettoyer le fichier temporaire en cas d'erreur
                if (tempArchivePath && fs.existsSync(tempArchivePath)) {
                    fs.unlinkSync(tempArchivePath);
                }
                
                if (res && !res.headersSent) {
                    res.status(500).json({
                        error: 'Erreur lors de l\'upload vers S3 ou sauvegarde en base de données',
                        details: error.message
                    });
                }
            }
        });

        archive.on('error', (err) => {
            console.error(`Erreur d'archivage: ${err.message}`, err);
            
            // Nettoyer le fichier temporaire en cas d'erreur
            if (tempArchivePath && fs.existsSync(tempArchivePath)) {
                fs.unlinkSync(tempArchivePath);
            }
            
            if (res && !res.headersSent) {
                res.status(500).json({
                    error: 'Erreur lors de la création de l\'archive de sauvegarde',
                    details: err.message
                });
            }
        });

        // Pipe archive data to the file
        archive.pipe(output);

        switch (type) {
            case 'fichier':
                if (!cible_id) {
                    archive.finalize();
                    if (res && !res.headersSent) res.status(400).json({ error: 'cible_id est requis pour la sauvegarde de fichier.' });
                    return;
                }
                
                // ** Récupérer les données du fichier et les ajouter à l'archive **
                try {
                    // Pour l'instant, on simule les données du fichier
                    // TODO: Implémenter la récupération réelle des données de fichier
                    const fileDetails = {
                        id: cible_id,
                        originalFileName: `fichier_${cible_id}.txt`,
                        taille: 1024,
                        type_mime: 'text/plain'
                    };

                    // Ajouter les métadonnées à l'archive
                    dataToArchive = fileDetails;
                    archive.append(JSON.stringify(dataToArchive, null, 2), { name: `metadata_${fileDetails.originalFileName}.json` });

                    // Ajouter un contenu simulé du fichier
                    archive.append('Contenu simulé du fichier', { name: fileDetails.originalFileName });

                    // Mettre à jour le résumé
                    backupSummary = {
                        type: 'fichier',
                        id: fileDetails.id,
                        name: fileDetails.originalFileName,
                        size: fileDetails.taille,
                        mime: fileDetails.type_mime
                    };

                } catch (fileError) {
                    console.error(`Erreur lors de la récupération/ajout du fichier à l'archive: ${fileError.message}`, fileError);
                    archive.finalize();
                    if (res && !res.headersSent) {
                        res.status(500).json({
                            error: 'Erreur lors de la préparation de la sauvegarde du fichier',
                            details: fileError.message
                        });
                    }
                    return;
                }
                break;

            case 'dossier':
                if (!cible_id) {
                    archive.finalize();
                    if (res && !res.headersSent) res.status(400).json({ error: 'cible_id est requis pour la sauvegarde de dossier.' });
                    return;
                }
                
                // ** Récupérer les données du dossier et de ses contenus et les ajouter à l'archive **
                try {
                    // Pour l'instant, on simule les données du dossier
                    // TODO: Implémenter la récupération réelle des données de dossier
                    const folderContent = {
                        id: cible_id,
                        name: `dossier_${cible_id}`,
                        files: []
                    };

                    // Ajouter les métadonnées
                    dataToArchive = folderContent;
                    archive.append(JSON.stringify(dataToArchive, null, 2), { name: `metadata_folder_${cible_id}.json` });

                    // Mettre à jour le résumé
                    backupSummary = {
                        type: 'dossier',
                        id: folderContent.id,
                        name: folderContent.name,
                        fileCount: folderContent.files ? folderContent.files.length : 0,
                    };

                } catch (folderError) {
                    console.error(`Erreur lors de la récupération/ajout du dossier à l'archive: ${folderError.message}`, folderError);
                    archive.finalize();
                    if (res && !res.headersSent) {
                        res.status(500).json({
                            error: 'Erreur lors de la préparation de la sauvegarde du dossier',
                            details: folderError.message
                        });
                    }
                    return;
                }
                break;

            case 'système':
                // ** Récupérer les données du système et les ajouter à l'archive **
                try {
                    // Pour l'instant, on simule les données système
                    // TODO: Implémenter la récupération réelle des données système
                    const systemMetadata = {
                        totalItems: 0,
                        date: new Date().toISOString(),
                        version: '1.0.0'
                    };

                    // Ajouter les métadonnées
                    dataToArchive = systemMetadata;
                    archive.append(JSON.stringify(dataToArchive, null, 2), { name: 'system_metadata.json' });

                    // Mettre à jour le résumé
                    backupSummary = {
                        type: 'système',
                        totalItems: systemMetadata.totalItems || 'unknown',
                        date: new Date()
                    };

                } catch (systemError) {
                    console.error(`Erreur lors de la récupération/ajout des données système à l'archive: ${systemError.message}`, systemError);
                    archive.finalize();
                    if (res && !res.headersSent) {
                        res.status(500).json({
                            error: 'Erreur lors de la préparation de la sauvegarde système',
                            details: systemError.message
                        });
                    }
                    return;
                }
                break;

            case 'casier':
                if (!cible_id) {
                    archive.finalize();
                    if (res && !res.headersSent) res.status(400).json({ error: 'cible_id est requis pour la sauvegarde de casier.' });
                    return;
                }
                
                // ** Récupérer les données du casier et de ses contenus et les ajouter à l'archive **
                try {
                    // Pour l'instant, on simule les données du casier
                    // TODO: Implémenter la récupération réelle des données de casier
                    const casierContent = {
                        id: cible_id,
                        name: `casier_${cible_id}`,
                        dossiers: []
                    };

                    // Ajouter les métadonnées
                    dataToArchive = casierContent;
                    archive.append(JSON.stringify(dataToArchive, null, 2), { name: `metadata_casier_${cible_id}.json` });

                    // Mettre à jour le résumé
                    backupSummary = {
                        type: 'casier',
                        id: casierContent.id,
                        name: casierContent.name,
                        dossierCount: casierContent.dossiers ? casierContent.dossiers.length : 0,
                    };

                } catch (casierError) {
                    console.error(`Erreur lors de la récupération/ajout du casier à l'archive: ${casierError.message}`, casierError);
                    archive.finalize();
                    if (res && !res.headersSent) {
                        res.status(500).json({
                            error: 'Erreur lors de la préparation de la sauvegarde du casier',
                            details: casierError.message
                        });
                    }
                    return;
                }
                break;

            case 'armoire':
                if (!cible_id) {
                    archive.finalize();
                    if (res && !res.headersSent) res.status(400).json({ error: 'cible_id est requis pour la sauvegarde d\'armoire.' });
                    return;
                }
                
                // ** Récupérer les données de l'armoire et de ses contenus et les ajouter à l'archive **
                try {
                    // Pour l'instant, on simule les données de l'armoire
                    // TODO: Implémenter la récupération réelle des données d'armoire
                    const armoireContent = {
                        id: cible_id,
                        name: `armoire_${cible_id}`,
                        casiers: []
                    };

                    // Ajouter les métadonnées
                    dataToArchive = armoireContent;
                    archive.append(JSON.stringify(dataToArchive, null, 2), { name: `metadata_armoire_${cible_id}.json` });

                    // Mettre à jour le résumé
                    backupSummary = {
                        type: 'armoire',
                        id: armoireContent.id,
                        name: armoireContent.name,
                        casierCount: armoireContent.casiers ? armoireContent.casiers.length : 0,
                    };

                } catch (armoireError) {
                    console.error(`Erreur lors de la récupération/ajout de l'armoire à l'archive: ${armoireError.message}`, armoireError);
                    archive.finalize();
                    if (res && !res.headersSent) {
                        res.status(500).json({
                            error: 'Erreur lors de la préparation de la sauvegarde de l\'armoire',
                            details: armoireError.message
                        });
                    }
                    return;
                }
                break;
            default:
                // Gérer les types invalides qui auraient pu passer la validation initiale (redondant mais sécuritaire)
                archive.finalize();
                if (res && !res.headersSent) res.status(400).json({ error: 'Type de sauvegarde invalide après switch.' });
                return;
        }

        // Finaliser l'archive
        archive.finalize();

    } catch (error) {
        console.error(`Erreur dans backupService.createBackup: ${error.message}`, error);
        
        // Nettoyer le fichier temporaire en cas d'erreur
        if (tempArchivePath && fs.existsSync(tempArchivePath)) {
            fs.unlinkSync(tempArchivePath);
        }
        
        // Propage l'erreur si elle n'a pas été gérée par un return plus tôt
        throw error;
    }
};

export default {
    createBackup,
    // Vous pouvez ajouter d'autres fonctions liées à la sauvegarde ici (e.g., validateBackupRequest)
}; 