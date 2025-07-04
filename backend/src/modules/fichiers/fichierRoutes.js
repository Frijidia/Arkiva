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

const router = express.Router();

// router.use(verifyToken);

router.put('/:fichier_id', checkRole(['admin', 'contributeur']), renameFichier);
router.delete('/:dossier_id', checkRole(['admin', 'contributeur']), deleteFichier);
router.get('/:fichier_id/:entreprise_id', displayFichier);
router.get('/:dossier_id', getFichiersByDossierId);
// router.get('/telecharger/:fichier_id', telechargerFichier);
router.get('/getinfofile/:fichier_id', getFichierById);
router.put('/:id/deplacer', deplacerFichier);




export default router;
