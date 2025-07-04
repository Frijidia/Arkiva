import express from 'express';

import {
    getFichiersByDossierId,
    renameFichier,
    deleteFichier,
    displayFichier,
    // telechargerFichier,
    getFichierById,
    deplacerFichier

   
} from './fichierControllers.js';
import { verifyToken, checkRole } from '../../modules/auth/authMiddleware.js';
import { checkSubscriptionStatus, checkFichierAccess } from '../payments/subscriptionMiddleware.js';

const router = express.Router();

router.use(verifyToken);

// Routes qui nécessitent un abonnement actif
router.put('/:fichier_id', checkRole(['admin', 'contributeur']), checkFichierAccess, renameFichier);
router.delete('/:fichier_id', checkRole(['admin', 'contributeur']), checkFichierAccess, deleteFichier);
router.get('/:fichier_id/:entreprise_id', checkFichierAccess, displayFichier);
router.get('/:dossier_id', checkSubscriptionStatus, getFichiersByDossierId);
// router.get('/telecharger/:fichier_id', telechargerFichier);
router.get('/getinfofile/:fichier_id', getFichierById);
router.put('/:id/deplacer', deplacerFichier);

export default router;
