import express from 'express';
import cleanupController from './cleanupController.js';
import { verifyToken } from '../auth/authMiddleware.js';

const router = express.Router();

// Middleware pour vérifier le rôle admin
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Accès refusé. Rôle admin requis.' });
  }
  next();
};

router.get('/stats', verifyToken, requireAdmin, cleanupController.getCleanupStats);
router.post('/backups', verifyToken, requireAdmin, cleanupController.cleanupUnusedBackups);
router.post('/versions', verifyToken, requireAdmin, cleanupController.cleanupUnusedVersions);
router.post('/full', verifyToken, requireAdmin, cleanupController.performFullCleanup);
router.get('/backups', verifyToken, requireAdmin, cleanupController.getBackupsList);
router.get('/versions', verifyToken, requireAdmin, cleanupController.getVersionsList);
router.get('/backups/:backup_id', verifyToken, requireAdmin, cleanupController.getBackupDetails);
router.get('/versions/:version_id', verifyToken, requireAdmin, cleanupController.getVersionDetails);
router.delete('/backups/:backup_id', verifyToken, requireAdmin, cleanupController.deleteBackup);
router.delete('/versions/:version_id', verifyToken, requireAdmin, cleanupController.deleteVersion);

export default router; 