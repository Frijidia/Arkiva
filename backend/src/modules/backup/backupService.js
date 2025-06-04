import backupModel from './backupModel.js';
import auditService from '../audit/auditService.js';
import fs from 'fs';
import path from 'path';
import archiver from 'archiver';
import fileService from '../fichiers/fichierService.js';
import folderService from '../dosiers/folderService.js';
import systemService from '../system/systemService.js';

// Chemin où stocker les sauvegardes (vous pouvez configurer cela via une variable d'environnement)
const BACKUP_DIR = path.join(__dirname, '../../uploads/backups'); // Exemple : un sous-dossier dans uploads

// S'assurer que le répertoire de sauvegarde existe
if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
}

const createBackup = async (backupData, utilisateur_id, res) => { // Passer `res` pour gérer les réponses HTTP ici temporairement, ou refactorer pour retourner des données/erreurs
    try {
        const { type, cible_id, mode } = backupData;

        // Valider le type de sauvegarde
        if (!['fichier', 'dossier', 'système'].includes(type)) {
            // Plutôt que d'envoyer la réponse ici, on pourrait lancer une erreur personnalisée
             if (res && !res.headersSent) res.status(400).json({ error: 'Type de sauvegarde invalide.' });
            throw new Error('Type de sauvegarde invalide.');
        }

        // ** Logique de sauvegarde **
        let dataToArchive = {};
        let backupFileName = `${type}_${cible_id || 'system'}_${Date.now()}.zip`; // Nom de fichier unique
        let archivePath = path.join(BACKUP_DIR, backupFileName);
        let backupSummary = {};

        // Créer l'archive ZIP
        const output = fs.createWriteStream(archivePath);
        const archive = archiver('zip', {
            zlib: { level: 9 } // Meilleure compression
        });

        // Gérer les événements de l'archive
        output.on('close', async () => {
            console.log(archive.pointer() + ' total bytes for ' + backupFileName);
            console.log('Archiver has been finalized and the output file descriptor has closed.');

            // Sauvegarder les informations dans la base de données UNE FOIS l'archive créée
            const dbBackupData = {
                type,
                cible_id: cible_id || null,
                chemin_sauvegarde: archivePath,
                contenu_json: backupSummary,
                declenche_par_id: utilisateur_id,
            };

            try {
                const newBackup = await backupModel.createBackup(dbBackupData);
                // Envoyer la réponse ici, une fois la DB mise à jour (ou retourner le résultat)
                 if (res && !res.headersSent) {
                     res.status(201).json({
                         message: `Sauvegarde de type ${type} déclenchée avec succès.`, // Message plus informatif
                         backup: newBackup
                     });
                 }
            } catch (dbError) {
                console.error(`Erreur lors de la sauvegarde en base de données: ${dbError.message}`, dbError);
                // TODO: Gérer l'erreur DB après la création de l'archive si nécessaire (ex: supprimer l'archive créée)
                 if (res && !res.headersSent) {
                     res.status(500).json({
                         error: 'Erreur lors de la sauvegarde en base de données',
                         details: dbError.message
                     });
                 }
            }
        });

        archive.on('error', (err) => {
            console.error(`Erreur d'archivage: ${err.message}`, err);
            // Si l'erreur survient pendant l'archivage, on la propage ou on gère ici.
            // Comme la réponse n'a pas encore été envoyée, on peut envoyer une erreur 500.
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
                     // Envoyer la réponse d'erreur ici ou lancer une erreur
                     if (res && !res.headersSent) res.status(400).json({ error: 'cible_id est requis pour la sauvegarde de fichier.' });
                     return; // Stop processing
                }
                // ** Récupérer les données du fichier et les ajouter à l'archive **
                try {
                    const fileDetails = await fileService.getFileDetails(cible_id);
                    if (!fileDetails) {
                         archive.finalize();
                         if (res && !res.headersSent) res.status(404).json({ error: 'Fichier non trouvé.' });
                         return;
                    }

                    // Ajouter les métadonnées à l'archive
                    dataToArchive = fileDetails;
                    archive.append(JSON.stringify(dataToArchive, null, 2), { name: `metadata_${fileDetails.originalFileName}.json` });

                    // Ajouter le contenu du fichier réel
                    const filePath = fileDetails.chemin_chiffre;
                    if (fs.existsSync(filePath)) {
                         archive.file(filePath, { name: fileDetails.originalFileName });
                    } else {
                         console.warn(`Fichier physique introuvable pour ID ${cible_id}: ${filePath}`);
                         // Gérer si le fichier physique manque
                    }

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
                    const folderContent = await folderService.getFolderContentRecursive(cible_id);
                    if (!folderContent) {
                         archive.finalize();
                         if (res && !res.headersSent) res.status(404).json({ error: 'Dossier non trouvé.' });
                         return;
                    }

                    // Ajouter les métadonnées
                    dataToArchive = folderContent;
                    archive.append(JSON.stringify(dataToArchive, null, 2), { name: `metadata_folder_${cible_id}.json` });

                    // Optionnel: Ajouter les fichiers physiques

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
                    const systemMetadata = await systemService.getAllSystemMetadata();

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
        // Propage l'erreur si elle n'a pas été gérée par un return plus tôt
        throw error;
    }
};

// Nécessaire pour utiliser __dirname et __filename avec les modules ES
import { fileURLToPath } from 'url';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default {
    createBackup,
    // Vous pouvez ajouter d'autres fonctions liées à la sauvegarde ici (e.g., validateBackupRequest)
}; 