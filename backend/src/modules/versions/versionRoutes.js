import express from 'express';
import { verifyToken } from '../auth/authMiddleware.js';
import * as versionController from './versionController.js';

const router = express.Router();

// Toutes les routes nécessitent une authentification
router.use(verifyToken);

// Routes pour les versions
router.post('/', versionController.createVersion);
router.get('/cible/history', versionController.getVersionHistory);
router.get('/:id/content', versionController.getVersionContent);
router.get('/:id/download-url', versionController.getVersionDownloadUrl);
router.post('/compare', versionController.compareVersions);
router.delete('/:id', versionController.deleteVersion);

export default router; 