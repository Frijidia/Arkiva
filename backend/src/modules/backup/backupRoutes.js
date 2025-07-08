import express from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { verifyToken, checkRole } from '../auth/authMiddleware.js';
import {
  createBackup,
  getAllBackups,
  getBackupById
} from './backupController.js';
import cleanupService from '../cleanup/cleanupService.js';

const router = express.Router();

// Créer le dossier de sauvegarde s'il n'existe pas
const backupDir = path.join(process.cwd(), 'uploads/backups');
if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
}

// Configuration de multer pour le stockage des fichiers
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, backupDir);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ 
    storage: storage,
    limits: {
        fileSize: 50 * 1024 * 1024 // limite de 50MB
    }
});

// Middleware pour gérer les erreurs multer
const handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ error: 'Le fichier est trop volumineux. Taille maximale: 50MB' });
        }
        return res.status(400).json({ error: err.message });
    }
    next(err);
};

// Toutes les routes nécessitent une authentification et le rôle admin
router.use(verifyToken);
router.use(checkRole(['admin']));

// Routes pour les sauvegardes
router.post('/', checkRole(['admin']), createBackup);
router.get('/', checkRole(['admin']), getAllBackups);
router.get('/:id', checkRole(['admin']), getBackupById);

// 🧹 Nouvelle route pour le nettoyage automatique
router.post('/cleanup', checkRole(['admin']), async (req, res) => {
  try {
    console.log(`🧹 [Cleanup] Nettoyage manuel déclenché par l'admin`);
    
    const result = await cleanupService.runFullCleanup();
    
    res.status(200).json({
      message: 'Nettoyage terminé avec succès',
      result: result
    });
    
  } catch (error) {
    console.error('❌ [Cleanup] Erreur lors du nettoyage manuel:', error);
    res.status(500).json({ 
      error: 'Erreur lors du nettoyage',
      details: error.message 
    });
  }
});

export default router; 