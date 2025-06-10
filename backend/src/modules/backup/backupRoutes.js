import express from 'express';
import multer from 'multer';
import path from 'path';
import { verifyToken, checkRole } from '../auth/authMiddleware.js';
import * as backupController from './backupController.js';

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
router.post('/', upload.single('file'), backupController.createBackup);
router.get('/', backupController.getAllBackups);
router.get('/:id', backupController.getBackupById);
router.post('/:id/restore', backupController.restoreBackup);

// Routes pour les versions
router.post('/versions', backupController.createVersion);
router.get('/versions/:fileId/history', backupController.getVersionHistory);
router.get('/versions/:id/content', backupController.getVersionContent);
router.post('/versions/compare', backupController.compareVersions);
router.delete('/versions/:id', backupController.deleteVersion);

export default router; 