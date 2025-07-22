import express from 'express';
import { verifyToken, checkRole } from '../auth/authMiddleware.js';
import {
    getUserActivity,
    getTargetActivity,
    getEntrepriseActivity
} from './auditController.js';

const router = express.Router();

// Toutes les routes sont protégées par authentification
router.use(verifyToken);

// Routes accessibles aux administrateurs et contributeurs
router.get('/users/:userId', checkRole(['admin', 'contributeur']), getUserActivity);
router.get('/target/:type/:id', checkRole(['admin', 'contributeur']), getTargetActivity);
router.get('/entreprise/:entrepriseId', checkRole(['admin', 'contributeur']), getEntrepriseActivity);

export default router;
