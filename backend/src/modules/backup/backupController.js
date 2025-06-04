import backupModel from './backupModel.js';
import auditService from '../audit/auditService.js'; // Supposant l'existence de ce service
import fs from 'fs';
import path from 'path';
import archiver from 'archiver'; // Assurez-vous que ce package est installé (npm install archiver)
import unzipper from 'unzipper'; // Assurez-vous que ce package est installé (npm install unzipper)
// Importer les services ou modèles pour récupérer les données des fichiers/dossiers si nécessaire
import fileService from '../fichiers/fichierService.js'; // Supposant l'existence de ce service
import folderService from '../dosiers/folderService.js'; // Supposant l'existence de ce service pour les dossiers
import systemService from '../system/systemService.js'; // Supposant l'existence de ce service pour la sauvegarde système
import backupService from './backupService.js';

// Chemin où stocker les sauvegardes (vous pouvez configurer cela via une variable d'environnement)
const BACKUP_DIR = path.join(__dirname, '../../uploads/backups'); // Exemple : un sous-dossier dans uploads

// S'assurer que le répertoire de sauvegarde existe
if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
}

class BackupController {
    // Endpoint pour déclencher une sauvegarde (POST /sauvegardes)
    static async createBackup(req, res) {
        try {
            const { type, cible_id, mode } = req.body;
            const declenche_par_id = req.user ? req.user.id : null;

            // Valider le type de sauvegarde
            if (!['fichier', 'dossier', 'système'].includes(type)) {
                return res.status(400).json({ error: 'Type de sauvegarde invalide.' });
            }

            // Déléguer la création de la sauvegarde au service
            const newBackup = await backupService.createBackup({
                type,
                cible_id,
                mode,
                declenche_par_id,
                res // Passer l'objet res pour permettre au service de gérer les réponses HTTP
            });

            // Si la sauvegarde a réussi et que la réponse n'a pas encore été envoyée
            if (!res.headersSent) {
                res.status(201).json({
                    message: `Sauvegarde de type ${type} déclenchée avec succès.`,
                    backup: newBackup
                });
            }
        } catch (error) {
            console.error('Erreur lors du déclenchement de la sauvegarde:', error);
            if (!res.headersSent) {
                res.status(500).json({
                    error: 'Erreur lors du déclenchement de la sauvegarde',
                    details: error.message
                });
            }
        }
    }

    // Endpoint pour lister les sauvegardes (GET /sauvegardes)
    static async listBackups(req, res) {
        try {
            const backups = await backupModel.getAllBackups();

            const formattedBackups = backups.map(backup => ({
                id: backup.id,
                type: backup.type,
                contenu: backup.contenu_json,
                date_creation: backup.date_creation
            }));

            res.json(formattedBackups);
        } catch (error) {
            console.error('Erreur lors de la liste des sauvegardes:', error);
            res.status(500).json({
                error: 'Erreur lors de la récupération des sauvegardes',
                details: error.message
            });
        }
    }

    // Endpoint pour restaurer une sauvegarde (POST /sauvegardes/:id/restaurer)
    // NOTE: Cette route devrait être protégée par un middleware pour les administrateurs uniquement.
    static async restoreBackup(req, res) {
        try {
            const backupId = req.params.id;
            const utilisateur_id = req.user ? req.user.id : null;

            // Assurez-vous que l'utilisateur est un admin (middleware checkRole('admin')) est appliqué à cette route

            // La logique de restauration est maintenant dans le modèle.
            const result = await backupModel.restoreBackup(backupId, utilisateur_id);

            // Envoyer la réponse une fois la logique du modèle terminée
            res.json(result); // Le modèle retourne un objet avec un message

        } catch (error) {
            console.error(`Erreur lors de la restauration de la sauvegarde ID ${req.params.id} dans le contrôleur:`, error);
            // Gérer les erreurs remontées par le modèle ou d'autres erreurs du contrôleur
            if (!res.headersSent) {
                res.status(500).json({
                    error: 'Erreur lors de la restauration de la sauvegarde',
                    details: error.message
                });
            }
        }
    }
}

// Nécessaire pour utiliser __dirname et __filename avec les modules ES
import { fileURLToPath } from 'url';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default BackupController; 