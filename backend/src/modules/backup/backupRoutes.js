import express from 'express';
import multer from 'multer';
import path from 'path';
import backupModel from './backupModel.js';
import versionService from './versionService.js';
import restoreService from './restoreService.js';
import { verifyToken, checkRole } from '../auth/authMiddleware.js';
import * as fileService from '../fichiers/fichierControllers.js';
import * as dossierService from '../dosiers/dosierControllers.js';
import * as casierService from '../cassiers/cassierContollers.js';
import * as armoireService from '../armoires/armoireControllers.js';

const router = express.Router();

// Configuration de multer pour le stockage des fichiers
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, path.join(process.cwd(), 'uploads/backups'))
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9)
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname))
    }
});

const upload = multer({ storage: storage });

// Toutes les routes nécessitent une authentification et le rôle admin
router.use(verifyToken);
router.use(checkRole(['admin']));

// Routes pour les sauvegardes
router.post('/', upload.single('file'), async (req, res) => {
    try {
        const backupData = {
            type: req.body.type,
            cible_id: req.body.cible_id,
            chemin_sauvegarde: req.file.path,
            contenu_json: JSON.parse(req.body.contenu_json || '{}'),
            declenche_par_id: req.user.user_id
        };

        const backup = await backupModel.createBackup(backupData);
        res.status(201).json(backup);
    } catch (error) {
        console.error('Erreur lors de la création de la sauvegarde:', error);
        res.status(500).json({ error: error.message });
    }
});

router.get('/', async (req, res) => {
    try {
        const backups = await backupModel.getAllBackups();
        res.json(backups);
    } catch (error) {
        console.error('Erreur lors de la récupération des sauvegardes:', error);
        res.status(500).json({ error: error.message });
    }
});

router.get('/:id', async (req, res) => {
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
});

router.post('/:id/restore', async (req, res) => {
    try {
        const result = await restoreService.restoreBackup(req.params.id, req.user.user_id);
        res.json(result);
    } catch (error) {
        console.error('Erreur lors de la restauration:', error);
        res.status(500).json({ error: error.message });
    }
});

// Routes pour les versions
router.post('/versions', async (req, res) => {
    try {
        const { cible_id, type } = req.body;
        
        let details, content, versionMetadata;

        switch(type) {
            case 'fichier':
                // Récupérer les informations du fichier
                details = await fileService.getFileDetails(cible_id);
                if (!details) {
                    return res.status(404).json({ error: 'Fichier non trouvé' });
                }
                content = await fileService.getFileContent(cible_id);
                if (!content) {
                    return res.status(404).json({ error: 'Contenu du fichier non trouvé' });
                }
                versionMetadata = {
                    nom: details.nom,
                    type_mime: details.type_mime,
                    taille: details.taille,
                    version_number: (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date()
                };
                break;

            case 'dossier':
                // Récupérer les informations du dossier
                details = await dossierService.getDossierDetails(cible_id);
                if (!details) {
                    return res.status(404).json({ error: 'Dossier non trouvé' });
                }
                content = await dossierService.getDossierContent(cible_id);
                if (!content) {
                    return res.status(404).json({ error: 'Contenu du dossier non trouvé' });
                }
                versionMetadata = {
                    nom: details.nom,
                    type: "dossier",
                    nombre_elements: details.nombre_elements,
                    version_number: (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date()
                };
                break;

            case 'casier':
                // Récupérer les informations du casier
                details = await casierService.getCasierDetails(cible_id);
                if (!details) {
                    return res.status(404).json({ error: 'Casier non trouvé' });
                }
                content = await casierService.getCasierContent(cible_id);
                if (!content) {
                    return res.status(404).json({ error: 'Contenu du casier non trouvé' });
                }
                versionMetadata = {
                    nom: details.nom,
                    type: "casier",
                    nombre_elements: details.nombre_elements,
                    version_number: (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date()
                };
                break;

            case 'armoire':
                // Récupérer les informations de l'armoire
                details = await armoireService.getArmoireDetails(cible_id);
                if (!details) {
                    return res.status(404).json({ error: 'Armoire non trouvée' });
                }
                content = await armoireService.getArmoireContent(cible_id);
                if (!content) {
                    return res.status(404).json({ error: 'Contenu de l\'armoire non trouvé' });
                }
                versionMetadata = {
                    nom: details.nom,
                    type: "armoire",
                    nombre_elements: details.nombre_elements,
                    version_number: (details.version_number || 0) + 1,
                    created_by: req.user.user_id,
                    created_at: new Date()
                };
                break;

            default:
                return res.status(400).json({ error: 'Type de cible invalide' });
        }

        // Créer la nouvelle version
        const version = await versionService.createNewVersion(
            cible_id,
            content,
            versionMetadata,
            req.user.user_id
        );

        res.status(201).json(version);
    } catch (error) {
        console.error('Erreur lors de la création de la version:', error);
        res.status(500).json({ error: error.message });
    }
});

router.get('/versions/:fileId/history', async (req, res) => {
    try {
        const history = await versionService.getVersionHistory(req.params.fileId);
        res.json(history);
    } catch (error) {
        console.error('Erreur lors de la récupération de l\'historique:', error);
        res.status(500).json({ error: error.message });
    }
});

router.get('/versions/:id/content', async (req, res) => {
    try {
        const version = await versionService.getVersionContent(req.params.id);
        res.json(version);
    } catch (error) {
        console.error('Erreur lors de la récupération du contenu:', error);
        res.status(500).json({ error: error.message });
    }
});

router.post('/versions/compare', async (req, res) => {
    try {
        const { versionId1, versionId2 } = req.body;
        const comparison = await versionService.compareVersions(versionId1, versionId2);
        res.json(comparison);
    } catch (error) {
        console.error('Erreur lors de la comparaison des versions:', error);
        res.status(500).json({ error: error.message });
    }
});

router.delete('/versions/:id', async (req, res) => {
    try {
        const result = await versionService.deleteVersion(req.params.id, req.user.user_id);
        res.json(result);
    } catch (error) {
        console.error('Erreur lors de la suppression de la version:', error);
        res.status(500).json({ error: error.message });
    }
});

export default router; 