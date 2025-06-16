import backupModel from './backupModel.js';
import * as fileService from '../fichiers/fichierControllers.js';
import * as dossierService from '../dosiers/dosierControllers.js';
import * as casierService from '../cassiers/cassierContollers.js';
import * as armoireService from '../armoires/armoireControllers.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import archiver from 'archiver';
import pool from '../../config/database.js';
import { v4 as uuidv4 } from 'uuid';

// Obtenir le chemin du répertoire actuel pour les modules ES
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Chemin où stocker les sauvegardes
const BACKUP_DIR = path.join(__dirname, '../../uploads/backups');

// S'assurer que le répertoire de sauvegarde existe
if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
}

// Fonctions utilitaires pour récupérer les données
const getDossierById = async (dossierId) => {
    const result = await pool.query('SELECT * FROM dossiers WHERE dossier_id = $1', [dossierId]);
    return result.rows[0];
};

const getFichiersByDossierId = async (dossierId) => {
    const result = await pool.query(
        'SELECT * FROM fichiers WHERE dossier_id = $1 ORDER BY fichier_id DESC',
        [dossierId]
    );
    return result.rows;
};

const getCasierById = async (casierId) => {
    const result = await pool.query('SELECT * FROM casiers WHERE casier_id = $1', [casierId]);
    return result.rows[0];
};

const getDossiersByCasier = async (casierId) => {
    const result = await pool.query(
        'SELECT * FROM dossiers WHERE casier_id = $1 ORDER BY dossier_id ASC',
        [casierId]
    );
    return result.rows;
};

const getArmoireById = async (armoireId) => {
    const result = await pool.query('SELECT * FROM armoires WHERE armoire_id = $1', [armoireId]);
    return result.rows[0];
};

const getCasiersByArmoire = async (armoireId) => {
    const result = await pool.query(
        'SELECT * FROM casiers WHERE armoire_id = $1 ORDER BY casier_id ASC',
        [armoireId]
    );
    return result.rows;
};

// Contrôleurs pour les sauvegardes
export const createBackup = async (req, res) => {
    try {
        const { type, cible_id, entreprise_id } = req.body;

        if (!type || !cible_id || !entreprise_id) {
            return res.status(400).json({ error: 'Type, cible_id et entreprise_id sont requis' });
        }

        // Créer un nom de fichier unique pour la sauvegarde
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const backupFileName = `backup-${type}-${cible_id}-${timestamp}.zip`;
        const backupPath = path.join(BACKUP_DIR, backupFileName);

        // Créer un fichier zip pour la sauvegarde
        const output = fs.createWriteStream(backupPath);
        const archive = archiver('zip', {
            zlib: { level: 9 } // Compression maximale
        });

        output.on('close', async () => {
            try {
                // Créer l'entrée dans la base de données
                const backupData = {
                    type,
                    cible_id,
                    entreprise_id,
                    chemin_sauvegarde: backupPath,
                    contenu_json: JSON.stringify({
                        taille: archive.pointer(),
                        date_creation: new Date(),
                        description: `Sauvegarde de ${type} ${cible_id}`
                    }),
                    declenche_par_id: req.user?.user_id || null
                };

                const backup = await backupModel.createBackup(backupData);
                res.status(201).json(backup);
            } catch (error) {
                console.error('Erreur lors de la création de la sauvegarde:', error);
                res.status(500).json({ error: error.message });
            }
        });

        archive.on('error', (err) => {
            throw err;
        });

        archive.pipe(output);

        // Récupérer et ajouter le contenu selon le type
        switch (type) {
            case 'armoire':
                const armoire = await getArmoireById(cible_id);
                if (!armoire) {
                    return res.status(404).json({ error: 'Armoire non trouvée' });
                }
                // Ajouter les métadonnées de l'armoire
                archive.append(JSON.stringify(armoire, null, 2), { name: 'metadata.json' });
                // Ajouter les casiers
                const casiers = await getCasiersByArmoire(cible_id);
                for (const casier of casiers) {
                    archive.append(JSON.stringify(casier, null, 2), { name: `casiers/${casier.casier_id}.json` });
                }
                break;

            case 'casier':
                const casier = await getCasierById(cible_id);
                if (!casier) {
                    return res.status(404).json({ error: 'Casier non trouvé' });
                }
                // Ajouter les métadonnées du casier
                archive.append(JSON.stringify(casier, null, 2), { name: 'metadata.json' });
                // Ajouter les dossiers
                const dossiers = await getDossiersByCasier(cible_id);
                for (const dossier of dossiers) {
                    archive.append(JSON.stringify(dossier, null, 2), { name: `dossiers/${dossier.dossier_id}.json` });
                }
                break;

            case 'dossier':
                const dossier = await getDossierById(cible_id);
                if (!dossier) {
                    return res.status(404).json({ error: 'Dossier non trouvé' });
                }
                // Ajouter les métadonnées du dossier
                archive.append(JSON.stringify(dossier, null, 2), { name: 'metadata.json' });
                // Ajouter les fichiers
                const fichiers = await getFichiersByDossierId(cible_id);
                for (const fichier of fichiers) {
                    archive.append(JSON.stringify(fichier, null, 2), { name: `fichiers/${fichier.fichier_id}.json` });
                }
                break;

            case 'fichier':
                const fichier = await fileService.getFichierById(cible_id);
                if (!fichier) {
                    return res.status(404).json({ error: 'Fichier non trouvé' });
                }
                // Ajouter les métadonnées du fichier
                archive.append(JSON.stringify(fichier, null, 2), { name: 'metadata.json' });
                break;

            default:
                return res.status(400).json({ error: 'Type de sauvegarde invalide' });
        }

        // Finaliser l'archive
        await archive.finalize();

    } catch (error) {
        console.error('Erreur lors de la création de la sauvegarde:', error);
        res.status(500).json({ error: error.message });
    }
};

// Fonction utilitaire pour convertir un ID en UUID
const convertToUuid = async (id) => {
    try {
        // Si l'ID est déjà un UUID valide, le retourner tel quel
        if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) {
            return id;
        }
        // Sinon, générer un nouvel UUID
        return uuidv4();
    } catch (error) {
        console.error('Erreur lors de la conversion en UUID:', error);
        throw error;
    }
};

export const getAllBackups = async (req, res) => {
    try {
        const backups = await backupModel.getAllBackups();
        res.json(backups);
    } catch (error) {
        console.error('Erreur lors de la récupération des sauvegardes:', error);
        res.status(500).json({ error: error.message });
    }
};

export const getBackupById = async (req, res) => {
    try {
        const backup = await backupModel.getBackupById(req.params.id);
        if (!backup) {
            return res.status(404).json({ error: 'Sauvegarde non trouvée' });
        }
        res.json(backup);
    } catch (error) {
        console.error('Erreur lors de la récupération de la sauvegarde:', error);
        res.status(500).json({ error: error.message });
    }
}; 