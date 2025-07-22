import express from 'express';

import {
    CreateDossier,
    GetDossiersByCasier,
    DeleteDossier,
    RenameDossier,
    deplacerDossier

   
} from './dosierControllers.js';
import { verifyToken, checkRole } from '../auth/authMiddleware.js';
import { checkSubscriptionStatus, checkDossierAccess } from '../payments/subscriptionMiddleware.js';

const router = express.Router();

// Appliquer l'authentification à toutes les routes
router.use(verifyToken);

// Routes qui nécessitent un abonnement actif
router.post('/', checkRole(['admin', 'contributeur']), checkSubscriptionStatus, CreateDossier);
router.put('/:dossier_id', checkRole(['admin', 'contributeur']), checkDossierAccess, RenameDossier);
router.delete('/:dossier_id', checkRole(['admin', 'contributeur']), checkDossierAccess, DeleteDossier);
router.get('/:cassier_id', checkRole(['admin', 'contributeur']), checkSubscriptionStatus, GetDossiersByCasier);

router.put('/:id/deplacer', deplacerDossier);


export default router;
