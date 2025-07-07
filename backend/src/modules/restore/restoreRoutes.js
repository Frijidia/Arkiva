import express from 'express';
import { verifyToken, checkRole } from '../auth/authMiddleware.js';
import * as restoreController from './restoreController.js';

const router = express.Router();

// Toutes les routes nécessitent une authentification et le rôle admin
router.use(verifyToken);
router.use(checkRole(['admin']));

// Routes pour les restaurations
router.post('/backup/:id', restoreController.restoreBackup);
router.post('/version/:id', restoreController.restoreVersion);
router.get('/', restoreController.getAllRestores);
router.get('/:id', restoreController.getRestoreById);
router.get('/:id/details', restoreController.getRestoreDetails);
router.get('/entreprise/:entrepriseId', restoreController.getRestoresByEntreprise);
router.get('/type/:type', restoreController.getRestoresByType);
router.get('/version/:versionId', restoreController.getRestoresByVersion);
router.get('/backup/:backupId', restoreController.getRestoresByBackup);
router.delete('/:id', restoreController.deleteRestore);

export default router;